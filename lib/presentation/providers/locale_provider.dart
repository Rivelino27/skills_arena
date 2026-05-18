import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locales suportadas pelo app. A primeira da lista é o fallback final
/// (se o sistema vier com um idioma fora dos suportados).
const supportedLocales = <Locale>[
  Locale('pt'),
  Locale('en'),
  Locale('es'),
  Locale('zh'),
  Locale('fr'),
];

/// `null` = seguir idioma do sistema. Caso contrário, idioma escolhido
/// manualmente pelo usuário e persistido em SharedPreferences.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  static const _key = 'app_locale';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
      }
    } catch (_) {/* mantém system default */}
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, locale.languageCode);
      }
    } catch (_) {/* state já está, persistência é best-effort */}
  }
}
