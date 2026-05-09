import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/models/venue_attendance_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../providers/post_provider.dart';
import '../../providers/sports_provider.dart';
import '../chat/conversation_screen.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final SportsVenueModel venue;
  final double? userLat;
  final double? userLng;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    this.userLat,
    this.userLng,
  });

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.venue.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.venue.sport,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'Info'),
            Tab(icon: Icon(Icons.dynamic_feed_rounded), text: 'Mural'),
            Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Ranking'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              heroTag: null,
              tooltip: 'Publicar no mural',
              onPressed: () => _showAddPostSheet(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(
            venue: widget.venue,
            userLat: widget.userLat,
            userLng: widget.userLng,
          ),
          _MuralTab(venueId: widget.venue.id),
          _RankingTab(venueId: widget.venue.id),
        ],
      ),
    );
  }

  void _showAddPostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddPostSheet(venueId: widget.venue.id),
    );
  }
}

// ─── Aba 1: Info ─────────────────────────────────────────────────────────────

class _InfoTab extends ConsumerWidget {
  final SportsVenueModel venue;
  final double? userLat;
  final double? userLng;

  const _InfoTab({required this.venue, this.userLat, this.userLng});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live venue so occupancy updates rebuild this tab.
    final live = ref
        .watch(venuesStreamProvider)
        .valueOrNull
        ?.where((v) => v.id == venue.id)
        .firstOrNull;
    final v = live ?? venue;
    final dist = (userLat == null || userLng == null)
        ? null
        : GeoUtils.distanceKm(userLat!, userLng!, v.lat, v.lng);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sports_rounded,
                size: 40, color: cs.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              label: Text(v.sport),
              avatar: const Icon(Icons.sports_rounded, size: 16),
              backgroundColor: cs.primaryContainer,
              labelStyle: TextStyle(color: cs.onPrimaryContainer),
            ),
            Chip(
              label: Text(v.isPublic ? 'Público' : 'Privado'),
              avatar: Icon(
                v.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_outline_rounded,
                size: 16,
              ),
              backgroundColor: v.isPublic
                  ? cs.tertiaryContainer
                  : cs.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: v.isPublic
                    ? cs.onTertiaryContainer
                    : cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Status atual da quadra ─────────────────────────────────────
        _OccupancySection(venue: v),
        const SizedBox(height: 8),

        // ── Quem vai jogar lá ─────────────────────────────────────────
        _AttendanceSection(venueId: v.id, venueName: v.name),
        const SizedBox(height: 8),

        // ── Como chegar (Google Maps / Uber) ──────────────────────────
        _NavigationSection(venue: v),
        const SizedBox(height: 8),

        _InfoTile(
          icon: Icons.location_on_rounded,
          label: 'Coordenadas',
          value:
              '${v.lat.toStringAsFixed(5)}, ${v.lng.toStringAsFixed(5)}',
        ),
        if (v.address != null)
          _InfoTile(
            icon: Icons.home_outlined,
            label: 'Endereço',
            value: v.address!,
          ),
        if (dist != null)
          _InfoTile(
            icon: Icons.near_me_rounded,
            label: 'Distância',
            value: GeoUtils.formatDistance(dist),
          ),
        _InfoTile(
          icon: Icons.person_outline_rounded,
          label: 'Adicionado por',
          value: v.addedByName,
        ),
        _InfoTile(
          icon: Icons.calendar_today_rounded,
          label: 'Data',
          value: '${v.createdAt.day.toString().padLeft(2, '0')}/'
              '${v.createdAt.month.toString().padLeft(2, '0')}/'
              '${v.createdAt.year}',
        ),
      ],
    );
  }
}

class _OccupancySection extends ConsumerStatefulWidget {
  final SportsVenueModel venue;
  const _OccupancySection({required this.venue});

  @override
  ConsumerState<_OccupancySection> createState() =>
      _OccupancySectionState();
}

class _OccupancySectionState extends ConsumerState<_OccupancySection> {
  bool _saving = false;

