import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/social_repository.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../chat/conversation_screen.dart';

final _userByIdProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_userByIdProvider(userId));
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMe = userId == myUid;

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuário não encontrado.')),
          );
        }
        return _ProfileBody(user: user, myUid: myUid, isMe: isMe, ref: ref);
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserModel user;
  final String myUid;
  final bool isMe;
  final WidgetRef ref;

  const _ProfileBody({
    required this.user,
    required this.myUid,
    required this.isMe,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsStreamProvider(user.id));
    final me = ref.watch(currentUserProvider).valueOrNull;
    final iBlocked = me?.hasBlocked(user.id) ?? false;
    final theyBlockedMe = user.hasBlocked(myUid);
    final isBlocked = iBlocked || theyBlockedMe;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = user.name ?? 'Usuário';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              if (!isMe)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (v) async {
                    if (v == 'block') {
                      await _confirmBlock(context, ref);
                    } else if (v == 'unblock') {
                      await ref
                          .read(socialRepositoryProvider)
                          .unblockUser(user.id);
                    }
                  },
                  itemBuilder: (_) => [
                    if (iBlocked)
                      const PopupMenuItem(
                        value: 'unblock',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.lock_open_rounded),
                          title: Text('Desbloquear'),
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'block',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.block_rounded, color: Colors.red),
                          title: Text('Bloquear',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primaryContainer, cs.secondaryContainer],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        backgroundColor: cs.primary,
                        child: user.photoUrl == null
                            ? Text(initial,
                                style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      if (user.username != null) ...[
                        const SizedBox(height: 6),
                        Text('@${user.username}',
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBlocked)
              Container(
                width: double.infinity,
                color: cs.errorContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        iBlocked
                            ? 'Você bloqueou este usuário.'
                            : 'Este usuário te bloqueou.',
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            if (!isMe)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: FilledButton.icon(
                  onPressed:
                      isBlocked ? null : () => _openChat(context, ref),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar mensagem'),
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Publicações',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: postsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (posts) {
                  if (posts.isEmpty) {
                    return Center(
                      child: Text('Nenhuma publicação ainda.',
                          style:
                              TextStyle(color: cs.onSurfaceVariant)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (_, i) =>
                        _MiniPostTile(post: posts[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    try {
      final conv =
          await ref.read(chatRepositoryProvider).getOrCreateConversation(
                otherUid: user.id,
                otherName: user.name ?? 'Usuário',
                otherPhoto: user.photoUrl,
              );
      if (!context.mounted) return;
      AppNavigator.pushWithNavBar(
        context,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _confirmBlock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquear usuário?'),
        content: Text(
          '${user.name ?? 'Este usuário'} não poderá te enviar mensagens '
          'e vocês não aparecerão um para o outro nas listas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Bloquear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(socialRepositoryProvider).blockUser(user.id);
  }
}

class _MiniPostTile extends StatelessWidget {
  final PostModel post;
  const _MiniPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diff = DateTime.now().difference(post.createdAt);
    final time = diff.inHours < 1
        ? '${diff.inMinutes}m'
        : diff.inDays < 1
            ? '${diff.inHours}h'
            : '${diff.inDays}d';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _typeIcon(post.type, cs),
      title: Text(
        post.type == PostType.text
            ? post.content
            : (post.caption ?? post.content),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(time,
          style:
              TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    );
  }

  Widget _typeIcon(PostType type, ColorScheme cs) {
    switch (type) {
      case PostType.text:
        return Icon(Icons.text_fields_rounded, color: cs.secondary);
      case PostType.youtube:
        return const Icon(Icons.smart_display_rounded,
            color: Colors.red);
      case PostType.tiktok:
        return const Icon(Icons.music_video_rounded,
            color: Colors.pink);
      case PostType.link:
        return Icon(Icons.link_rounded, color: cs.primary);
    }
  }
}
