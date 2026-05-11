import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plataforma não suportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNox_MHUiLbtJKldUC5Wtezw3UfAuOJOM',
    appId: '1:492117491640:android:3a0e63d78f085e34c3594d',
    messagingSenderId: '492117491640',
    projectId: 'skills-arena-c2c71',
    storageBucket: 'skills-arena-c2c71.firebasestorage.app',
  );

  // rode `flutterfire configure` para gerar as opções de iOS e Web
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:492117491640:ios:f524e28eed161514c3594d',
    messagingSenderId: '492117491640',
    projectId: 'skills-arena-c2c71',
    storageBucket: 'skills-arena-c2c71.firebasestorage.app',
    iosBundleId: 'com.r27systems.skillsArena',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:492117491640:web:4e5c92d5980015bec3594d',
    messagingSenderId: '492117491640',
    projectId: 'skills-arena-c2c71',
    storageBucket: 'skills-arena-c2c71.firebasestorage.app',
  );
}
