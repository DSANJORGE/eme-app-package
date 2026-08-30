import 'package:flutter/material.dart';
import '../utils/error_handler.dart';

import '../services/workspace_service.dart';

class Workspace {
  final String id;
  final String name;
  final String mediaDBRoot;
  final String? _iconAsset;
  final Locale? locale;

  const Workspace({
    required this.id,
    required this.name,
    required this.mediaDBRoot,
    this._iconAsset,
    this.locale = const Locale('en'),
  });

  String? get iconAsset {
    if (_iconAsset != null && _iconAsset.isNotEmpty) {
      return _iconAsset;
    }
    try {
      final uri = Uri.parse(mediaDBRoot);
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/site/find/theme/logo.png';
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Workspace.iconAsset URI parse error',
        customKeys: {'mediaDBRoot': mediaDBRoot},
      );
      return null;
    }
  }

  static final ValueNotifier<Locale> languageNotifier = ValueNotifier<Locale>(
    const Locale('en'),
  );

  static Locale get currentLanguage => languageNotifier.value;

  static set currentLanguage(Locale locale) {
    languageNotifier.value = locale;
  }

  /// Extracts the hostname label from a URL or mediaDBRoot string.
  /// Example: 'https://minsur.genailabs.tech/site/mediadb' -> 'minsur'
  static String extractHostname(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 'workspace';
    try {
      final formattedUrl = trimmed.contains('://')
          ? trimmed
          : 'https://$trimmed';
      final uri = Uri.parse(formattedUrl);
      final host = uri.host.isNotEmpty ? uri.host : trimmed;
      final parts = host.split('.');
      if (parts.isNotEmpty) {
        final first = parts.first.toLowerCase();
        if (first != 'www' && first.isNotEmpty) {
          return first;
        } else if (parts.length > 1) {
          return parts[1].toLowerCase();
        }
      }
      return host.toLowerCase();
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Workspace.extractHostname failed',
        customKeys: {'url': url},
      );
      return 'workspace';
    }
  }

  /// Formats/normalizes a mediaDBRoot URL.
  /// Always adds/upgrades scheme to `https://` by default unless [useHttps] is false (`https=false`).
  static String normalizeMediaDBRoot(String url, {bool useHttps = true}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    String result = trimmed;

    if (!result.contains('://')) {
      result = useHttps ? 'https://$result' : 'http://$result';
    } else if (useHttps && result.startsWith('http://')) {
      result = 'https://${result.substring(7)}';
    } else if (!useHttps && result.startsWith('https://')) {
      result = 'http://${result.substring(8)}';
    }

    return result;
  }

  /// Capitalizes a string (e.g. 'minsur' -> 'Minsur')
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    if (text.length == 1) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Creates a dynamic [Workspace] requiring only [mediaDBRoot].
  /// Defaults scheme to `https://` unless [useHttps] is false.
  /// Checks if a matching workspace already exists in WorkspaceService before creating a new one.
  /// Defaults:
  /// - [id]: lowercase hostname extracted from [mediaDBRoot]
  /// - [name]: capitalized hostname extracted from [mediaDBRoot]
  /// - [iconAsset]: null
  factory Workspace.fromMediaDBRoot(
    String mediaDBRoot, {
    String? id,
    String? name,
    String? iconAsset,
    bool useHttps = true,
  }) {
    final formattedRoot = normalizeMediaDBRoot(mediaDBRoot, useHttps: useHttps);
    final hostname = extractHostname(formattedRoot);
    final derivedId = (id != null && id.trim().isNotEmpty)
        ? id.trim().toLowerCase()
        : hostname.toLowerCase();
    final derivedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : capitalize(hostname);

    // Check if matching workspace already exists in WorkspaceService
    for (final ws in WorkspaceService.workspaces) {
      if (ws.mediaDBRoot.trim().toLowerCase() == formattedRoot.toLowerCase() ||
          ws.id.toLowerCase() == derivedId) {
        return ws;
      }
    }

    return Workspace(
      id: derivedId,
      name: derivedName,
      mediaDBRoot: formattedRoot,
      iconAsset: iconAsset,
    );
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final rawRoot =
        json['mediaDBRoot'] as String? ?? json['mediadbroot'] as String? ?? '';
    final httpsParam =
        json['https']?.toString().toLowerCase() ??
        json['ssl']?.toString().toLowerCase();
    final useHttps = httpsParam != 'false';

    final mediaDBRoot = normalizeMediaDBRoot(rawRoot, useHttps: useHttps);
    final hostname = extractHostname(mediaDBRoot);

    final rawId = json['id'] as String?;
    final id = (rawId != null && rawId.trim().isNotEmpty)
        ? rawId.trim().toLowerCase()
        : hostname.toLowerCase();

    final rawName = json['name'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : capitalize(hostname);

    final iconAsset =
        json['iconAsset'] as String? ?? json['iconasset'] as String?;

    return Workspace(
      id: id,
      name: name,
      mediaDBRoot: mediaDBRoot,
      iconAsset: iconAsset,
    );
  }

  Uri get uri => Uri.parse(mediaDBRoot);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mediadb': mediaDBRoot,
    'siteroot': '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}',
    'https': uri.scheme == 'https',
    if (_iconAsset != null) 'iconAsset': _iconAsset,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workspace &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          mediaDBRoot == other.mediaDBRoot;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ mediaDBRoot.hashCode;
}
