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

O que você ainda precisa fazer (fora do código)
1. SHA-1 para Google Sign-In (obrigatório para login social)

keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
Copie o SHA1: XX:XX:... → Firebase Console → Configurações do projeto → App Android → Adicionar impressão digital → Salvar → baixar novo google-services.json e colocar em android/app/.

2. Índice composto no Firestore (obrigatório para "minha disponibilidade")
O método myAvailability() faz query com dois campos diferentes (userId + expiresAt). Na primeira chamada, o Firestore vai retornar um erro com um link direto para criar o índice. Basta clicar nesse link no console do Android Studio/logcat e criar.

3. Regras de segurança do Firestore
Configure as regras no Firebase Console → Firestore → Regras conforme mostrado na mensagem anterior.

4. iOS / Web (somente se precisar compilar para essas plataformas)

flutterfire configure
Isso gera os valores corretos em firebase_options.dart para iOS e Web. ok

O que você ainda precisa fazer no Firebase
Índices Firestore obrigatórios
Crie no Firebase Console → Firestore → Índices:

Coleção	Campo 1	Campo 2	Tipo
chats	participants (array)	lastMessageAt (desc)	Composto
player_availability	userId (asc)	expiresAt (asc)	Composto
O primeiro erro de runtime vai mostrar um link direto para criar — basta clicar.

Regras Firestore (adicionar as novas coleções)

match /posts/{id} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth != null; // para likes
}
match /chats/{chatId} {
  allow read, write: if request.auth != null
    && request.auth.uid in resource.data.participants;
  allow create: if request.auth != null;
  match /messages/{msgId} {
    allow read, write: if request.auth != null;
  }
}