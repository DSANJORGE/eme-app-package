import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_eme_base/utils/log.dart';
import '../models/user.dart';
import '../models/workspace.dart';
import 'workspace_service.dart';

class AuthService {
  static String get mediaDBRoot => WorkspaceService.currentMediaDBRoot;

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
      } catch (e) {
        logPrint('Error fetching user for workspace $wsId: $e');
      }
    } else {
      _token = null;
      _refreshToken = null;
      _tokenExpiration = null;
      _userId = null;
      _currentUser = null;
    }
  }

  static Future<void> init() async {
    await loadSessionForActiveWorkspace();
  }

  static Future<bool> switchWorkspace(
    Workspace workspace, {
    bool childOfCurrentWorkspace = false,
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

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static DateTime? get tokenExpiration => _tokenExpiration;
  static String? get userId => _userId;
  static User? get currentUser => _currentUser;

  static Future<User?> fetchUser() async {
    if (_token == null || _token!.isEmpty) return null;

    final url = Uri.parse('$mediaDBRoot/services/authentication/user.json');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': _token!,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final userJson = data['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        if (_currentUser!.id.isNotEmpty) {
          _userId = _currentUser!.id;
        }
        try {
          final workspaceJson = data['servers'] as List<dynamic>;
          List<Workspace> customWorkspaces = workspaceJson.map((ws) {
            return Workspace(
              id: ws['id'] as String,
              name: ws['name'] as String,
              mediaDBRoot: ws['mediadbroot'] as String,
              iconAsset: ws['iconasset'] as String?,
            );
          }).toList();
          logPrint("workspaces $customWorkspaces");
          WorkspaceService.addWorkspaces(customWorkspaces);
        } catch (e) {
          logPrint('Failed to load workspaces: $e');
        }

        return _currentUser;
      }
    } catch (e) {
      logPrint('Failed to fetch user');
    }
    return null;
  }

  static Future<Map<String, String>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;
    _userId = prefs.getString('user_$wsId') ?? prefs.getString('user');
    _token =
        prefs.getString('entermediakey_$wsId') ??
        prefs.getString('entermediakey');
    return {'user': _userId ?? '', 'entermediakey': _token ?? ''};
  }

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

    await prefs.remove('user_$wsId');
    await prefs.remove('entermediakey_$wsId');
    await prefs.remove('refresh_token_$wsId');
    await prefs.remove('token_expiration_$wsId');

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
    final url = Uri.parse(
      '$mediaDBRoot/services/authentication/sendusercode.json',
    );
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> body = {'email': email};
    if (firstName != null && firstName.trim().isNotEmpty) {
      body['firstName'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      body['lastName'] = lastName.trim();
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
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
    } catch (e) {
      throw Exception('Failed to send user code: $e');
    }
  }

  static Future<bool> loginWithPassword(String email, String password) async {
    return _login({'email': email, 'password': password});
  }

  static Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    final url = Uri.parse('$mediaDBRoot/services/authentication/token.json');
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final Map<String, String> body = {
      'grant_type': 'refresh_token',
      'refresh_token': _refreshToken!,
    };

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

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
      }
    } catch (e) {
      logPrint('Failed to refresh token: $e');
    }
    return false;
  }

  static Future<void> loadWorkspaces() async {
    final workspacesUrl = Uri.parse('$mediaDBRoot/services/server/list.json');

    final Map<String, String> credentials = await AuthService.getCredentials();
    final workspacesResponse = await http.get(
      workspacesUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-tokentype': 'entermedia',
        'X-entermediakey': credentials['entermediakey']!,
        'X-userid': credentials['user']!,
      },
    );

    if (workspacesResponse.statusCode == 200) {
      final Map<String, dynamic> workspacesData = json.decode(
        workspacesResponse.body,
      );

      final workspacesList = workspacesData['servers'] as List<dynamic>? ?? [];

      List<Workspace> customWorkspaces = workspacesList.map((ws) {
        return Workspace(
          id: ws['id'] as String,
          name: ws['name'] as String,
          mediaDBRoot: ws['mediadbroot'] as String,
          iconAsset: ws['iconasset'] as String?,
        );
      }).toList();
      WorkspaceService.addWorkspaces(customWorkspaces);
    }
  }

  static Future<bool> loginWithOtp(String email, String otp) async {
    final url = Uri.parse('$mediaDBRoot/services/authentication/token.json');
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final Map<String, String> body = {
      'grant_type': 'otp',
      'email': email,
      'code': otp,
    };

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final key = data['access_token']?.toString() ?? '';
        final refreshToken = data['refresh_token']?.toString();
        final expiresIn = data['expires_in'] as int?;
        DateTime? expiration;
        if (expiresIn != null) {
          expiration = DateTime.now().add(Duration(seconds: expiresIn));
        }
        final userJson = data['user'] as Map<String, dynamic>?;
        final userId = userJson?['id']?.toString() ?? '';

        if (key.isNotEmpty) {
          await saveCredentials(
            userId,
            key,
            refreshToken: refreshToken,
            tokenExpiration: expiration,
          );

          await loadWorkspaces();

          if (userJson != null) {
            _currentUser = User.fromJson(userJson);
          } else if (userId.isNotEmpty) {
            await fetchUser();
          }

          return true;
        } else {
          throw Exception('Login response missing access_token');
        }
      } else {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final errorMsg =
              data['error_description']?.toString() ??
              data['error']?.toString() ??
              'Authentication failed';
          throw Exception(errorMsg);
        } catch (_) {
          throw Exception(
            'Authentication failed: Server returned status code ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      throw Exception(
        'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  static Future<bool> _login(Map<String, dynamic> requestBody) async {
    final url = Uri.parse('$mediaDBRoot/services/authentication/login.json');
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final responseObj = data['response'] as Map<String, dynamic>?;

        if (responseObj != null && responseObj['status'] == 'ok') {
          final userJson = data['user'] as Map<String, dynamic>?;
          final key = data['entermediakey']?.toString() ?? '';
          final userId =
              userJson?['id']?.toString() ??
              responseObj['user']?.toString() ??
              '';

          if (key.isNotEmpty) {
            await saveCredentials(userId, key);

            await loadWorkspaces();

            if (userJson != null) {
              _currentUser = User.fromJson(userJson);
            } else if (userId.isNotEmpty) {
              await fetchUser();
            }

            return true;
          } else {
            throw Exception('Login response missing entermediakey');
          }
        } else {
          final errorMsg =
              data['error']?.toString() ??
              responseObj?['message']?.toString() ??
              'Authentication failed';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception(
          'Authentication failed: Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }
}
