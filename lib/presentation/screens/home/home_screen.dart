import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../providers/post_provider.dart';
import 'create_post_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Skills Arena')),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return _EmptyFeed(
              onPost: () => AppNavigator.pushWithoutNavBar(
                  context, const CreatePostScreen()),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(postsStreamProvider),
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: posts.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (_, i) => _PostCard(
                post: posts[i],
                myUid: myUid,
                onLike: () =>
                    ref.read(postRepositoryProvider).toggleLike(posts[i].id, myUid),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            AppNavigator.pushWithoutNavBar(context, const CreatePostScreen()),
        tooltip: 'Nova publicação',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final PostModel post;
  final String myUid;
  final VoidCallback onLike;

  const _PostCard(
      {required this.post, required this.myUid, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLiked = post.isLikedBy(myUid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(_formatTime(post.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              _PostTypeBadge(type: post.type),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          _PostContent(post: post),
          // Caption
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.caption!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          // Footer — likes
          InkWell(
            onTap: onLike,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isLiked ? Colors.red : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLiked ? Colors.red : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      onTap: () => _launch(post.content),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (thumbnail != null)
              Image.network(
                thumbnail,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _NoThumbnail(cs: cs),
              )
            else
              _NoThumbnail(cs: cs),
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 36),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('YouTube',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
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

class _NoThumbnail extends StatelessWidget {
  final ColorScheme cs;
  const _NoThumbnail({required this.cs});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 200,
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.smart_display_rounded,
            size: 48, color: cs.onSurfaceVariant),
      );
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
              child: Text(
                url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.primary),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 16, color: cs.primary),
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

// ─── Badges / empty ──────────────────────────────────────────────────────────

class _PostTypeBadge extends StatelessWidget {
  final PostType type;
  const _PostTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    IconData icon;
    Color color;
    switch (type) {
      case PostType.text:
        icon = Icons.text_fields_rounded;
        color = cs.secondary;
        break;
      case PostType.youtube:
        icon = Icons.smart_display_rounded;
        color = Colors.red;
        break;
      case PostType.link:
        icon = Icons.link_rounded;
        color = cs.primary;
        break;
    }
    return Icon(icon, size: 18, color: color);
  }
}

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onPost;
  const _EmptyFeed({required this.onPost});

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
            Icon(Icons.dynamic_feed_rounded, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Nenhuma publicação ainda',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Seja o primeiro a publicar!',
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