  Future<void> _set(VenueOccupancy o) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref.read(sportsRepositoryProvider).updateOccupancy(
          venueId: widget.venue.id,
          occupancy: o,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger.showSnackBar(
        SnackBar(content: Text('Status atualizado: ${o.label}')),
      ),
    );
  }

  Color _colorFor(VenueOccupancy o, ColorScheme cs) {
    switch (o) {
      case VenueOccupancy.empty:
        return Colors.green;
      case VenueOccupancy.few:
        return Colors.orange;
      case VenueOccupancy.full:
        return Colors.red;
      case VenueOccupancy.unknown:
        return cs.onSurfaceVariant;
    }
  }

  IconData _iconFor(VenueOccupancy o) {
    switch (o) {
      case VenueOccupancy.empty:
        return Icons.sentiment_very_satisfied_rounded;
      case VenueOccupancy.few:
        return Icons.groups_2_rounded;
      case VenueOccupancy.full:
        return Icons.groups_rounded;
      case VenueOccupancy.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final v = widget.venue;
    final color = _colorFor(v.occupancy, cs);
    final updated = v.occupancyUpdatedAt;

    String? updatedLabel() {
      if (updated == null) return null;
      final diff = DateTime.now().difference(updated);
      if (diff.inMinutes < 1) return 'agora há pouco';
      if (diff.inHours < 1) return 'há ${diff.inMinutes}min';
      if (diff.inDays < 1) return 'há ${diff.inHours}h';
      return '${updated.day.toString().padLeft(2, '0')}/'
          '${updated.month.toString().padLeft(2, '0')} '
          '${updated.hour.toString().padLeft(2, '0')}:'
          '${updated.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_iconFor(v.occupancy), color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Como está agora?',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        v.occupancy == VenueOccupancy.unknown
                            ? 'Sem atualização recente.'
                            : '${v.occupancy.label}'
                                '${updatedLabel() != null ? ' • atualizado ${updatedLabel()}' : ''}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OccupancyChip(
                  label: 'Vazio',
                  icon: Icons.sentiment_very_satisfied_rounded,
                  color: Colors.green,
                  selected: v.occupancy == VenueOccupancy.empty,
                  onTap: _saving ? null : () => _set(VenueOccupancy.empty),
                ),
                _OccupancyChip(
                  label: 'Poucas pessoas',
                  icon: Icons.groups_2_rounded,
                  color: Colors.orange,
                  selected: v.occupancy == VenueOccupancy.few,
                  onTap: _saving ? null : () => _set(VenueOccupancy.few),
                ),
                _OccupancyChip(
                  label: 'Cheio',
                  icon: Icons.groups_rounded,
                  color: Colors.red,
                  selected: v.occupancy == VenueOccupancy.full,
                  onTap: _saving ? null : () => _set(VenueOccupancy.full),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OccupancyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _OccupancyChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
      label: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w600 : null,
          )),
      backgroundColor: selected ? color : null,
      side: BorderSide(color: color.withValues(alpha: 0.6)),
      onPressed: onTap,
    );
  }
}

// ─── Aba 2: Mural ─────────────────────────────────────────────────────────────

class _MuralTab extends ConsumerWidget {
  final String venueId;
  const _MuralTab({required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(venuePostsStreamProvider(venueId));
    final cs = Theme.of(context).colorScheme;

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dynamic_feed_rounded,
                    size: 56, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('Nenhuma publicação ainda.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Seja o primeiro a postar!',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _MuralPostCard(post: posts[i]),
        );
      },
    );
  }
}

