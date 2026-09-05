import 'dart:convert';

import 'package:dio/dio.dart';

import 'services/auth_service.dart';
import 'services/workspace_service.dart';
import 'utils/dio.dart';
import 'utils/error_handler.dart';
import 'utils/log.dart';

/// EnterMedia HTTP module. One instance per app (or per test).
/// Design: Traycer artifact `entermedia-http-seam-design` (Design B).
///
/// Contract — everything a caller must know:
/// - `path` is relative to the ACTIVE workspace's mediaDBRoot, re-resolved on
///   every call (switchWorkspace-safe). Absolute URLs are rejected (assert):
///   the module only talks to the workspace host, so the token cannot leak to
///   Asset.url hosts.
/// - Auth: [EmeAuth.token] (default) sends `Authorization: Bearer <token>`
///   (server refactored to Bearer upstream, 2026-08-31).
///   [EmeAuth.none] for pre-auth calls — refresh/login cannot recurse.
///   [EmeAuth.keyAndUser] for the legacy X-entermediakey/X-userid variant.
/// - Query and form VALUES are percent-encoded here; callers pass raw strings.
///   Repeated keys are allowed (usersave's `field=a&…&field=b`), hence
///   entry lists instead of Maps where repeats occur.
/// - HTTP 200 → decoded JSON map. A String body is json-decoded; a bare JSON
///   array is wrapped as `{'data': [...]}`; an empty body becomes `{}`.
///   Any other status → [EmeHttpException] carrying the decoded error body;
///   transport failure → [EmeHttpException] with statusCode null.
///   Every failure is recorded to AppErrorHandler exactly once, in here,
///   before throwing. Callers keep their own policy (return [] vs rethrow)
///   but never record the same failure again.
/// - [post] with files never forces Content-Type — Dio owns the multipart
///   boundary. files == null sends no body.
/// - No init-order dependency: Dio is resolved lazily per call, so
///   constructing this before DioUtil.init() is safe.
/// - 401/403 are NOT retried (decided 2026-08-30); a future refresh-retry
///   lands inside [DioEmeHttp] without changing this interface. They do
///   fire [onUnauthorized] (2026-09-04): eMe keeps one token per user, so a
///   login elsewhere kills this session and every call 403s from then on.
abstract class EmeHttp {
  /// Called once per authenticated call that comes back 401/403, before
  /// the exception is thrown. The app decides what to do (sign out).
  static void Function(EmeHttpException e)? onUnauthorized;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
    EmeAuth auth = EmeAuth.token,
  });

  /// x-www-form-urlencoded body (continue.json mutations, token.json).
  Future<Map<String, dynamic>> postForm(
    String path,
    Iterable<MapEntry<String, String>> fields, {
    EmeAuth auth = EmeAuth.token,
  });

  /// Command-style POST: params in the query string, optional multipart
  /// files in the body (usersave.json).
  Future<Map<String, dynamic>> post(
    String path, {
    Iterable<MapEntry<String, String>> query = const [],
    List<MapEntry<String, MultipartFile>>? files,
    EmeAuth auth = EmeAuth.token,
  });
}

enum EmeAuth { none, token, keyAndUser }

class EmeHttpException implements Exception {
  EmeHttpException({required this.uri, this.statusCode, this.body, this.cause});

  final Uri uri;
  final int? statusCode; // null = transport failure
  final Object? body; // decoded server body when available
  final Object? cause;

  @override
  String toString() =>
      'EmeHttpException(${statusCode ?? cause}, $uri)';
}

/// What the module needs from auth — not all of AuthService.
abstract class EmeSession {
  String? get token;
  String? get userId;
}

class _AuthSession implements EmeSession {
  const _AuthSession();

  @override
  String? get token => AuthService.token;

  @override
  String? get userId => AuthService.userId;
}

