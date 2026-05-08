import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/geo_utils.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../providers/post_provider.dart';
import '../../providers/sports_provider.dart';

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
