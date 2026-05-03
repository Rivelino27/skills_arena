import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_theme.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 100, color: Color(0xFF00FF88)),
            const Text("QuadraFinder", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "E-mail", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Senha", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(authControllerProvider.notifier).loginWithEmail(
                    emailController.text,
                    passwordController.text,
                    context,
                  ),
              child: const Text("Entrar"),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata),
              label: const Text("Entrar com Google"),
              onPressed: () => ref.read(authControllerProvider.notifier).loginWithGoogle(context),
            ),

            TextButton(
              onPressed: () {}, // TODO: tela de cadastro
              child: const Text("Não tem conta? Cadastre-se"),
            ),
          ],
        ),
      ),
    );
  }
}