import 'package:firebase_auth/firebase_auth.dart'; /// ______
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM background handler must be registered before runApp.
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // null = segue idioma do sistema. Caso contrário, idioma escolhido
    // pelo user em Perfil → Idioma (persistido em SharedPreferences).
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Skills Arena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        // Se o user não escolheu manual, usa o idioma do device — desde
        // que seja um dos suportados. Caso contrário, cai pra português.
        if (deviceLocale == null) return supported.first;
        for (final s in supported) {
          if (s.languageCode == deviceLocale.languageCode) return s;
        }
        return supported.first;
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user != null) {
          // Register FCM token + foreground handler. Idempotent.
          NotificationService.instance.initialize();
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
