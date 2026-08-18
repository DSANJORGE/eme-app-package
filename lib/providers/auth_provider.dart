import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/workspace.dart';
import '../services/auth_service.dart';

import '../utils/error_handler.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final User? currentUser;

  const AuthState({required this.isLoggedIn, this.userId, this.currentUser});

  String get displayName => currentUser?.displayName ?? '';
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
    : super(
        AuthState(
          isLoggedIn: AuthService.isLoggedIn,
          userId: AuthService.userId,
          currentUser: AuthService.currentUser,
        ),
      );

  void refresh() {
    state = AuthState(
      isLoggedIn: AuthService.isLoggedIn,
      userId: AuthService.userId,
      currentUser: AuthService.currentUser,
    );
  }

  Future<bool> loginWithOtp(String accountOrEmail, String code) async {
    try {
      final success = await AuthService.loginWithOtp(accountOrEmail, code);
      refresh();
      return success;
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'AuthNotifier.loginWithOtp failed',
        customKeys: {'accountOrEmail': accountOrEmail},
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      refresh();
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'AuthNotifier.logout failed',
      );
      rethrow;
    }
  }

  Future<bool> switchWorkspace(Workspace workspace) async {
    try {
      final success = await AuthService.switchWorkspace(workspace);
      refresh();
      return success;
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'AuthNotifier.switchWorkspace failed',
        customKeys: {'workspace': workspace.id},
      );
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
