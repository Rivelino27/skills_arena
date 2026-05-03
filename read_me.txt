lib/
├── core/
│   ├── config/
│   │   ├── firebase_options.dart          # gerado pelo Firebase CLI
│   │   ├── app_theme.dart                 # tema escuro
│   │   └── constants.dart
│   ├── utils/
│   │   ├── helpers.dart
│   │   └── geo_helper.dart
│   └── widgets/
│       └── custom_button.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── controllers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── home/
│   ├── map/
│   ├── chat/
│   └── profile/
│
├── models/                  # todos os models (UserModel, CourtModel, etc.)
├── services/                # Firebase services
├── providers/               # Riverpod providers
├── routes/
└── main.dart
incluir :
Authentication (Email/Senha + Google)
Firestore Database (modo produção)
Storage
Cloud Functions (vamos usar depois para admins)

firebase logout
firebase login


flutter pub global activate flutterfire_cli
C:\Users\TD48\AppData\Local\Pub\Cache\bin\flutterfire configure

