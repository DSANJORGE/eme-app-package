import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:eme_app_package/eme_http.dart';
import 'package:eme_app_package/utils/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eme_app_package/utils/log.dart';
import '../models/user.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import '../models/workspace.dart';
import '../utils/error_handler.dart';
import 'workspace_service.dart';

class AuthService {
  static String get mediaDBRoot => WorkspaceService.currentMediaDBRoot;

  /// The EnterMedia HTTP seam; swappable in tests.
  static EmeHttp http = DioEmeHttp();

  static String? _token;
  static String? _refreshToken;
  static DateTime? _tokenExpiration;
  static String? _userId;
  static User? _currentUser;

  static Future<void> loadSessionForActiveWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;

    _token = prefs.getString('entermediakey_$wsId');
    _userId = prefs.getString('user_$wsId');
    _refreshToken = prefs.getString('refresh_token_$wsId');
    final expString = prefs.getString('token_expiration_$wsId');
    if (expString != null) {
      _tokenExpiration = DateTime.tryParse(expString);
    } else {
      _tokenExpiration = null;
    }

    // Migration / fallback for legacy single key storage
    if ((_token == null || _token!.isEmpty) &&
        (wsId == 'development' ||
            wsId == WorkspaceService.workspaces.first.id)) {
      final legacyToken = prefs.getString('entermediakey');
      final legacyUser = prefs.getString('user');
      final legacyRefreshToken = prefs.getString('refresh_token');
      final legacyExpString = prefs.getString('token_expiration');
      if (legacyToken != null && legacyToken.isNotEmpty) {
        _token = legacyToken;
        _userId = legacyUser;
        _refreshToken = legacyRefreshToken;
        if (legacyExpString != null) {
          _tokenExpiration = DateTime.tryParse(legacyExpString);
        }
        await saveCredentials(
          _userId ?? '',
          _token!,
          refreshToken: _refreshToken,
          tokenExpiration: _tokenExpiration,
        );
      }
    }

