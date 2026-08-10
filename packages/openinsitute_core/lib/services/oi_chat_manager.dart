import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:openinsitute_core/models/oi_chat_message.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:openinsitute_core/services/hive_manager.dart';

class OiChatManager {
  String chatBox = "oiChatManagerCache";
  List? fieldProjectChatChangeListeners;

  OpenI get oi {
    return Get.find();
  }

  Future<void> cacheChat(String projectId, List<OIChatMessage> messages) async {
    messages.sort(
      (a, b) => DateTime.parse(a.properties["date"])
          .compareTo(DateTime.parse(b.properties["date"])),
    );
    for (int i = 0; i < messages.length; i++) {
      await HiveManager.instance.saveData(messages[i].messageid,
          messages[i].properties, chatBox + "_" + projectId);
    }
  }

  Future<void> saveSingleChat(
      OIChatMessage chatMessage, String projectId) async {
    await HiveManager.instance.saveData(chatMessage.messageid,
        chatMessage.properties, chatBox + "_" + projectId);
  }

  Future<List<OIChatMessage>> loadChatCache(String projectId) async {
    List<Map<String, dynamic>> cache =
        await HiveManager.instance.getAllHits(chatBox + "_" + projectId);
    List<OIChatMessage> messages = [];
    for (var e in cache) {
      messages.add(OIChatMessage.fromJson(e));
    }
    return messages;
  }

  Future<void> loadChat(String projectId, int page) async {
    List<OIChatMessage> messages = [];
    List<OIChatMessage> result = await getProjectChatMessages(projectId, page);
    if (result.isNotEmpty) {
      messages.addAll(result);
      await cacheChat(projectId, result);
    }
  }

  /// Firebase can call this when it sees that a chat event came in
  /// so we can invalidate our local cache and update our list of chats
  void chatMessageEdited(String inMessageId, String inUserId) async {
    // var box = await getBox("oiChatManagerCache");

    //fieldProjectChatChangeListeners;
  }

  Map getParams(int page, String inProjectId) {
    return {"page": "$page", "hitsperpage": "20", "collectionid": inProjectId};
  }

  Future<List<OIChatMessage>> getProjectChatMessages(
      String inProjectId, int page) async {
    final Map? responded = await oi.postEntermedia(
      oi.app!["mediadb"] +
          '/services/module/librarycollection/viewmessages.json',
      getParams(page, inProjectId),
    );
    List<OIChatMessage> messages = responded!["results"]!
        .map<OIChatMessage>((json) => OIChatMessage.fromJson(json))
        .toList();
    return Future.value(messages);
  }

  Future<void> saveChat(OIChatMessage inMessage, String projectId) async {
    await saveSingleChat(inMessage, projectId);
    try {
      final Map? responded = await oi.postEntermedia(
        oi.app!["mediadb"] +
            '/services/module/librarycollection/savemessage.json',
        inMessage.properties,
      );
      log("Saved chat message: " + responded.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
