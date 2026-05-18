import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../providers/post_provider.dart';
import '../chat/conversation_screen.dart';
import '../profile/user_profile_screen.dart';
import 'create_post_screen.dart';
import 'in_app_video_screen.dart';
import 'shorts_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills Arena'),
        actions: [
          IconButton(
            tooltip: 'Modo Shorts',
            icon: const Icon(Icons.smart_display_rounded),
            onPressed: () => AppNavigator.pushWithNavBar(
                context, const ShortsScreen()),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.public_rounded), text: 'Global'),
            Tab(icon: Icon(Icons.group_rounded), text: 'Seguindo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _Feed(
            asyncPosts: ref.watch(postsStreamProvider),
            myUid: myUid,
            emptyMessage: 'Nenhuma publicação ainda',
            emptyHint: 'Seja o primeiro a publicar!',
            onRefresh: () => ref.invalidate(postsStreamProvider),
          ),
          _Feed(
            asyncPosts: ref.watch(followingPostsStreamProvider),
            myUid: myUid,
            emptyMessage: 'Você ainda não segue ninguém',
            emptyHint:
                'Siga jogadores para ver as publicações deles aqui.',
            onRefresh: () => ref.invalidate(followingPostsStreamProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () =>
            AppNavigator.pushWithNavBar(context, const CreatePostScreen()),
        tooltip: 'Nova publicação',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

}

/// Shared list body for both feed tabs (Global / Seguindo). Stateless
/// rendering of an [AsyncValue] of posts plus the empty-state copy.
class _Feed extends ConsumerWidget {
  final AsyncValue<List<PostModel>> asyncPosts;
  final String myUid;
  final String emptyMessage;
  final String emptyHint;
  final VoidCallback onRefresh;

  const _Feed({
    required this.asyncPosts,
    required this.myUid,
    required this.emptyMessage,
    required this.emptyHint,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncPosts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyFeed(
            message: emptyMessage,
            hint: emptyHint,
            onPost: () => AppNavigator.pushWithNavBar(
                context, const CreatePostScreen()),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: posts.length,
            itemBuilder: (_, i) => _PostCard(
              post: posts[i],
              myUid: myUid,
              onLike: () => ref
                  .read(postRepositoryProvider)
                  .toggleLike(posts[i].id, myUid),
              onShare: () =>
                  ref.read(postRepositoryProvider).sharePost(posts[i]),
              onViewProfile: () => AppNavigator.pushWithNavBar(
                context,
                UserProfileScreen(userId: posts[i].userId),
              ),
              onMessage: () => _openChatWithAuthor(context, ref, posts[i]),
              onDelete: () => _confirmDeletePost(context, ref, posts[i].id),
            ),
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog then deletes the post. Firestore rules
  /// already enforce that only the author can delete.
  Future<void> _confirmDeletePost(
      BuildContext context, WidgetRef ref, String postId) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar publicação?'),
        content: const Text(
            'Esta ação não pode ser desfeita. Comentários e curtidas serão removidos junto.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res =
        await ref.read(postRepositoryProvider).deletePost(postId);
    res.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Publicação apagada.')),
      ),
    );
  }

  /// Opens a 1-1 chat with the post's author. Creates the conversation
  /// if needed. Self-posts (myUid == post.userId) just go to the user's
  /// own profile to avoid creating a chat-with-self.
  Future<void> _openChatWithAuthor(
      BuildContext context, WidgetRef ref, PostModel post) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (post.userId == myUid) {
      AppNavigator.pushWithNavBar(
          context, UserProfileScreen(userId: post.userId));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conv =
          await ref.read(chatRepositoryProvider).getOrCreateConversation(
                otherUid: post.userId,
                otherName: post.userName,
                otherPhoto: post.userPhotoUrl,
              );
      if (!context.mounted) return;
      AppNavigator.pushWithNavBar(
        context,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Erro ao abrir chat: $e')));
    }
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final PostModel post;
  final String myUid;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onViewProfile;
  final VoidCallback onMessage;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.myUid,
    required this.onLike,
    required this.onShare,
    required this.onViewProfile,
    required this.onMessage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLiked = post.isLikedBy(myUid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — toca no avatar/nome para ver perfil
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onViewProfile,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userPhotoUrl != null
                      ? NetworkImage(post.userPhotoUrl!)
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: post.userPhotoUrl == null
                      ? Text(
                          post.userName.isNotEmpty
                              ? post.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: cs.onPrimaryContainer),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600)),
                      Text(_formatTime(post.createdAt),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                _PostTypeBadge(type: post.type),
                if (post.userId == myUid)
                  PopupMenuButton<String>(
                    tooltip: 'Mais opções',
                    icon: Icon(Icons.more_vert_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                          title: Text('Apagar publicação'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PostContent(post: post),
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.caption!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 10),
          // Footer — curtir / comentar / compartilhar
          Row(
            children: [
              _ActionButton(
                icon: isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.likesCount}',
                color: isLiked ? Colors.red : cs.onSurfaceVariant,
                onTap: onLike,
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.commentsCount}',
                color: cs.onSurfaceVariant,
                onTap: () => _showComments(context, post),
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Compartilhar',
                color: cs.onSurfaceVariant,
                onTap: onShare,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.send_rounded,
                label: 'Mensagem',
                color: cs.primary,
                onTap: onMessage,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showComments(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CommentsSheet(post: post, myUid: myUid),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}m atrás';
    if (diff.inDays < 1) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ─── Post Content ─────────────────────────────────────────────────────────────

class _PostContent extends StatelessWidget {
  final PostModel post;
  const _PostContent({required this.post});

  @override
  Widget build(BuildContext context) {
    switch (post.type) {
      case PostType.text:
        return Text(post.content,
            style: Theme.of(context).textTheme.bodyLarge);
      case PostType.youtube:
        return _YouTubeCard(post: post);
      case PostType.tiktok:
        return _TikTokCard(post: post);
      case PostType.link:
        return _LinkCard(url: post.content);
    }
  }
}

class _YouTubeCard extends StatelessWidget {
  final PostModel post;
  const _YouTubeCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final thumbnail = post.youtubeThumbnailUrl;

    return InkWell(
      onTap: () => AppNavigator.pushWithNavBar(
          context, InAppVideoScreen(post: post)),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (thumbnail != null)
              Image.network(thumbnail,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _MediaPlaceholder(cs: cs, icon: Icons.smart_display_rounded))
            else
              _MediaPlaceholder(cs: cs, icon: Icons.smart_display_rounded),
            const Positioned.fill(
              child: Center(
                child: _PlayButton(),
              ),
            ),
            const Positioned(
              bottom: 8,
              left: 8,
              child: _Badge(text: 'YouTube', color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _TikTokCard extends StatelessWidget {
  final PostModel post;
  const _TikTokCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AppNavigator.pushWithNavBar(
          context, InAppVideoScreen(post: post)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: Center(child: _PlayButton())),
            const Positioned(
              bottom: 8,
              left: 8,
              child: _Badge(text: '🎵 TikTok', color: Colors.black),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Icon(Icons.play_circle_filled_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final String url;
  const _LinkCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _launch(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.link_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13, color: cs.primary)),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─── Helpers visuais ──────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
            color: Colors.black54, shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow_rounded,
            color: Colors.white, size: 36),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      );
}

class _MediaPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  const _MediaPlaceholder({required this.cs, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 200,
        color: cs.surfaceContainerHighest,
        child: Icon(icon, size: 48, color: cs.onSurfaceVariant),
      );
}

class _PostTypeBadge extends StatelessWidget {
  final PostType type;
  const _PostTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case PostType.text:
        return Icon(Icons.text_fields_rounded, size: 18, color: cs.secondary);
      case PostType.youtube:
        return const Icon(Icons.smart_display_rounded,
            size: 18, color: Colors.red);
      case PostType.tiktok:
        return const Icon(Icons.music_video_rounded,
            size: 18, color: Colors.pink);
      case PostType.link:
        return Icon(Icons.link_rounded, size: 18, color: cs.primary);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      );
}

// ─── Comments Sheet ───────────────────────────────────────────────────────────

class _CommentsSheet extends ConsumerStatefulWidget {
  final PostModel post;
  final String myUid;
  const _CommentsSheet({required this.post, required this.myUid});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _inputFocus = FocusNode();
  bool _sending = false;
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _ctrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _ctrl.clear();
    final replyTo = _replyingTo;
    setState(() => _replyingTo = null);
    await ref.read(postRepositoryProvider).addComment(
          postId: widget.post.id,
          text: text,
          replyToId: replyTo?.id,
          replyToName: replyTo?.userName,
        );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final commentsAsync =
        ref.watch(commentsStreamProvider(widget.post.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Comentários',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // List
          Expanded(
            child: commentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text('Sem comentários ainda.',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentTile(
                    comment: comments[i],
                    postId: widget.post.id,
                    myUid: widget.myUid,
                    onReply: () {
                      setState(() => _replyingTo = comments[i]);
                      _inputFocus.requestFocus();
                    },
                  ),
                );
              },
            ),
          ),
          // Input
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    color: cs.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Respondendo a ${_replyingTo!.userName}',
                            style: TextStyle(
                                fontSize: 12, color: cs.primary),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _replyingTo = null),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
              Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: cs.outlineVariant, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _inputFocus,
                      decoration: InputDecoration(
                        hintText: 'Escreva um comentário...',
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  final CommentModel comment;
  final String postId;
  final String myUid;
  final VoidCallback? onReply;

  const _CommentTile({
    required this.comment,
    required this.postId,
    required this.myUid,
    this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final diff = DateTime.now().difference(comment.createdAt);
    final time = diff.inHours < 1
        ? '${diff.inMinutes}m'
        : diff.inDays < 1
            ? '${diff.inHours}h'
            : '${diff.inDays}d';
    final isMe = comment.userId == myUid;

    return Padding(
      padding: EdgeInsets.only(
          top: 6, bottom: 6, left: comment.isReply ? 32 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comment.isReply)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 6),
              child: Icon(Icons.subdirectory_arrow_right_rounded,
                  size: 14, color: cs.onSurfaceVariant),
            ),
          CircleAvatar(
            radius: comment.isReply ? 13 : 16,
            backgroundImage: comment.userPhotoUrl != null
                ? NetworkImage(comment.userPhotoUrl!)
                : null,
            backgroundColor: cs.primaryContainer,
            child: comment.userPhotoUrl == null
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize: comment.isReply ? 10 : 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: comment.isReply ? 12 : 13)),
                    const SizedBox(width: 6),
                    Text(time,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                    children: [
                      if (comment.replyToName != null)
                        TextSpan(
                          text: '@${comment.replyToName} ',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onReply,
                  child: Text(
                    'Responder',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              tooltip: 'Apagar comentário',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(postRepositoryProvider)
                    .deleteComment(postId: postId, commentId: comment.id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Comentário apagado.')),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── Empty / providers aux ────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final String message;
  final String hint;
  final VoidCallback onPost;
  const _EmptyFeed({
    required this.message,
    required this.hint,
    required this.onPost,
  });

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
            Icon(Icons.dynamic_feed_rounded,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPost,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova publicação'),
            ),
          ],
        ),
      ),
    );
  }
}