    if (_token != null && _token!.isNotEmpty) {
      try {
        await fetchUser();
      } catch (e, stack) {
        logPrint('Error fetching user for workspace $wsId: $e');
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error fetching user during loadSessionForActiveWorkspace',
          customKeys: {'workspaceId': wsId},
        );
      }
    } else {
      _token = null;
      _refreshToken = null;
      _tokenExpiration = null;
      _userId = null;
      _currentUser = null;
    }
  }

  static late Dio _dio;

  static Future<void> init() async {
    await DioUtil.init();
    _dio = DioUtil.dio;

    await loadSessionForActiveWorkspace();
  }

  static Future<bool> switchWorkspace(
    Workspace workspace, {
    bool childOfCurrentWorkspace = true,
  }) async {
    String? currentUserId;
    String? currentToken;
    String? currentRefreshToken;
    DateTime? currentTokenExpiration;

    if (childOfCurrentWorkspace) {
      currentUserId = _userId;
      currentToken = _token;
      currentRefreshToken = _refreshToken;
      currentTokenExpiration = _tokenExpiration;
    }

    await WorkspaceService.setActiveWorkspace(workspace);

    OpenI.instance?.updateSettings(workspace.toJson());

    if (childOfCurrentWorkspace &&
        currentUserId != null &&
        currentToken != null) {
      await saveCredentials(
        currentUserId,
        currentToken,
        refreshToken: currentRefreshToken,
        tokenExpiration: currentTokenExpiration,
      );
    }

    await loadSessionForActiveWorkspace();
    return isLoggedIn;
  }

  static bool get isLoggedIn =>
      _token != null && _token!.isNotEmpty && _currentUser != null;
  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static DateTime? get tokenExpiration => _tokenExpiration;
  static String? get userId => _userId;
  static User? get currentUser => _currentUser;

  static Future<User?> fetchUser() async {
    if (_token == null || _token!.isEmpty) return null;

    const path = 'services/authentication/user.json';
    try {
      final data = await http.getJson(path);

      final userJson = data['user'] as Map<String, dynamic>;
      _currentUser = User.fromJson(userJson);
      if (_currentUser!.id.isNotEmpty) {
        _userId = _currentUser!.id;
      }
      try {
        final workspaceJson = data['servers'] as List<dynamic>;

        List<Workspace> customWorkspaces = workspaceJson.map((ws) {
          return Workspace.fromJson(ws);
        }).toList();

        WorkspaceService.addWorkspaces(customWorkspaces);
      } catch (e, stack) {
        logPrint('Failed to load workspaces: $e');
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'AuthService.fetchUser workspace parsing failed',
        );
      }

      return _currentUser;
    } catch (e, stack) {
      logPrint('Failed to fetch user');
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'AuthService.fetchUser failed',
          customKeys: {'url': path},
        );
      }
    }
    return null;
  }

  /// usersave.json convenience shared by the profile, consent and compliance
  /// screens. Throws EmeHttpException on failure (already recorded).
  static Future<void> saveUserFields(
    List<MapEntry<String, String>> fields, {
    MultipartFile? portrait,
  }) => http.post(
    'services/authentication/usersave.json',
    query: [
      const MapEntry('save', 'true'),
      MapEntry('userid', _userId ?? ''),
      MapEntry('username', _userId ?? ''),
      ...fields,
      if (portrait != null) const MapEntry('field', 'assetportrait'),
    ],
    files: portrait == null
        ? null
        : [MapEntry('file.assetportrait', portrait)],
  );

  static Future<void> saveCredentials(
    String userId,
    String key, {
    String? refreshToken,
    DateTime? tokenExpiration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;

    await prefs.setString('user_$wsId', userId);
    await prefs.setString('entermediakey_$wsId', key);
    if (refreshToken != null) {
      await prefs.setString('refresh_token_$wsId', refreshToken);
    }
    if (tokenExpiration != null) {
      await prefs.setString(
        'token_expiration_$wsId',
        tokenExpiration.toIso8601String(),
      );
    }

    await prefs.setString('user', userId);
    await prefs.setString('entermediakey', key);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    if (tokenExpiration != null) {
      await prefs.setString(
        'token_expiration',
        tokenExpiration.toIso8601String(),
      );
    }

    _token = key;
    _userId = userId;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (tokenExpiration != null) _tokenExpiration = tokenExpiration;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;

    logPrint('Logging out of $wsId');

    await prefs.remove('user_$wsId');
    await prefs.remove('entermediakey_$wsId');
    await prefs.remove('refresh_token_$wsId');
    await prefs.remove('token_expiration_$wsId');

    // Also remove global/legacy keys to prevent migration fallback from logging the user back in
    await prefs.remove('user');
    await prefs.remove('entermediakey');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiration');

    try {
      await DioUtil.clearCookies();
    } catch (e, stack) {
      logPrint('Error clearing cookies: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'AuthService.logout clearCookies failed',
      );
    }

    _token = null;
    _refreshToken = null;
    _tokenExpiration = null;
    _userId = null;
    _currentUser = null;
  }

  static Future<Map<String, dynamic>> sendUserCode({
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    final url = '$mediaDBRoot/services/authentication/sendusercode.json';
    logPrint('Logging in at $url');
    final Map<String, dynamic> body = {'email': email};
    if (firstName != null && firstName.trim().isNotEmpty) {
      body['firstName'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      body['lastName'] = lastName.trim();
    }

    try {
      final response = await _dio.post(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data)
            : response.data;
        final responseObj = data['response'] as Map<String, dynamic>?;
        if (responseObj != null) {
          return responseObj;
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        throw Exception(
          'Failed to send user code: Server returned status code ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'AuthService.sendUserCode failed',
        customKeys: {'email': email, 'url': url},
      );
      throw Exception('Failed to send user code: $e');
    }
  }

  static Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    const path = 'services/authentication/token.json';

    try {
      final data = await http.postForm(path, [
        const MapEntry('grant_type', 'refresh_token'),
        MapEntry('refresh_token', _refreshToken!),
      ], auth: EmeAuth.none);

      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        logPrint('Failed to refresh token: missing user in response');
        return false;
      }

      final key = data['access_token']?.toString() ?? '';
      final newRefreshToken = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'] as int?;
      DateTime? expiration;
      if (expiresIn != null) {
        expiration = DateTime.now().add(Duration(seconds: expiresIn));
      }

      if (key.isNotEmpty && _userId != null) {
        await saveCredentials(
          _userId!,
          key,
          refreshToken: newRefreshToken ?? _refreshToken,
          tokenExpiration: expiration,
        );
        return true;
      }
    } catch (e, stack) {
      logPrint('Failed to refresh token: $e');
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'AuthService.refreshAuthToken failed',
          customKeys: {'url': path},
        );
      }
    }
    return false;
  }

  static Future<void> loadWorkspaces() async {
    const path = 'services/server/list.json';

    try {
      final workspacesData = await http.getJson(
        path,
        auth: EmeAuth.keyAndUser,
      );

      final workspacesList = workspacesData['servers'] as List<dynamic>? ?? [];

      List<Workspace> customWorkspaces = workspacesList.map((ws) {
        final root = (ws['mediadbroot'] as String).replaceAll(
          RegExp(r'\/$'),
          '',
        );
        return Workspace(
          id: ws['id'] as String,
          name: ws['name'] as String,
          mediaDBRoot: root,
          iconAsset: ws['iconasset'] as String?,
        );
      }).toList();
      WorkspaceService.addWorkspaces(customWorkspaces);
    } catch (e, stack) {
      logPrint('Failed to load workspaces: $e');
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'AuthService.loadWorkspaces failed',
          customKeys: {'url': path},
        );
      }
    }
  }

  static Future<bool> loginWithOtp(String email, String otp) async {
    const path = 'services/authentication/token.json';

    try {
      final data = await http.postForm(path, [
        const MapEntry('grant_type', 'otp'),
        MapEntry('email', email),
        MapEntry('code', otp),
      ], auth: EmeAuth.none);

      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw Exception('Login response missing user');
      }

      final key = data['access_token']?.toString() ?? '';
      final refreshToken = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'] as int?;
      DateTime? expiration;
      if (expiresIn != null) {
        expiration = DateTime.now().add(Duration(seconds: expiresIn));
      }

      final userId = userJson['id']?.toString() ?? '';

      if (key.isNotEmpty) {
        await saveCredentials(
          userId,
          key,
          refreshToken: refreshToken,
          tokenExpiration: expiration,
        );

        await loadWorkspaces();

        _currentUser = User.fromJson(userJson);

        return true;
      } else {
        throw Exception('Login response missing access_token');
      }
    } on EmeHttpException catch (e) {
      // Non-200: the module already recorded it; surface the server's message.
      final body = e.body;
      final errorMsg = body is Map
          ? (body['error_description']?.toString() ?? body['error']?.toString())
          : null;
      throw Exception(
        'Authentication failed: '
        '${errorMsg ?? 'Server returned status code ${e.statusCode}'}',
      );
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'AuthService.loginWithOtp failed',
        customKeys: {'email': email, 'url': path},
      );
      throw Exception(
        'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }
}
