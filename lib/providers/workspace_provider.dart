import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace.dart';
import '../services/workspace_service.dart';

class WorkspaceNotifier extends StateNotifier<Workspace> {
  WorkspaceNotifier() : super(WorkspaceService.activeWorkspace);

  void setWorkspace(Workspace workspace) {
    state = workspace;
  }

  void refresh() {
    state = WorkspaceService.activeWorkspace;
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, Workspace>((ref) {
  return WorkspaceNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(Workspace.currentLanguage);

  void setLocale(Locale? locale) {
    if (locale != null) {
      Workspace.currentLanguage = locale;
    }
    state = locale;
  }
}


final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});
