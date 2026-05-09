# Skills Arena — Configurações Fora do Código

Este arquivo documenta tudo que precisa ser feito **além do código** para o app funcionar corretamente.

---

## 1. Firebase — Projeto

1. Acesse [console.firebase.google.com](https://console.firebase.google.com) e crie (ou abra) o projeto **skills-arena**.
2. Adicione os aplicativos Android e iOS ao projeto.
3. Execute o FlutterFire CLI para gerar `lib/firebase_options.dart`:

```bash
# Instale o CLI (somente uma vez)
dart pub global activate flutterfire_cli

# Na raiz do projeto C:\Users\TD48\AppData\Local\Pub\Cache\bin\flutterfire configure
flutterfire configure
```

---

## 2. Android — SHA-1 para Google Sign-In

O Google Sign-In exige que os SHA-1 do keystore estejam cadastrados no Firebase.

### Debug (desenvolvimento)
```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copie o valor **SHA1** e cadastre em:
Firebase Console → Projeto → Configurações (⚙) → Seus apps → Android → Adicionar impressão digital.

### Release (produção)
```bash
keytool -list -v -keystore caminho/para/seu.keystore -alias seu_alias
```
Cadastre o SHA-1 do release keystore também.

> Após cadastrar os SHA-1, baixe o `google-services.json` atualizado e substitua em `android/app/`.

---

## 3. Google Sign-In — android/app/build.gradle

Certifique-se de que o `applicationId` em `android/app/build.gradle` coincide exatamente com o pacote cadastrado no Firebase Console:

```gradle
defaultConfig {
    applicationId "com.r27systems.skills_arena"
    ...
}
```

---

## 4. Firestore — Regras de segurança

No Firebase Console → Firestore → Regras, use:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuários: leitura pública (busca), escrita somente pelo próprio
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;
    }

    // Posts: leitura pública, criação autenticada, edição somente pelo autor
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.userId;

      // Comentários: qualquer usuário autenticado pode ler/criar
      match /comments/{commentId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }

    // Locais esportivos
    match /sports_venues/{venueId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;
    }

    // Disponibilidade de jogadores
    match /player_availability/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == resource.data.userId;
    }

    // Chats: somente participantes podem ler/escrever
    match /chats/{chatId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.participants;

      match /messages/{msgId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      }
    }
  }
}
```

---

## 5. Firestore — Índices compostos

Acesse Firebase Console → Firestore → Índices → Adicionar índice.

| Coleção           | Campo 1        | Ordem | Campo 2     | Ordem      | Escopo    |
|-------------------|----------------|-------|-------------|------------|-----------|
| `posts`           | `venueId`      | ASC   | `createdAt` | DESC       | Coleção   |
| `posts`           | `userId`       | ASC   | `createdAt` | DESC       | Coleção   |
| `sports_venues`   | `sport`        | ASC   | `createdAt` | DESC       | Coleção   |
| `player_availability` | `sport`   | ASC   | `createdAt` | DESC       | Coleção   |

> Os índices de campo único (ex.: `posts` ordenado só por `createdAt`) são criados automaticamente pelo Firestore.
> O índice de `chats/messages` por `createdAt` também é criado automaticamente (query simples).

---

## 6. Android — Permissões (AndroidManifest.xml)

Em `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 7. Android — minSdkVersion

Em `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21   // mínimo para Firebase Auth + Google Sign-In
    ...
}
```

---

## 8. iOS — Info.plist

Em `ios/Runner/Info.plist`, adicione as chaves de localização:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>O Skills Arena usa sua localização para mostrar quadras próximas.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>O Skills Arena usa sua localização para mostrar quadras próximas.</string>
```

Para Google Sign-In no iOS, adicione o `REVERSED_CLIENT_ID` do `GoogleService-Info.plist` como URL scheme em `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.SEU_CLIENT_ID_AQUI</string>
    </array>
  </dict>
</array>
```

---

## 9. Dependências — Instalação

```bash
flutter pub get
```

Pacotes principais utilizados:
- `firebase_core`, `firebase_auth`, `cloud_firestore` — Firebase
- `google_sign_in` — Login com Google
- `flutter_riverpod` — Gerenciamento de estado
- `go_router` — Navegação declarativa
- `persistent_bottom_nav_bar_v2` — Bottom nav bar persistente
- `flutter_map` + `latlong2` — Mapa OpenStreetMap
- `geolocator ^12.0.0` — GPS (^13 é incompatível com firebase_auth ^4)
- `url_launcher` — Abrir links YouTube/TikTok
- `share_plus` — Compartilhar posts para outros apps
- `dartz` — Either para tratamento de erros

---

## 10. OpenStreetMap — Política de uso

O `flutter_map` usa tiles do OpenStreetMap. Para produção:
- Mantenha o `userAgentPackageName` correto no `TileLayer` (já configurado: `com.r27systems.skills_arena`).
- Para apps com muitos usuários, considere um servidor de tiles próprio ou serviço pago (Mapbox, Stadia Maps).

---

## 11. Verificação rápida

```bash
# Verificar se tudo compila
flutter build apk --debug

# Rodar no dispositivo
flutter run
```