/// Production adapter over the shared Dio (Accept-Language + cookies ride
/// along). Tests use FakeEmeHttp against the same interface instead.
class DioEmeHttp implements EmeHttp {
  DioEmeHttp({
    Dio Function()? dio,
    EmeSession? session,
    String Function()? baseUrl,
  }) : _dio = dio ?? (() => DioUtil.dio),
       _session = session ?? const _AuthSession(),
       _baseUrl = baseUrl ?? (() => WorkspaceService.currentMediaDBRoot);

  final Dio Function() _dio;
  final EmeSession _session;
  final String Function() _baseUrl;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
    EmeAuth auth = EmeAuth.token,
  }) => _send('GET', path, query: query.entries, auth: auth);

  @override
  Future<Map<String, dynamic>> postForm(
    String path,
    Iterable<MapEntry<String, String>> fields, {
    EmeAuth auth = EmeAuth.token,
  }) => _send(
    'POST',
    path,
    auth: auth,
    body: _encode(fields),
    contentType: Headers.formUrlEncodedContentType,
  );

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Iterable<MapEntry<String, String>> query = const [],
    List<MapEntry<String, MultipartFile>>? files,
    EmeAuth auth = EmeAuth.token,
  }) => _send(
    'POST',
    path,
    query: query,
    auth: auth,
    body: files == null ? null : (FormData()..files.addAll(files)),
  );

  static String _encode(Iterable<MapEntry<String, String>> kv) => kv
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');

  Map<String, String> _headers(EmeAuth auth) => switch (auth) {
    EmeAuth.none => {'Accept': 'application/json'},
    EmeAuth.token => {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_session.token ?? ''}',
    },
    EmeAuth.keyAndUser => {
      'Accept': 'application/json',
      'X-entermediakey': _session.token ?? '',
      'X-userid': _session.userId ?? '',
    },
  };

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Iterable<MapEntry<String, String>> query = const [],
    required EmeAuth auth,
    Object? body,
    String? contentType,
  }) async {
    assert(
      !path.startsWith('http') && !path.startsWith('/'),
      'EmeHttp takes workspace-relative paths, got: $path',
    );
    final qs = _encode(query);
    final uri = Uri.parse('${_baseUrl()}/$path${qs.isEmpty ? '' : '?$qs'}');
    logPrint('EmeHttp $method $uri');

    final Response<dynamic> response;
    try {
      response = await _dio().request<dynamic>(
        uri.toString(),
        data: body,
        options: Options(
          method: method,
          headers: _headers(auth),
          contentType: contentType,
          validateStatus: (_) => true,
        ),
      );
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'EmeHttp $method $path transport failed',
        customKeys: {'url': uri.toString()},
      );
      throw EmeHttpException(uri: uri, cause: e);
    }

    Object? decoded = response.data;
    if (decoded is String && decoded.trim().isNotEmpty) {
      try {
        decoded = json.decode(decoded);
      } on FormatException {
        // Non-JSON body: keep the raw string for the exception below.
      }
    }

    if (response.statusCode != 200) {
      final e = EmeHttpException(
        uri: uri,
        statusCode: response.statusCode,
        body: decoded,
      );
      AppErrorHandler.recordNonFatal(
        e,
        StackTrace.current,
        reason: 'EmeHttp $method $path returned HTTP ${response.statusCode}',
        customKeys: {'url': uri.toString()},
      );
      if (auth != EmeAuth.none &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        EmeHttp.onUnauthorized?.call(e);
      }
      throw e;
    }

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'data': decoded};
    if (decoded == null || (decoded is String && decoded.trim().isEmpty)) {
      return <String, dynamic>{};
    }
    final e = EmeHttpException(
      uri: uri,
      statusCode: 200,
      body: decoded,
      cause: const FormatException('Expected a JSON object'),
    );
    AppErrorHandler.recordNonFatal(
      e,
      StackTrace.current,
      reason: 'EmeHttp $method $path returned non-JSON 200 body',
      customKeys: {'url': uri.toString()},
    );
    throw e;
  }
}
