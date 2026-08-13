import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/workspace.dart';
import '../services/auth_service.dart';

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
    final success = await AuthService.loginWithOtp(accountOrEmail, code);
    refresh();
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    refresh();
  }

  Future<bool> switchWorkspace(Workspace workspace) async {
    final success = await AuthService.switchWorkspace(workspace);
    refresh();
    return success;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
