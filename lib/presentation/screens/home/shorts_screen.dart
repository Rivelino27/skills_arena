import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../providers/post_provider.dart';

/// TikTok-style vertical pager over posts that contain a video link
/// (YouTube or TikTok). Other post types are filtered out for a more
/// focused experience. Tap the card to open the actual video in the
/// external app; swipe up/down to navigate.
class ShortsScreen extends ConsumerWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Shorts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: postsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
            child: Text('Erro: $e',
                style: const TextStyle(color: Colors.white))),
        data: (posts) {
          final videos = posts
              .where((p) =>
                  p.type == PostType.youtube || p.type == PostType.tiktok)
              .toList();
          if (videos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Sem vídeos para mostrar.\n'
                      'Publique links do YouTube ou TikTok no feed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (_, i) => _ShortItem(post: videos[i], myUid: myUid),
          );
        },
      ),
    );
  }
}

class _ShortItem extends ConsumerWidget {
  final PostModel post;
  final String myUid;
  const _ShortItem({required this.post, required this.myUid});

  Future<void> _open() async {
    final uri = Uri.tryParse(post.content);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = post.isLikedBy(myUid);
    final thumb = post.youtubeThumbnailUrl;
    final isYoutube = post.type == PostType.youtube;

    return GestureDetector(
      onTap: _open,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background thumbnail (YouTube) or solid TikTok-like color.
          if (thumb != null)
            Image.network(thumb, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black))
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF3D0F4E)],
                ),
              ),
            ),
          // Dim overlay for legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Big play button
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 56),
            ),
          ),
          // Source badge top-left
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isYoutube ? Colors.red : Colors.pink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isYoutube ? 'YouTube' : 'TikTok',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Author + caption bottom-left
          Positioned(
            left: 16,
            right: 80,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: post.userPhotoUrl != null
                          ? NetworkImage(post.userPhotoUrl!)
                          : null,
                      backgroundColor: Colors.white24,
                      child: post.userPhotoUrl == null
                          ? Text(
                              post.userName.isNotEmpty
                                  ? post.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '@${post.userName}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (post.caption != null && post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.caption!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          // Right-side action column (like / comments / share-ish)
          Positioned(
            right: 12,
            bottom: 40,
            child: Column(
              children: [
                _ShortAction(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${post.likesCount}',
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () => ref
                      .read(postRepositoryProvider)
                      .toggleLike(post.id, myUid),
                ),
                const SizedBox(height: 14),
                _ShortAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  color: Colors.white,
                  onTap: _open,
                ),
                const SizedBox(height: 14),
                _ShortAction(
                  icon: Icons.share_rounded,
                  label: 'Compartilhar',
                  color: Colors.white,
                  onTap: () => ref
                      .read(postRepositoryProvider)
                      .sharePost(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShortAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
