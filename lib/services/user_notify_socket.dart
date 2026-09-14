import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/log.dart';
import 'auth_service.dart';

/// Where and as whom to connect; null while signed out.
typedef UserNotifySession = ({Uri url, String userId, String key});

/// EnterMedia's per-user push channel (server:
/// `org.entermediadb.websocket.usernotify`). One socket for the signed-in
/// user: it logs in with `{command: login, userid, entermediakey}`, and every
/// JSON object the server sends through `UserNotifyManager.sentNotifications`
/// reaches [onEvent]. Drops reconnect with [backoff] until [stop].
///
/// Unlike `ChatSocketService` (one tutor channel, any user id), the server
/// checks the key here, and the events are the user's own.
class UserNotifySocket {
  UserNotifySocket({
    required this.onEvent,
    UserNotifySession? Function()? session,
    WebSocketChannel Function(Uri url)? connect,
  }) : _session = session ?? _signedIn,
       _connect = connect ?? WebSocketChannel.connect;

  final void Function(Map<String, dynamic> event) onEvent;
  final UserNotifySession? Function() _session;
  final WebSocketChannel Function(Uri url) _connect;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retry;
  Timer? _keepAlive;
  int _failures = 0;
  bool _running = false;
  bool _authenticated = false;

  /// Logged in and listening. False while connecting or waiting to retry.
  bool get isConnected => _authenticated;

  /// 1 s, 2 s, 4 s … capped at a minute.
  static Duration backoff(int failures) =>
      Duration(seconds: min(60, 1 << min(failures, 6)));

  /// Idempotent. Does nothing while signed out (call again after sign-in).
  void start() {
    if (_running) return;
    _running = true;
    _open();
  }

  void stop() {
    _running = false;
    _failures = 0;
    _close();
  }

  Future<void> _open() async {
    final s = _session();
    if (!_running || s == null) {
      _running = false;
      return;
    }
    final ch = _channel = _connect(s.url);
    try {
      await ch.ready;
    } catch (e) {
      logPrint('UserNotifySocket: connect failed ($e)');
      if (identical(ch, _channel)) _down();
      return;
    }
    // stop() (or stop + start) ran while this one was connecting.
    if (!identical(ch, _channel)) {
      ch.sink.close();
      return;
    }
    _sub = ch.stream.listen(
      _onData,
      onDone: _down,
      onError: (_) => _down(),
      cancelOnError: true,
    );
    ch.sink.add(
      jsonEncode({'command': 'login', 'userid': s.userId, 'entermediakey': s.key}),
    );
    // Traffic keeps proxies from closing an idle socket; the server ignores it.
    _keepAlive = Timer.periodic(
      const Duration(seconds: 20),
      (_) => ch.sink.add('{"command":"keepalive"}'),
    );
  }

  void _onData(dynamic raw) {
    final Object? m;
    try {
      m = jsonDecode(raw is String ? raw : utf8.decode(raw as List<int>));
    } catch (_) {
      return;
    }
    if (m is! Map) return;
    final event = Map<String, dynamic>.from(m);
    switch (event['command']) {
      case 'authenticated':
        _authenticated = true;
        _failures = 0;
      case 'authenticatefail':
        logPrint('UserNotifySocket: login refused (${event['reason']})');
        _down();
      default:
        onEvent(event);
    }
  }

  void _down() {
    _close();
    if (!_running) return;
    _retry = Timer(backoff(_failures++), () {
      if (_running && _channel == null) _open();
    });
  }

  void _close() {
    _authenticated = false;
    _retry?.cancel();
    _retry = null;
    _keepAlive?.cancel();
    _keepAlive = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  static UserNotifySession? _signedIn() {
    final oi = OpenI.instance;
    final userId = AuthService.userId ?? '';
    final key = AuthService.token ?? '';
    if (oi == null || userId.isEmpty || key.isEmpty) return null;
    return (
      url: Uri.parse(
        '${oi.settings.https ? 'wss' : 'ws'}://${oi.settings.siteroot}'
        '/entermedia/services/websocket/org/entermediadb/websocket/usernotify/UserNotifyConnection',
      ),
      userId: userId,
      key: key,
    );
  }
}
