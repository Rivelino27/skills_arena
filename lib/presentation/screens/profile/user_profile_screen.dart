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
import '../../providers/team_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/fifa_card_widget.dart';
import '../../widgets/playstyle_vote_sheet.dart';
import '../../widgets/user_badge.dart';
import '../chat/conversation_screen.dart';
import '../teams/team_detail_screen.dart';

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
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  UserBadge(user: user, size: 14),
                ],
              ),
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
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.group_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${user.followersCount} seguidor${user.followersCount == 1 ? '' : 'es'}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!isMe)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _FollowButton(
                        targetUid: user.id,
                        following: me?.isFollowing(user.id) ?? false,
                        disabled: isBlocked,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            isBlocked ? null : () => _openChat(context, ref),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Mensagem'),
                      ),
                    ),
                  ],
                ),
              ),
            if (user.isPremium) ...[
              const SizedBox(height: 8),
              Center(
                child: Consumer(
                  builder: (_, ref, __) {
                    final votes =
                        ref.watch(playstyleVotesProvider(user.id));
                    final active = votes.valueOrNull?.activeKeys;
                    return FifaCardWidget(
                      user: user,
                      scale: 0.75,
                      activePlaystyles: active,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (!isMe)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      builder: (_) => PlaystyleVoteSheet(
                        targetUid: user.id,
                        targetName: user.name ?? 'Jogador',
                      ),
                    ),
                    icon: const Icon(Icons.how_to_vote_rounded),
                    label:
                        const Text('Votar nas playstyles deste jogador'),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            _UserInfoCard(user: user),
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

/// Resumo do usuário mostrado em todo perfil aberto pelo chat:
/// e-mail, times que ele participa e posição no ranking geral
/// (calculada a partir do `topUsersByFollowersProvider`).
class _UserInfoCard extends ConsumerWidget {
  final UserModel user;
  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final teamsAsync = ref.watch(userTeamsProvider(user.id));
    final rankingAsync = ref.watch(topUsersByFollowersProvider);

    // Posição no ranking (index + 1) ou null se não está nos top.
    int? rankingPosition;
    final ranking = rankingAsync.valueOrNull;
    if (ranking != null) {
      final i = ranking.indexWhere((u) => u.id == user.id);
      if (i >= 0) rankingPosition = i + 1;
    }

    final showEmail = user.searchableByEmail && user.email.isNotEmpty;
    final teams = teamsAsync.valueOrNull ?? const [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showEmail) ...[
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value: user.email,
                ),
                const SizedBox(height: 6),
              ],
              _InfoRow(
                icon: Icons.leaderboard_rounded,
                label: 'Ranking geral',
                value: rankingAsync.isLoading
                    ? 'Carregando…'
                    : rankingPosition != null
                        ? '#$rankingPosition  ·  ${user.followersCount} seguidores'
                        : 'Fora do top 100',
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 84,
                    child: Text('Times',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: teamsAsync.when(
                      loading: () => Text('Carregando…',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                      error: (_, __) => Text('—',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                      data: (_) => teams.isEmpty
                          ? Text('Sem time',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant))
                          : Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: teams
                                  .map((t) => ActionChip(
                                        avatar: const Icon(
                                            Icons.shield_rounded,
                                            size: 14),
                                        label: Text(t.name,
                                            style: const TextStyle(
                                                fontSize: 12)),
                                        visualDensity:
                                            VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                        onPressed: () => AppNavigator
                                            .pushWithNavBar(
                                          context,
                                          TeamDetailScreen(
                                              teamId: t.id),
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        SizedBox(
          width: 84,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final String targetUid;
  final bool following;
  final bool disabled;

  const _FollowButton({
    required this.targetUid,
    required this.following,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPressed = disabled
        ? null
        : () => ref.read(socialRepositoryProvider).toggleFollow(targetUid);
    if (following) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Seguindo'),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add_alt_rounded),
      label: const Text('Seguir'),
    );
  }
}
