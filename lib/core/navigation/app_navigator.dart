import 'package:flutter/material.dart';

/// Utilitário de navegação que controla a visibilidade da bottom nav bar.
///
/// [pushWithNavBar]    → push no navigator da aba atual  → barra permanece visível
/// [pushWithoutNavBar] → push no navigator raiz          → barra fica oculta (tela cheia)
class AppNavigator {
  static Future<T?> pushWithNavBar<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Future<T?> pushWithoutNavBar<T>(BuildContext context, Widget screen) {
    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
