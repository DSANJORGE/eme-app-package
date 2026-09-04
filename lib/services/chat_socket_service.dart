import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:eme_app_package/utils/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../utils/error_handler.dart';
import 'auth_service.dart';

enum SocketConnectionState { disconnected, connecting, connected, reconnecting }

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;

  late String _userId;
  late String _channelId;
  String? _sessionId;
  String? _baseUrl;
  String? _entermediakey;
  bool _isDisposed = false;

  String _catalogId = '';

  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  final StreamController<SocketConnectionState> _stateController =
      StreamController<SocketConnectionState>.broadcast();

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  final StreamController<Map<String, dynamic>> _rawEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  SocketConnectionState get connectionState => _connectionState;
  Stream<SocketConnectionState> get connectionStateStream =>
      _stateController.stream;
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get rawEventStream => _rawEventController.stream;
  bool get isConnected => _connectionState == SocketConnectionState.connected;
  String? get currentChannel => _channelId;

  /// Connect to Entermedia WebSocket Chat
  Future<void> connect({required String channel}) async {
    _isDisposed = false;
    _channelId = channel;
    _baseUrl = _resolveBaseUrl();
    _sessionId = _generateSessionId();

    _userId = _resolveUserId();
    _entermediakey = _resolveToken();

    _catalogId = _resolveCatalogId();

    if (_userId.isEmpty) {
      logPrint('ChatSocketService: cannot connect without a valid userId');
      return;
    }

    if (_connectionState == SocketConnectionState.connected ||
        _connectionState == SocketConnectionState.connecting) {
      if (channel != _channelId) {
        switchChannel(channel);
      }
      return;
    }

    _updateState(
      _connectionState == SocketConnectionState.disconnected
          ? SocketConnectionState.connecting
          : SocketConnectionState.reconnecting,
    );

    try {
      final wsUri = _buildWebSocketUri(
        baseUrl: _baseUrl!,
        sessionId: _sessionId!,
        userId: _userId,
        channel: _channelId,
        entermediakey: _entermediakey,
      );

      logPrint('ChatSocketService connecting to: $wsUri');

      _channel = WebSocketChannel.connect(wsUri);
      await _channel!.ready;

      logPrint('ChatSocketService connected');

      _updateState(SocketConnectionState.connected);
      _startKeepAlive();

      _streamSubscription = _channel!.stream.listen(
        _onMessageReceived,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );
    } catch (e, stack) {
      logPrint('ChatSocketService connection error: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'ChatSocketService connection error',
        customKeys: {'channel': channel, 'baseUrl': _baseUrl ?? ''},
      );
      _handleDisconnectAndReconnect();
    }
  }

  /// Send chat message
  void sendMessage({
    required String message,
    String? channel,
    String? replyToId,
    String? command,
    String? functionName,
    String? nextFunctionName,
    String? messageType,
    Map<String, dynamic>? extraData,
  }) {
    final targetChannel = channel ?? _channelId;

    final data = <String, dynamic>{
      'message': message,
      'channel': targetChannel,
      'user': _userId,
      'catalogid': _catalogId,
      if (replyToId != null && replyToId.isNotEmpty) 'replytoid': replyToId,
      if (command != null && command.isNotEmpty) 'command': command,
      if (functionName != null && functionName.isNotEmpty)
        'functionname': functionName,
      if (nextFunctionName != null && nextFunctionName.isNotEmpty)
        'nextfunctionname': nextFunctionName,
      'messagetype': ?messageType,
      ...?extraData,
    };

    logPrint('ChatSocketService sendMessage: $data');

    sendRaw(data);
  }

  /// Send raw map data over websocket
  void sendRaw(Map<String, dynamic> data) {
    if (_connectionState != SocketConnectionState.connected ||
        _channel == null) {
      logPrint(
        'ChatSocketService: Socket not connected. Message dropped: $data',
      );
      return;
    }

    try {
      final jsonStr = json.encode(data);
      _channel!.sink.add(jsonStr);
      logPrint('ChatSocketService sent: $jsonStr');
    } catch (e, stack) {
      logPrint('ChatSocketService error sending message: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'ChatSocketService sendRaw error',
        customKeys: {'data': data.toString()},
      );
    }
  }

  /// Switch channel
  void switchChannel(String channelId) {
    if (_channelId == channelId) return;
    _channelId = channelId;
    // Reconnect to subscribe to new channel endpoint if needed
    if (isConnected) {
      disconnect(reconnect: true);
    }
  }

  /// Handle incoming message from socket stream
  void _onMessageReceived(dynamic rawData) {
    try {
      logPrint('ChatSocketService rawData received: $rawData');
      String strData;
      if (rawData is String) {
        strData = rawData;
      } else if (rawData is List<int>) {
        strData = utf8.decode(rawData);
      } else {
        return;
      }

      final decoded = json.decode(strData);

      void processMessage(Map<String, dynamic> data) {
        _rawEventController.add(data);
        final chatMessage = ChatMessage.fromJson(data);
        _messageController.add(chatMessage);
      }

      if (decoded is Map<String, dynamic>) {
        processMessage(decoded);
      } else if (decoded is List) {
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            processMessage(item);
          } else if (item is Map) {
            processMessage(Map<String, dynamic>.from(item));
          }
        }
      } else if (decoded is Map) {
        processMessage(Map<String, dynamic>.from(decoded));
      }
    } catch (e, stack) {
      logError('ChatSocketService error parsing incoming message: $e\n$stack');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'ChatSocketService error parsing incoming message',
      );
    }
  }

  /// Periodic KeepAlive every 20 seconds matching chat.js
  void _startKeepAlive() {
    _stopKeepAlive();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (isConnected) {
        final keepAliveData = <String, dynamic>{
          'command': 'keepalive',
          'userid': _userId,
          if (_channelId.isNotEmpty) 'channel': _channelId,
        };
        sendRaw(keepAliveData);
      } else {
        _handleDisconnectAndReconnect();
      }
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  void _onSocketError(dynamic error) {
    logPrint('ChatSocketService stream error: $error');
    AppErrorHandler.recordNonFatal(
      error,
      null,
      reason: 'ChatSocketService stream error',
      customKeys: {'channel': _channelId},
    );
    _handleDisconnectAndReconnect();
  }

  void _onSocketDone() {
    logPrint('ChatSocketService connection closed.');
    _handleDisconnectAndReconnect();
  }

  void _handleDisconnectAndReconnect() {
    _stopKeepAlive();
    _streamSubscription?.cancel();
    _streamSubscription = null;

    if (_isDisposed) {
      _updateState(SocketConnectionState.disconnected);
      return;
    }

    _updateState(SocketConnectionState.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed &&
          _connectionState != SocketConnectionState.connected &&
          _connectionState != SocketConnectionState.connecting) {
        connect(channel: _channelId);
      }
    });
  }

  /// Disconnect current session
  void disconnect({bool reconnect = false}) {
    _reconnectTimer?.cancel();
    _stopKeepAlive();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _channel?.sink.close();
    _channel = null;

    if (!reconnect) {
      _updateState(SocketConnectionState.disconnected);
    } else {
      connect(channel: _channelId);
    }
  }

  /// Clean up resources
  void dispose() {
    _isDisposed = true;
    disconnect();
  }

  void _updateState(SocketConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _stateController.add(newState);
    }
  }

  String _generateSessionId() {
    final rand = Random().nextDouble();
    return rand.toString();
  }

  String _resolveUserId() {
    return AuthService.userId!;
  }

  String _resolveCatalogId() {
    if (Get.isRegistered<OpenI>()) {
      final oi = Get.find<OpenI>();
      return oi.settings.catalogId;
    }
    throw Exception('catalogid not found in app settings');
  }

  String _resolveBaseUrl() {
    try {
      if (Get.isRegistered<OpenI>()) {
        final oi = Get.find<OpenI>();
        final siteRoot = oi.settings.siteroot;
        final scheme = oi.settings.https ? 'wss' : 'ws';
        return '$scheme://$siteRoot/entermedia/services/websocket/org/entermediadb/websocket/chat/ChatConnection';
      }
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'ChatSocketService _resolveBaseUrl failed',
      );
    }
    throw Exception('chat_socket_url not found in app settings');
  }

  String? _resolveToken() {
    if (AuthService.token != null && AuthService.token!.isNotEmpty) {
      return AuthService.token;
    }
    return null;
  }

  Uri _buildWebSocketUri({
    required String baseUrl,
    required String sessionId,
    required String userId,
    String? channel,
    String? entermediakey,
  }) {
    final httpUri = Uri.parse(baseUrl);
    final wsScheme = (httpUri.scheme == 'https' || httpUri.scheme == 'wss')
        ? 'wss'
        : 'ws';

    final path = httpUri.path.endsWith('/ChatConnection')
        ? httpUri.path
        : '/entermedia/services/websocket/org/entermediadb/websocket/chat/ChatConnection';

    final queryParameters = <String, String>{
      'sessionid': sessionId,
      'userid': userId,
      if (channel != null && channel.isNotEmpty) 'channel': channel,
      'channeltype': 'agenttutorchat',
      if (entermediakey != null && entermediakey.isNotEmpty)
        'entermedia.key': entermediakey,
    };

    return Uri(
      scheme: wsScheme,
      host: httpUri.host,
      port: httpUri.hasPort ? httpUri.port : null,
      path: path,
      queryParameters: queryParameters,
    );
  }
}