class _MuralPostCard extends StatelessWidget {
  final PostModel post;
  const _MuralPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final icon = _typeIcon(post.type);
    final color = _typeColor(post.type, cs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: post.userPhotoUrl != null
                      ? NetworkImage(post.userPhotoUrl!)
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: post.userPhotoUrl == null
                      ? Text(
                          post.userName.isNotEmpty
                              ? post.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(post.userName,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(_typeLabel(post.type),
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall),
            if (post.caption != null && post.caption!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(post.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite_border_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${post.likesCount}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${post.commentsCount}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const Spacer(),
                Text(
                  _relativeTime(post.createdAt),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(PostType t) {
    switch (t) {
      case PostType.youtube:
        return Icons.play_circle_outline_rounded;
      case PostType.tiktok:
        return Icons.music_video_rounded;
      case PostType.link:
        return Icons.link_rounded;
      case PostType.text:
        return Icons.notes_rounded;
    }
  }

  String _typeLabel(PostType t) {
    switch (t) {
      case PostType.youtube:
        return 'YouTube';
      case PostType.tiktok:
        return 'TikTok';
      case PostType.link:
        return 'Link';
      case PostType.text:
        return 'Texto';
    }
  }

  Color _typeColor(PostType t, ColorScheme cs) {
    switch (t) {
      case PostType.youtube:
        return Colors.red;
      case PostType.tiktok:
        return Colors.pink;
      case PostType.link:
        return cs.primary;
      case PostType.text:
        return cs.tertiary;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

// ─── Aba 3: Ranking ───────────────────────────────────────────────────────────

class _RankingTab extends ConsumerWidget {
  final String venueId;
  const _RankingTab({required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(venuePostsStreamProvider(venueId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (posts) {
        // Agrega por userId
        final map = <String, _RankEntry>{};
        for (final p in posts) {
          map.update(
            p.userId,
            (e) => _RankEntry(
              userId: p.userId,
              userName: p.userName,
              photoUrl: p.userPhotoUrl,
              posts: e.posts + 1,
              likes: e.likes + p.likesCount,
            ),
            ifAbsent: () => _RankEntry(
              userId: p.userId,
              userName: p.userName,
              photoUrl: p.userPhotoUrl,
              posts: 1,
              likes: p.likesCount,
            ),
          );
        }

        final ranking = map.values.toList()
          ..sort((a, b) {
            final s = (b.posts * 3 + b.likes).compareTo(a.posts * 3 + a.likes);
            return s != 0 ? s : a.userName.compareTo(b.userName);
          });

        if (ranking.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 56, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('Ainda sem jogadores no ranking.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: ranking.length,
          itemBuilder: (_, i) {
            final entry = ranking[i];
            final pos = i + 1;
            final medalColor = pos == 1
                ? Colors.amber
                : pos == 2
                    ? Colors.grey.shade400
                    : pos == 3
                        ? Colors.brown.shade300
                        : cs.onSurfaceVariant;

            return ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: entry.photoUrl != null
                        ? NetworkImage(entry.photoUrl!)
                        : null,
                    backgroundColor: cs.primaryContainer,
                    child: entry.photoUrl == null
                        ? Text(
                            entry.userName.isNotEmpty
                                ? entry.userName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.titleSmall,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: medalColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: cs.surface, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$pos',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: pos <= 3 ? Colors.white : cs.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(entry.userName,
                  style: TextStyle(
                    fontWeight:
                        pos <= 3 ? FontWeight.bold : FontWeight.normal,
                  )),
              subtitle: Text(
                  '${entry.posts} publicaç${entry.posts == 1 ? 'ão' : 'ões'} · ${entry.likes} curtidas'),
              trailing: pos == 1
                  ? const Icon(Icons.emoji_events_rounded,
                      color: Colors.amber)
                  : null,
            );
          },
        );
      },
    );
  }
}

class _RankEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final int posts;
  final int likes;

  const _RankEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.posts,
    required this.likes,
  });
}

// ─── Bottom sheet: adicionar post no mural ────────────────────────────────────

class _AddPostSheet extends ConsumerStatefulWidget {
  final String venueId;
  const _AddPostSheet({required this.venueId});

  @override
  ConsumerState<_AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends ConsumerState<_AddPostSheet> {
  PostType _type = PostType.link;
  final _contentCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _loading = true);
    final result = await ref.read(postRepositoryProvider).addPost(
          type: _type,
          content: content,
          caption: _captionCtrl.text.trim().isEmpty
              ? null
              : _captionCtrl.text.trim(),
          venueId: widget.venueId,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = _type == PostType.link
        ? 'https://...'
        : _type == PostType.youtube
            ? 'URL do vídeo YouTube'
            : _type == PostType.tiktok
                ? 'URL do TikTok'
                : 'Escreva um comentário sobre este local...';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Publicar no mural',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<PostType>(
            segments: const [
              ButtonSegment(
                  value: PostType.link,
                  icon: Icon(Icons.link_rounded),
                  label: Text('Link')),
              ButtonSegment(
                  value: PostType.youtube,
                  icon: Icon(Icons.play_circle_outline_rounded),
                  label: Text('YouTube')),
              ButtonSegment(
                  value: PostType.text,
                  icon: Icon(Icons.notes_rounded),
                  label: Text('Texto')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            maxLines: _type == PostType.text ? 4 : 1,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _captionCtrl,
            decoration: const InputDecoration(
              hintText: 'Legenda (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}

// ─── Quem vai jogar lá ──────────────────────────────────────────────────────

class _AttendanceSection extends ConsumerWidget {
  final String venueId;
  final String venueName;
  const _AttendanceSection({required this.venueId, required this.venueName});

  static String _slotKey(DateTime dt) =>
      '${dt.year}-${dt.month}-${dt.day}-${dt.hour}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final attendees =
        ref.watch(venueAttendanceProvider(venueId)).valueOrNull ?? const [];
    final mine = attendees.where((a) => a.userId == myUid).firstOrNull;

    // Group by hour slot (date + hour).
    final slots = <String, List<VenueAttendanceModel>>{};
    for (final a in attendees) {
      slots.putIfAbsent(_slotKey(a.startAt), () => []).add(a);
    }
    final slotEntries = slots.entries.toList()
      ..sort((a, b) =>
          a.value.first.startAt.compareTo(b.value.first.startAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_available_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quem vai jogar lá',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        attendees.isEmpty
                            ? 'Ninguém marcou presença ainda.'
                            : '${attendees.length} pessoa${attendees.length == 1 ? '' : 's'} • '
                                '${slots.length} horário${slots.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...slotEntries.map((e) {
              final slotList = e.value;
              final slotStart = slotList.first.startAt;
              final imIn = slotList.any((a) => a.userId == myUid);
              return _SlotCard(
                attendees: slotList,
                slotStart: slotStart,
                myUid: myUid,
                onOpenChat: imIn
                    ? () => _openSlotChat(context, ref, slotStart)
                    : null,
                onJoinSlot: imIn
                    ? null
                    : () => _showMarkSheet(
                          context,
                          ref,
                          prefilledStart: slotStart,
                          prefilledDuration: slotList.first.endAt
                              .difference(slotStart),
                        ),
                onCancel: imIn ? () => _cancel(context, ref) : null,
              );
            }),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showMarkSheet(context, ref),
              icon: Icon(mine == null
                  ? Icons.add_rounded
                  : Icons.edit_calendar_rounded),
              label: Text(mine == null
                  ? 'Vou jogar nessa quadra'
                  : 'Alterar meu horário'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMarkSheet(BuildContext context, WidgetRef ref,
      {DateTime? prefilledStart, Duration? prefilledDuration}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_MarkAttendanceResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MarkAttendanceSheet(
        initialStart: prefilledStart,
        initialDuration: prefilledDuration,
      ),
    );
    if (result == null) return;
    final res = await ref.read(sportsRepositoryProvider).markAttendance(
          venueId: venueId,
          startAt: result.start,
          duration: result.duration,
        );
    if (!context.mounted) return;
    await res.fold(
      (f) async => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) async {
        // Auto-join the venue-slot group chat for this slot.
        try {
          await ref.read(chatRepositoryProvider).getOrCreateVenueSlotChat(
                venueId: venueId,
                venueName: venueName,
                startAt: result.start,
              );
        } catch (_) {/* non-fatal */}
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Presença marcada! Grupo do horário pronto.')),
        );
      },
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final res =
        await ref.read(sportsRepositoryProvider).removeMyAttendance(venueId);
    res.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Presença cancelada.')),
      ),
    );
  }

  Future<void> _openSlotChat(
      BuildContext context, WidgetRef ref, DateTime slotStart) async {
    final messenger = ScaffoldMessenger.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final conv =
          await ref.read(chatRepositoryProvider).getOrCreateVenueSlotChat(
                venueId: venueId,
                venueName: venueName,
                startAt: slotStart,
              );
      if (!context.mounted) return;
      AppNavigator.pushWithNavBar(
        context,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Erro ao abrir grupo: $e')));
    }
  }

}

class _SlotCard extends StatelessWidget {
  final List<VenueAttendanceModel> attendees;
  final DateTime slotStart;
  final String myUid;
  final VoidCallback? onOpenChat;
  final VoidCallback? onJoinSlot;
  final VoidCallback? onCancel;

  const _SlotCard({
    required this.attendees,
    required this.slotStart,
    required this.myUid,
    this.onOpenChat,
    this.onJoinSlot,
    this.onCancel,
  });

  String _slotLabel() {
    final now = DateTime.now();
    final isToday = slotStart.year == now.year &&
        slotStart.month == now.month &&
        slotStart.day == now.day;
    final isTomorrow = slotStart.year == now.year &&
        slotStart.month == now.month &&
        slotStart.day == now.day + 1;
    final hh = slotStart.hour.toString().padLeft(2, '0');
    final next = ((slotStart.hour + 1) % 24).toString().padLeft(2, '0');
    final dayPart = isToday
        ? 'Hoje'
        : isTomorrow
            ? 'Amanhã'
            : '${slotStart.day.toString().padLeft(2, '0')}/'
                '${slotStart.month.toString().padLeft(2, '0')}';
    return '$dayPart • ${hh}h–${next}h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iAmIn = onOpenChat != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: iAmIn
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iAmIn
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 18, color: iAmIn ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(_slotLabel(),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${attendees.length} pessoa${attendees.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: attendees
                .map((a) => Chip(
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundImage: a.userPhotoUrl != null
                            ? NetworkImage(a.userPhotoUrl!)
                            : null,
                        backgroundColor: cs.surfaceContainerHighest,
                        child: a.userPhotoUrl == null
                            ? Text(
                                a.userName.isNotEmpty
                                    ? a.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 10),
                              )
                            : null,
                      ),
                      label: Text(
                        a.userId == myUid ? 'Você' : a.userName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (onOpenChat != null)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.forum_rounded, size: 18),
                    label: const Text('Abrir grupo'),
                  ),
                ),
              if (onJoinSlot != null)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onJoinSlot,
                    icon: const Icon(Icons.group_add_rounded, size: 18),
                    label: const Text('Juntar a este horário'),
                  ),
                ),
              if (onCancel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkAttendanceResult {
  final DateTime start;
  final Duration duration;
  const _MarkAttendanceResult(this.start, this.duration);
}

class _MarkAttendanceSheet extends StatefulWidget {
  final DateTime? initialStart;
  final Duration? initialDuration;
  const _MarkAttendanceSheet({this.initialStart, this.initialDuration});

  @override
  State<_MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  late DateTime _start;
  late int _durationMin;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initialStart ??
        DateTime(now.year, now.month, now.day, now.hour + 1);
    _durationMin = widget.initialDuration?.inMinutes ?? 120;
  }

  Future<void> _pickStart() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (pickedTime == null) return;
    setState(() {
      _start = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _fmtStart() {
    final today = DateTime.now();
    final isToday = _start.year == today.year &&
        _start.month == today.month &&
        _start.day == today.day;
    final hh = '${_start.hour.toString().padLeft(2, '0')}:'
        '${_start.minute.toString().padLeft(2, '0')}';
    return isToday
        ? 'Hoje, $hh'
        : '${_start.day.toString().padLeft(2, '0')}/'
            '${_start.month.toString().padLeft(2, '0')} $hh';
  }

  String _fmtDuration() {
    final h = _durationMin ~/ 60;
    final m = _durationMin % 60;
    if (h == 0) return '${m}min';
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Marcar presença',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Outros jogadores verão seu horário e poderão se juntar.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Início'),
            subtitle: Text(_fmtStart()),
            trailing: const Icon(Icons.edit_rounded),
            onTap: _pickStart,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_rounded),
              const SizedBox(width: 8),
              Text('Duração: ${_fmtDuration()}',
                  style: theme.textTheme.bodyLarge),
            ],
          ),
          Slider(
            value: _durationMin.toDouble(),
            min: 30,
            max: 360,
            divisions: 11,
            label: _fmtDuration(),
            onChanged: (v) => setState(() => _durationMin = v.round()),
          ),
          Wrap(
            spacing: 8,
            children: const [60, 90, 120, 180]
                .map((m) => ChoiceChip(
                      label: Text(m == 60
                          ? '1h'
                          : m == 90
                              ? '1h30'
                              : m == 120
                                  ? '2h'
                                  : '3h'),
                      selected: _durationMin == m,
                      onSelected: (_) => setState(() => _durationMin = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(
              _MarkAttendanceResult(
                  _start, Duration(minutes: _durationMin)),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar presença'),
          ),
        ],
      ),
    );
  }
}

// ─── Como chegar (apps externos de navegação) ───────────────────────────────

class _NavigationSection extends StatelessWidget {
  final SportsVenueModel venue;
  const _NavigationSection({required this.venue});

  Future<void> _openGoogleMaps(BuildContext context) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${venue.lat},${venue.lng}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
        );
      }
    }
  }

  Future<void> _openUber(BuildContext context) async {
    final name = Uri.encodeComponent(venue.name);
    // Tries the Uber app first, falls back to the mobile web URL.
    final appUri = Uri.parse(
        'uber://?action=setPickup&pickup=my_location&dropoff[latitude]=${venue.lat}&dropoff[longitude]=${venue.lng}&dropoff[nickname]=$name');
    final webUri = Uri.parse(
        'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=${venue.lat}&dropoff[longitude]=${venue.lng}&dropoff[nickname]=$name');
    final ok = await launchUrl(appUri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (ok) return;
    final web =
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
    if (!web && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Uber.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route_rounded, color: cs.primary),
                const SizedBox(width: 10),
                Text('Como chegar',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMaps(context),
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Google Maps'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openUber(context),
                    icon: const Icon(Icons.local_taxi_rounded),
                    label: const Text('Uber'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
