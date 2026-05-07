import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import 'conversation_screen.dart';
import 'new_conversation_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsStreamProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final blocked = me?.blockedUsers ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: convsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (allConvs) {
          // Hide 1-1 chats where the other participant is blocked.
          final convs = allConvs.where((c) {
            if (c.isGroup) return true;
            return !blocked.contains(c.otherUid(myUid));
          }).toList();
          if (convs.isEmpty) {
            return _EmptyState(
              onNewChat: () => AppNavigator.pushWithNavBar(
                  context, const NewConversationScreen()),
            );
          }
          return ListView.separated(
            itemCount: convs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) => _ConversationTile(
              conv: convs[i],
              myUid: myUid,
              // ← pushWithNavBar: abre COM a bottom nav bar visível
              onTap: () => AppNavigator.pushWithNavBar(
                context,
                ConversationScreen(
                  chatId: convs[i].id,
                  conv: convs[i],
                  myUid: myUid,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => AppNavigator.pushWithNavBar(
            context, const NewConversationScreen()),
        tooltip: 'Nova conversa',
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;
  final VoidCallback onTap;

  const _ConversationTile(
      {required this.conv, required this.myUid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = conv.displayTitle(myUid);
    final photo = conv.isGroup ? null : conv.otherPhoto(myUid);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: photo != null ? NetworkImage(photo) : null,
        backgroundColor:
            conv.isGroup ? cs.tertiaryContainer : cs.primaryContainer,
        child: photo != null
            ? null
            : conv.isGroup
                ? Icon(Icons.group_rounded, color: cs.onTertiaryContainer)
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: cs.onPrimaryContainer),
                  ),
      ),
      title: Row(
        children: [
          if (conv.isGroup) ...[
            Icon(Icons.group_rounded, size: 14, color: cs.tertiary),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      subtitle: Text(
        conv.lastMessage ?? 'Inicie a conversa',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      trailing: conv.lastMessageAt != null
          ? Text(_formatTime(conv.lastMessageAt!),
              style: Theme.of(context).textTheme.bodySmall)
          : null,
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Nenhuma conversa ainda',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Encontre jogadores e inicie um chat!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Nova conversa'),
            ),
          ],
        ),
      ),
    );
  }
}
