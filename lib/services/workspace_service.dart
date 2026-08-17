import 'dart:convert';
import 'package:flutter_eme_base/flutter_eme_base.dart';
import 'package:flutter_eme_base/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace.dart';

class WorkspaceService {
  static final List<Workspace> _workspaces = [];

  static List<Workspace> get workspaces => List.unmodifiable(_workspaces);

  static late Workspace _activeWorkspace;

  static Future<void> init({required Workspace initialWorkspace}) async {
    _workspaces.clear();
    _workspaces.add(initialWorkspace);
    _activeWorkspace = initialWorkspace;

    final prefs = await SharedPreferences.getInstance();

    // Restore dynamic custom workspaces if present
    final customJsonList = prefs.getStringList('custom_dynamic_workspaces');
    if (customJsonList != null && customJsonList.isNotEmpty) {
      for (final rawJson in customJsonList) {
        try {
          final Map<String, dynamic> map = json.decode(rawJson);
          final ws = Workspace.fromJson(map);
          if (ws.mediaDBRoot.isEmpty) {
            logPrint("workspace ${ws.id} has no mediaDBRoot, skip");
            continue;
          }
          if (!_workspaces.any(
            (w) => w.id.toLowerCase() == ws.id.toLowerCase(),
          )) {
            _workspaces.add(ws);
          }
        } catch (_) {}
      }
    }

    final savedId = prefs.getString('selected_workspace_id');
    final savedMediaDBRoot = prefs.getString('selected_workspace_mediadbroot');

    if (savedMediaDBRoot != null && savedMediaDBRoot.isNotEmpty) {
      _activeWorkspace = getOrCreateWorkspaceFromMediaDBRoot(
        savedMediaDBRoot,
        id: savedId,
      );
    } else if (savedId != null && savedId.isNotEmpty) {
      final found = _workspaces.firstWhere(
        (w) =>
            w.id.toLowerCase() == savedId.toLowerCase() ||
            w.name.toLowerCase() == savedId.toLowerCase(),
        orElse: () => _workspaces.first,
      );
      _activeWorkspace = found;
    }
  }

  static void addWorkspaces(List<Workspace> workspaces) {
    if (workspaces.isEmpty) return;
    // final firstWs = workspaces.first;
    for (final workspace in workspaces) {
      logPrint("add workspace ${workspace.id}:${workspace.mediaDBRoot}");

      if (workspace.mediaDBRoot.isEmpty) {
        logPrint("workspace ${workspace.id} has no mediaDBRoot, skip");
        continue;
      }

      if (!_workspaces.any(
        (w) =>
            w.id.toLowerCase() == workspace.id.toLowerCase() ||
            w.mediaDBRoot.toLowerCase() == workspace.mediaDBRoot.toLowerCase(),
      )) {
        _workspaces.add(workspace);
      } else {
        logPrint(
          "workspace ${workspace.id} or ${workspace.mediaDBRoot} is already in the list",
        );
      }
    }
    _saveCustomWorkspaces();
    // if (_activeWorkspace.id != firstWs.id) {
    //   AuthService.switchWorkspace(firstWs, childOfCurrentWorkspace: true);
    // }
  }

  static Workspace get activeWorkspace => _activeWorkspace;

  static String get currentMediaDBRoot => _activeWorkspace.mediaDBRoot;

  /// Retrieves an existing workspace matching [mediaDBRoot] or [id],
  /// or dynamically creates a new Workspace requiring only [mediaDBRoot].
  /// Defaults scheme to `https://` unless [useHttps] is false.
  static Workspace getOrCreateWorkspaceFromMediaDBRoot(
    String mediaDBRoot, {
    String? id,
    String? name,
    String? iconAsset,
    bool useHttps = true,
  }) {
    if (mediaDBRoot.trim().isEmpty) {
      return _activeWorkspace;
    }

    final formattedRoot = Workspace.normalizeMediaDBRoot(
      mediaDBRoot,
      useHttps: useHttps,
    );
    final cleanedRoot = formattedRoot.toLowerCase();
    final targetId = id?.trim().toLowerCase();

    for (final ws in _workspaces) {
      if (targetId != null) {
        if (ws.id.toLowerCase() == targetId) return ws;
      } else if (ws.mediaDBRoot.toLowerCase() == cleanedRoot) {
        return ws;
      }
    }

    final dynamicWs = Workspace.fromMediaDBRoot(
      formattedRoot,
      id: id,
      name: name,
      iconAsset: iconAsset,
      useHttps: useHttps,
    );

    _workspaces.add(dynamicWs);
    _saveCustomWorkspaces();
    return dynamicWs;
  }

  static Future<void> _saveCustomWorkspaces() async {
    final prefs = await SharedPreferences.getInstance();
    final customList = _workspaces
        .map((ws) => json.encode(ws.toJson()))
        .toList();
    await prefs.setStringList('custom_dynamic_workspaces', customList);
  }

  static Future<void> setActiveWorkspace(Workspace workspace) async {
    if (!_workspaces.any(
      (w) => w.id.toLowerCase() == workspace.id.toLowerCase(),
    )) {
      _workspaces.add(workspace);
      await _saveCustomWorkspaces();
    }
    _activeWorkspace = workspace;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_workspace_id', workspace.id);
    await prefs.setString(
      'selected_workspace_mediadbroot',
      workspace.mediaDBRoot,
    );
  }

  static Future<void> setActiveWorkspaceByName(String name) async {
    final lowerName = name.toLowerCase();
    final found = _workspaces.firstWhere(
      (w) =>
          w.name.toLowerCase() == lowerName || w.id.toLowerCase() == lowerName,
      orElse: () => _workspaces.first,
    );
    await setActiveWorkspace(found);
  }

  static Workspace getWorkspaceByName(String name) {
    final lowerName = name.toLowerCase();
    return _workspaces.firstWhere(
      (w) =>
          w.name.toLowerCase() == lowerName || w.id.toLowerCase() == lowerName,
      orElse: () => _workspaces.first,
    );
  }

  /// Checks whether a workspace can be deleted.
  static bool canDeleteWorkspace(Workspace workspace) {
    return _workspaces.length > 1;
  }

  /// Removes a workspace from registered workspaces and cleans up saved credentials.
  static Future<bool> removeWorkspace(Workspace workspace) async {
    final index = _workspaces.indexWhere(
      (w) => w.id.toLowerCase() == workspace.id.toLowerCase(),
    );

    if (index == -1) return false;

    final removed = _workspaces.removeAt(index);
    await _saveCustomWorkspaces();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_${removed.id}');
    await prefs.remove('entermediakey_${removed.id}');

    if (_activeWorkspace.id.toLowerCase() == removed.id.toLowerCase()) {
      if (_workspaces.isNotEmpty) {
        _activeWorkspace = _workspaces.first;
      }
      await prefs.setString('selected_workspace_id', _activeWorkspace.id);
      await prefs.setString(
        'selected_workspace_mediadbroot',
        _activeWorkspace.mediaDBRoot,
      );
    }

    return true;
  }
}
