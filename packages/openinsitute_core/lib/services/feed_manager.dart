import 'dart:convert';

import 'package:openinsitute_core/Helper/request_type.dart';
import 'package:openinsitute_core/models/em_data.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:openinsitute_core/services/hive_manager.dart';
import 'package:get/get.dart';

OpenI get oi {
  return Get.find();
}

class FeedManager {
  String feedsBox = "feeds";

  Future<List<EmData>> loadCache() async {
    List<Map<String, dynamic>> cache =
        await HiveManager.instance.getAllHits(feedsBox);
    return cache.map((e) => EmData.fromJson(e)).toList();
  }

  Future<int?> getTotal() async {
    return (await HiveManager.instance.getData("total", feedsBox));
  }

  updateTotal(int total) async {
    await HiveManager.instance.saveData("total", total, feedsBox);
  }

  Future<List<EmData>> loadFeeds(int page) async {
    Map query = getQuery(page);
    String results = await getRemoteData(query);
    if (page == 1) {
      await saveCache(results);
    }
    return await parseData(results);
  }

  Future<List<EmData>> parseData(String responseBody) async {
    final Map<String, dynamic> parsed = json.decode(responseBody);
    List<EmData> results =
        parsed["uploads"].map<EmData>((json) => EmData.fromJson(json)).toList();
    await updateTotal(int.parse(parsed["total"]));
    return results;
  }

  saveCache(String cacheString) async {
    Map<String, dynamic> cache = json.decode(cacheString);
    await HiveManager.instance.clear(feedsBox);
    await updateTotal(int.parse(cache["total"]));
    await HiveManager.instance.saveData(
        "lastsync", DateTime.now().millisecondsSinceEpoch.toString(), feedsBox);
    List<EmData> results =
        cache["uploads"].map<EmData>((json) => EmData.fromJson(json)).toList();
    for (var element in results) {
      await HiveManager.instance
          .saveData(element.id, element.properties, feedsBox);
    }
  }

  Map getQuery(int page) {
    return {
      "page": "$page",
      "hitsperpage": "30",
      "query": {
        "terms": [
          {"field": "id", "operation": "matches", "value": "*"}
        ]
      }
    };
  }

  Future<String> getRemoteData(
    Map? inQuery,
  ) async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + "/services/feed/channelfeed.json",
        inQuery,
        RequestType.post);
    return responsestring;
  }
}
