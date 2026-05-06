import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/chat_provider.dart';
import 'conversation_screen.dart';

class NewConversationScreen extends ConsumerWidget {
  const NewConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Conversa')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) => _UserTile(
              user: users[i],
              onTap: () => _startChat(context, ref, users[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startChat(
      BuildContext context, WidgetRef ref, UserModel user) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final conv = await ref.read(chatRepositoryProvider).getOrCreateConversation(
          otherUid: user.id,
          otherName: user.name ?? 'Usuário',
          otherPhoto: user.photoUrl,
        );

    if (!context.mounted) return;

    AppNavigator.pushWithNavBar(
      context,
      ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = user.name ?? 'Usuário';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        backgroundColor: cs.primaryContainer,
        child: user.photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: cs.onPrimaryContainer),
              )
            : null,
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(user.email,
          style: TextStyle(color: cs.onSurfaceVariant)),
      trailing: Icon(Icons.chat_bubble_outline_rounded, color: cs.primary),
      onTap: onTap,
    );
  }
}
