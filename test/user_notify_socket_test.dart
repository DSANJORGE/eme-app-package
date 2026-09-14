import 'dart:convert';

import 'package:eme_app_package/services/user_notify_socket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket/testing.dart';
import 'package:web_socket/web_socket.dart';
import 'package:web_socket_channel/adapter_web_socket_channel.dart';

/// Client end wired to a fake server end the test drives.
class _Server {
  final received = <Map<String, dynamic>>[];
  late WebSocket peer;
  int connects = 0;

  AdapterWebSocketChannel connect(Uri _) {
    connects++;
    final (client, server) = fakes();
    peer = server;
    server.events.listen((e) {
      if (e is TextDataReceived) received.add(jsonDecode(e.text));
    });
    return AdapterWebSocketChannel(client);
  }

  void send(Map<String, dynamic> m) => peer.sendText(jsonEncode(m));
}

void main() {
  test('backoff doubles from 1 s and caps at a minute', () {
    expect(
      [for (var i = 0; i < 8; i++) UserNotifySocket.backoff(i).inSeconds],
      [1, 2, 4, 8, 16, 32, 60, 60],
    );
  });

  test('logs in, forwards server events, reconnects after a drop', () async {
    final server = _Server();
    final events = <Map<String, dynamic>>[];
    final socket = UserNotifySocket(
      onEvent: events.add,
      session: () =>
          (url: Uri.parse('ws://x/usernotify'), userId: 'ana', key: 'k1'),
      connect: server.connect,
    );
    socket.start();
    socket.start(); // idempotent: still one connection
    await pumpEventQueue();
    expect(server.connects, 1);
    expect(server.received.single, {
      'command': 'login',
      'userid': 'ana',
      'entermediakey': 'k1',
    });

    server.send({'command': 'authenticated'});
    server.send({'type': 'progress', 'connectionid': null});
    await pumpEventQueue();
    expect(socket.isConnected, isTrue);
    expect(events.map((e) => e['type']), ['progress']);

    await server.peer.close();
    await pumpEventQueue();
    expect(socket.isConnected, isFalse);
    // First retry after 1 s.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await pumpEventQueue();
    expect(server.connects, 2);

    socket.stop();
    await pumpEventQueue();
    expect(socket.isConnected, isFalse);
  });

  test('signed out: start does nothing and can start again later', () async {
    final server = _Server();
    UserNotifySession? session;
    final socket = UserNotifySocket(
      onEvent: (_) {},
      session: () => session,
      connect: server.connect,
    );
    socket.start();
    await pumpEventQueue();
    expect(server.connects, 0);
    session = (url: Uri.parse('ws://x'), userId: 'ana', key: 'k');
    socket.start();
    await pumpEventQueue();
    expect(server.connects, 1);
    socket.stop();
  });
}
