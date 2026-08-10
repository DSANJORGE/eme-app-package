import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_eme_base/utils/log.dart';
import '../models/workspace.dart';
import 'auth_service.dart';
import 'workspace_service.dart';

class DeepLinkService {
  static StreamSubscription<Uri>? _sub;
  static final AppLinks _appLinks = AppLinks();
  static Map<String, String> _lastParameters = {};

  /// Returns the last processed web or deep link parameters.
  static Map<String, String> get lastParameters =>
      Map.unmodifiable(_lastParameters);

  /// Initialize deep link listening.
  /// Calls [onWorkspaceOpened] when a valid workspace deep link is processed.
  /// Calls [onParametersReceived] when parameters are extracted from a web URL or deep link.
  static Future<void> init({
    void Function(Workspace workspace)? onWorkspaceOpened,
    void Function(Map<String, String> parameters)? onParametersReceived,
  }) async {
    // Handle initial link from AppLinks if app was launched via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(
          initialUri,
          onWorkspaceOpened: onWorkspaceOpened,
          onParametersReceived: onParametersReceived,
        );
      }
    } catch (e) {
      logPrint('Error getting initial deep link: $e');
    }

    // On Web (or platform launch), also process current window location from Uri.base
    if (kIsWeb) {
      try {
        final webUri = Uri.base;
        logPrint('Reading web parameters from Uri.base: $webUri');
        await _handleUri(
          webUri,
          onWorkspaceOpened: onWorkspaceOpened,
          onParametersReceived: onParametersReceived,
        );
      } catch (e) {
        logPrint('Error reading web parameters from Uri.base: $e');
      }
    }

    // Listen for incoming deep links while app is running
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleUri(
          uri,
          onWorkspaceOpened: onWorkspaceOpened,
          onParametersReceived: onParametersReceived,
        );
      },
      onError: (err) {
        logPrint('Deep link stream error: $err');
      },
    );
  }

  /// Helper to read and extract parameters directly from Web URL (`Uri.base`).
  static Map<String, String> getWebParameters() {
    return parseParametersFromUri(Uri.base);
  }

  /// Extracts all query parameters, fragment parameters, and path parameters from a Uri into a normalized Map.
  static Map<String, String> parseParametersFromUri(Uri uri) {
    final Map<String, String> params = {};

    // 1. Standard query parameters (e.g. ?workspace=minsur&user=admin)
    params.addAll(uri.queryParameters);

    // 2. Parse fragment parameters if present (e.g. #/?workspace=minsur or #/workspace/minsur?lang=en)
    if (uri.hasFragment && uri.fragment.isNotEmpty) {
      final fragment = uri.fragment;
      String fragmentPath = fragment;
      String? fragmentQuery;

      final queryIndex = fragment.indexOf('?');
      if (queryIndex != -1) {
        fragmentPath = fragment.substring(0, queryIndex);
        fragmentQuery = fragment.substring(queryIndex + 1);
      }

      if (fragmentQuery != null && fragmentQuery.isNotEmpty) {
        final fragmentQueryUri = Uri.parse('http://dummy?$fragmentQuery');
        params.addAll(fragmentQueryUri.queryParameters);
      }

      if (fragmentPath.contains('=')) {
        final fragmentUri = Uri.parse('http://dummy?$fragmentPath');
        params.addAll(fragmentUri.queryParameters);
      } else if (fragmentPath.isNotEmpty && fragmentPath != '/') {
        final cleanPath =
            fragmentPath.startsWith('/') ? fragmentPath : '/$fragmentPath';
        final fragmentPathUri = Uri.parse('http://dummy$cleanPath');
        final pathWs = _extractWorkspaceFromPath(fragmentPathUri);
        if (pathWs != null && !params.containsKey('workspace')) {
          params['workspace'] = pathWs;
        }
      }
    }

    // 3. Normalize common parameter aliases
    final normalized = Map<String, String>.from(params);

    // MediaDBRoot aliases: mediaDBRoot / mediadb -> mediadbroot
    if (!normalized.containsKey('mediadbroot')) {
      if (normalized.containsKey('mediaDBRoot')) {
        normalized['mediadbroot'] = normalized['mediaDBRoot']!;
      } else if (normalized.containsKey('mediadb')) {
        normalized['mediadbroot'] = normalized['mediadb']!;
      }
    }

    // Workspace aliases: ws / id / name -> workspace
    if (!normalized.containsKey('workspace')) {
      if (normalized.containsKey('ws')) {
        normalized['workspace'] = normalized['ws']!;
      } else if (normalized.containsKey('id')) {
        normalized['workspace'] = normalized['id']!;
      } else if (normalized.containsKey('name')) {
        normalized['workspace'] = normalized['name']!;
      }
    }

    // User aliases: username / userId -> user
    if (!normalized.containsKey('user')) {
      if (normalized.containsKey('username')) {
        normalized['user'] = normalized['username']!;
      } else if (normalized.containsKey('userId')) {
        normalized['user'] = normalized['userId']!;
      }
    }

    // Token aliases: token / key / apikey -> entermediakey
    if (!normalized.containsKey('entermediakey')) {
      if (normalized.containsKey('token')) {
        normalized['entermediakey'] = normalized['token']!;
      } else if (normalized.containsKey('key')) {
        normalized['entermediakey'] = normalized['key']!;
      } else if (normalized.containsKey('apikey')) {
        normalized['entermediakey'] = normalized['apikey']!;
      }
    }

    // OTP / temp login aliases: otp / code -> templogincode
    if (!normalized.containsKey('templogincode')) {
      if (normalized.containsKey('otp')) {
        normalized['templogincode'] = normalized['otp']!;
      } else if (normalized.containsKey('code')) {
        normalized['templogincode'] = normalized['code']!;
      }
    }

    // 4. Extract path workspace if not already present
    if (!normalized.containsKey('workspace')) {
      final pathWs = _extractWorkspaceFromPath(uri);
      if (pathWs != null) {
        normalized['workspace'] = pathWs;
      }
    }

    return normalized;
  }

  static String? _extractWorkspaceFromPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    for (int i = 0; i < segments.length; i++) {
      if (segments[i].toLowerCase() == 'workspace') {
        if (i + 1 < segments.length) {
          return segments[i + 1];
        }
      }
    }

    if (segments.isNotEmpty) {
      if (uri.host.toLowerCase() == 'workspace') {
        return segments.first;
      } else if (segments.first.toLowerCase() != 'workspace') {
        return segments.first;
      }
    }

    if (uri.host.isNotEmpty &&
        uri.host.toLowerCase() != 'workspace' &&
        uri.host.toLowerCase() != 'eme.world' &&
        uri.host.toLowerCase() != 'localhost' &&
        !uri.host.contains('.127.')) {
      return uri.host;
    }

    return null;
  }

  /// Parses a Workspace target from the provided Uri or creates a dynamic workspace if [mediadbroot] is provided.
  /// Returns null if no matching or dynamic workspace could be created.
  static Workspace? parseWorkspaceFromUri(Uri uri) {
    final params = parseParametersFromUri(uri);

    final httpsVal = params['https'] ?? params['ssl'];
    final useHttps = httpsVal?.toLowerCase() != 'false';

    // 1. Direct mediadbroot parameter in URL or deep link
    final mediaDBRoot = params['mediadbroot'];
    if (mediaDBRoot != null && mediaDBRoot.trim().isNotEmpty) {
      final wsId = params['workspace'];
      final wsName = params['name'];
      return WorkspaceService.getOrCreateWorkspaceFromMediaDBRoot(
        mediaDBRoot,
        id: wsId,
        name: wsName,
        useHttps: useHttps,
      );
    }

    // 2. Workspace target in registered workspaces or dynamic URL
    final target = params['workspace'];
    if (target != null && target.trim().isNotEmpty) {
      final cleanedTarget = target.trim().toLowerCase();

      for (final ws in WorkspaceService.workspaces) {
        if (ws.id.toLowerCase() == cleanedTarget ||
            ws.name.toLowerCase() == cleanedTarget) {
          return ws;
        }
      }

      if (target.contains('://') || (target.contains('.') && target.contains('/'))) {
        return WorkspaceService.getOrCreateWorkspaceFromMediaDBRoot(
          target,
          useHttps: useHttps,
        );
      }
    }

    return null;
  }

  static Future<void> _handleUri(
    Uri uri, {
    void Function(Workspace workspace)? onWorkspaceOpened,
    void Function(Map<String, String> parameters)? onParametersReceived,
  }) async {
    logPrint('Handling deep link URI: $uri');
    final params = parseParametersFromUri(uri);
    _lastParameters = params;

    if (params.isNotEmpty && onParametersReceived != null) {
      onParametersReceived(params);
    }

    final workspace = parseWorkspaceFromUri(uri);
    if (workspace != null) {
      logPrint(
        'Deep link resolved workspace: ${workspace.name} (${workspace.id})',
      );
      await WorkspaceService.setActiveWorkspace(workspace);
    }

    // Auto-login support from URL parameters
    final user = params['user'];
    final key = params['entermediakey'];
    final email = params['email'];
    final code = params['templogincode'];

    if (user != null && user.isNotEmpty && key != null && key.isNotEmpty) {
      logPrint('Deep link auto-login with user: $user');
      await AuthService.saveCredentials(user, key);
      await AuthService.loadSessionForActiveWorkspace();
    } else if (email != null &&
        email.isNotEmpty &&
        code != null &&
        code.isNotEmpty) {
      logPrint('Deep link OTP login for email: $email');
      try {
        await AuthService.loginWithOtp(email, code);
      } catch (e) {
        logPrint('Error during deep link OTP login: $e');
      }
    } else if (workspace != null) {
      await AuthService.loadSessionForActiveWorkspace();
    }

    if (workspace != null && onWorkspaceOpened != null) {
      onWorkspaceOpened(workspace);
    }
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

