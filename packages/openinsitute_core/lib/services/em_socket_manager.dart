import 'dart:convert';

import 'package:get/get.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class EmSocketManager {
  WebSocketChannel? channel;
  WebSocketChannel? chat;

  OpenI get oi {
    return Get.find();
  }

  connect() async {
    // String entermediakey = "1114md542420a20f0be0db2c0be3709e0fe09b2c0bf0a84266tstampb9dIRTwjfcNON2/UikPQig==";
    String url =
        "${oi.app!["websocket_url"]}?entermedia.key=${oi.authenticationmanager.emUser!.entermediakey}";
    channel = WebSocketChannel.connect(Uri.parse(url));
    // channel!.stream.listen((data) {
    //   print("!!!!new msg: $data");

    // });

    String chatSocketBase = oi.app!["chat_socket_url"] ??
        oi.app!["websocket_url"]?.toString().replaceAll(
              '/OIConnection',
              '/chat/ChatConnection',
            );
    String chaturl =
        "$chatSocketBase?channeltype=agenttutorchat&entermedia.key=${oi.authenticationmanager.emUser!.entermediakey}";
    chat = WebSocketChannel.connect(Uri.parse(chaturl));
    // chat!.stream.listen((data) {
    //   print("!!!!new msg: $data");
    // });
    //handleMessages(channel!.stream);
  }

  Stream<dynamic> get stream {
    return channel!.stream;
  }

  sendChatMessage(Map inMessage) async {
    if (chat == null) {
      await connect();
    }
    chat!.sink.add(inMessage);
  }

  sendMessage(Map inMessage) async {
    if (channel == null) {
      await connect();
    }
    channel!.sink.add(jsonEncode(inMessage));
  }

  sendString(String inString) async {
    if (channel == null) {
      await connect();
    }
    channel!.sink.add(inString);
  }
}
