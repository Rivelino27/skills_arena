import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<UserModel?>>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController() : super(const AsyncValue.data(null));

  final AuthService _authService = AuthService();

  Future<void> loginWithEmail(String email, String password, BuildContext context) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(email, password);
      state = AsyncValue.data(user);
      if (user != null && context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
      if (user != null && context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no Google: ${e.toString()}')),
      );
    }
  }
}