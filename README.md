# skills_arena

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

6. Como tornar um user Premium manualmente
Pelo console do Firebase:

Acesse Firebase Console → Firestore Database
Coleção users → procure o doc pelo UID do usuário
Edite o campo isPremium (boolean) → marque como true. Se o campo não existir, clique em "Adicionar campo" → name: isPremium, type: boolean, value: true
Salvar. O app vai pegar a mudança automaticamente via currentUserProvider (stream).
Para admin: mesma coisa, campo isAdmin: true. O ProfileScreen._PremiumBadge e a paywall do TeamsHubScreen leem isPremium. O selo de "verificada" em quadras tem fluxo separado em _AdminVerifyToggle (só admin pode mexer).
