lib/
├── core/constants/      → app_constants.dart
│        errors/         → app_failure.dart
│        theme/          → app_theme.dart
├── data/models/         → user_model.dart
│        repositories/   → auth_repository.dart
├── services/            → storage_service.dart
├── config/              → firebase_options.dart
└── presentation/
    ├── providers/        → router_provider.dart
    ├── widgets/auth/     → google_sign_in_button.dart
    └── screens/
        ├── auth/         → login_screen.dart
        │                   register_screen.dart
        │                   forgot_password_screen.dart
        ├── shell/        → main_shell.dart
        ├── home/         → home_screen.dart
        ├── explore/      → explore_screen.dart
        ├── chat/         → chat_screen.dart
        └── profile/      → profile_screen.dart


incluir :
Authentication (Email/Senha + Google)
Firestore Database (modo produção)
Storage
Cloud Functions (vamos usar depois para admins)

firebase logout
firebase login


flutter pub global activate flutterfire_cli
C:\Users\TD48\AppData\Local\Pub\Cache\bin\flutterfire configure

