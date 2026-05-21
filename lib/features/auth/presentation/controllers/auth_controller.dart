import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/app_user.dart';

class AuthState {
  const AuthState({
    required this.isBooting,
    required this.isSubmitting,
    this.user,
    this.error,
  });

  const AuthState.booting()
    : isBooting = true,
      isSubmitting = false,
      user = null,
      error = null;

  final bool isBooting;
  final bool isSubmitting;
  final AppUser? user;
  final String? error;

  AuthState copyWith({
    bool? isBooting,
    bool? isSubmitting,
    AppUser? user,
    bool clearUser = false,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isBooting: isBooting ?? this.isBooting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState.booting();
  }

  Future<void> restore() async {
    final user = await ref.read(restoreSessionUseCaseProvider)();
    state = AuthState(isBooting: false, isSubmitting: false, user: user);
    if (user != null) {
      await ref.read(fcmRegistrationServiceProvider).registerTokenIfAvailable();
    }
  }

  Future<void> login(String nikNip, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final session = await ref.read(loginUseCaseProvider)(nikNip, password);
      state = AuthState(
        isBooting: false,
        isSubmitting: false,
        user: session.user,
      );
      await ref.read(fcmRegistrationServiceProvider).registerTokenIfAvailable();
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: _errorText(error),
        clearUser: true,
      );
    }
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)();
    state = const AuthState(isBooting: false, isSubmitting: false);
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    return 'Koneksi ke server belum berhasil. Coba lagi sebentar.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
