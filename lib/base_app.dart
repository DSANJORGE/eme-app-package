import 'package:flutter/material.dart';
import 'package:flutter_eme_base/models/workspace.dart';
import 'package:flutter_eme_base/services/auth_service.dart';
import 'package:flutter_eme_base/services/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openinsitute_core/openinsitute_core.dart';

import 'app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/workspace_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/deep_link_service.dart';

import 'utils/error_handler.dart';

class BaseApp extends ConsumerWidget {
  final AppConfig config;

  const BaseApp({super.key, required this.config});

  static Future<void> initialize({required Workspace initialWorkspace}) async {
    try {
      await WorkspaceService.init(initialWorkspace: initialWorkspace);
      await AuthService.init();
      final oi = OpenI();
      await oi.initialize(workspaceData: initialWorkspace.toJson());
    } catch (e, stack) {
      AppErrorHandler.recordFatal(
        e,
        stack,
        reason: 'Critical failure during BaseApp.initialize',
        customKeys: {'workspace': initialWorkspace.id},
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: config.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: config.darkTheme,
      theme: config.lightTheme,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  @override
  void initState() {
    super.initState();

    DeepLinkService.init(
      onWorkspaceOpened: (workspace) {
        if (mounted) {
          ref.read(authProvider.notifier).refresh();
          ref.read(workspaceProvider.notifier).refresh();
        }
      },
      onParametersReceived: (parameters) {
        if (mounted) {
          ref.read(authProvider.notifier).refresh();
          ref.read(workspaceProvider.notifier).refresh();
        }
      },
    );
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  void _handleLogin(String email) {
    ref.read(authProvider.notifier).refresh();
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
  }

  void _handleWorkspaceChanged() {
    ref.read(authProvider.notifier).refresh();
    ref.read(workspaceProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoggedIn) {
      return SelectionArea(
        child: DashboardScreen(
          fullName: authState.displayName,
          onLogout: _handleLogout,
          onWorkspaceChanged: _handleWorkspaceChanged,
        ),
      );
    } else {
      return SelectionArea(
        child: LoginScreen(
          onLoginSuccess: _handleLogin,
          onWorkspaceChanged: _handleWorkspaceChanged,
        ),
      );
    }
  }
}
