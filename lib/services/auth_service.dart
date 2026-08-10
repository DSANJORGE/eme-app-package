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
  static String? _userId;
  static User? _currentUser;

  static Future<void> loadSessionForActiveWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;

    _token = prefs.getString('entermediakey_$wsId');
    _userId = prefs.getString('user_$wsId');

    // Migration / fallback for legacy single key storage
    if ((_token == null || _token!.isEmpty) &&
        (wsId == 'development' || wsId == WorkspaceService.workspaces.first.id)) {
      final legacyToken = prefs.getString('entermediakey');
      final legacyUser = prefs.getString('user');
      if (legacyToken != null && legacyToken.isNotEmpty) {
        _token = legacyToken;
        _userId = legacyUser;
        await saveCredentials(_userId ?? '', _token!);
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
      _userId = null;
      _currentUser = null;
    }
  }

  static Future<void> init() async {
    await loadSessionForActiveWorkspace();
  }

  static Future<bool> switchWorkspace(Workspace workspace) async {
    await WorkspaceService.setActiveWorkspace(workspace);
    await loadSessionForActiveWorkspace();
    return isLoggedIn;
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  static String? get token => _token;
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
        logPrint("data: $data");
        final userJson = data['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        if (_currentUser!.id.isNotEmpty) {
          _userId = _currentUser!.id;
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
    _token = prefs.getString('entermediakey_$wsId') ?? prefs.getString('entermediakey');
    return {'user': _userId ?? '', 'entermediakey': _token ?? ''};
  }

  static Future<void> saveCredentials(String userId, String key) async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;

    await prefs.setString('user_$wsId', userId);
    await prefs.setString('entermediakey_$wsId', key);

    await prefs.setString('user', userId);
    await prefs.setString('entermediakey', key);

    _token = key;
    _userId = userId;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final wsId = WorkspaceService.activeWorkspace.id;

    await prefs.remove('user_$wsId');
    await prefs.remove('entermediakey_$wsId');

    _token = null;
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

  static Future<bool> loginWithOtp(String email, String otp) async {
    return _login({'email': email, 'templogincode': otp});
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
          final userId = userJson?['id']?.toString() ?? responseObj['user']?.toString() ?? '';

          if (key.isNotEmpty) {
            await saveCredentials(userId, key);

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
      throw Exception('Authentication failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
