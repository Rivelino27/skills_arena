import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/player_availability_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/sports_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/mark_availability_sheet.dart';
import '../../widgets/user_badge.dart';
import '../chat/conversation_screen.dart';
import '../profile/user_profile_screen.dart';

/// Tela de busca de jogadores — com bottom nav bar visível (pushWithNavBar).
class FindPlayersScreen extends ConsumerStatefulWidget {
  final double? userLat;
  final double? userLng;

  const FindPlayersScreen({super.key, this.userLat, this.userLng});

  @override
  ConsumerState<FindPlayersScreen> createState() => _FindPlayersScreenState();
}

class _FindPlayersScreenState extends ConsumerState<FindPlayersScreen>
    with SingleTickerProviderStateMixin {
  String? _sportFilter;
  late TabController _tabCtrl;

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
    final radius = ref.watch(mapRadiusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Jogadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Raio de busca',
            onPressed: () => _showRadiusSheet(context, ref, radius),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.sports_score_rounded), text: 'Querem jogar'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Localização fixa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildPlayersTab(context),
          _buildFixedUsersTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMarkAvailabilityAndApply(context, ref),
        icon: const Icon(Icons.sports_rounded),
        label: const Text('Quero jogar'),
      ),
    );
  }

  Widget _buildPlayersTab(BuildContext context) {
    final allPlayers = ref.watch(availabilityStreamProvider).valueOrNull ?? [];
    final radius = ref.watch(mapRadiusProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final blocked = me?.blockedUsers ?? const <String>[];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final players = allPlayers.where((p) {
      if (p.userId == currentUid) return false;
      if (blocked.contains(p.userId)) return false;
      if (_sportFilter != null && p.sport != _sportFilter) return false;
      if (widget.userLat != null && widget.userLng != null) {
        return GeoUtils.distanceKm(
                widget.userLat!, widget.userLng!, p.lat, p.lng) <=
            radius;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (widget.userLat == null) return 0;
        final da = GeoUtils.distanceKm(
            widget.userLat!, widget.userLng!, a.lat, a.lng);
        final db = GeoUtils.distanceKm(
            widget.userLat!, widget.userLng!, b.lat, b.lng);
        return da.compareTo(db);
      });

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Todos'),
                  selected: _sportFilter == null,
                  onSelected: (_) => setState(() => _sportFilter = null),
                ),
              ),
              ...kSportsList.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: _sportFilter == s,
                      onSelected: (_) => setState(
                        () => _sportFilter = _sportFilter == s ? null : s,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.radar_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Raio: ${radius.toStringAsFixed(0)} km  •  '
                '${players.length} jogador(es) encontrado(s)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: players.isEmpty
              ? _EmptyState(
                  sport: _sportFilter,
                  hasLocation: widget.userLat != null,
                  onMark: () => showMarkAvailabilityAndApply(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PlayerCard(
                    player: players[i],
                    userLat: widget.userLat,
                    userLng: widget.userLng,
                    onChat: () => _openChatWith(players[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFixedUsersTab(BuildContext context) {
    final allUsers = ref.watch(visibleUsersStreamProvider).valueOrNull ?? [];
    final radius = ref.watch(mapRadiusProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final users = allUsers.where((u) {
      if (u.id == myUid) return false;
      final lat = u.effectiveLat;
      final lng = u.effectiveLng;
      if (lat == null || lng == null) return false;
      if (widget.userLat != null && widget.userLng != null) {
        return GeoUtils.distanceKm(
                widget.userLat!, widget.userLng!, lat, lng) <=
            radius;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (widget.userLat == null) return 0;
        final da = GeoUtils.distanceKm(widget.userLat!, widget.userLng!,
            a.effectiveLat!, a.effectiveLng!);
        final db = GeoUtils.distanceKm(widget.userLat!, widget.userLng!,
            b.effectiveLat!, b.effectiveLng!);
        return da.compareTo(db);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.radar_rounded, size: 16, color: cs.secondary),
              const SizedBox(width: 4),
              Text(
                'Raio: ${radius.toStringAsFixed(0)} km  •  '
                '${users.length} jogador(es) fixo(s)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: users.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum jogador com localização fixa nas proximidades',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final dist =
                        (widget.userLat != null && widget.userLng != null)
                            ? GeoUtils.distanceKm(widget.userLat!,
                                widget.userLng!, u.effectiveLat!, u.effectiveLng!)
                            : null;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: u.photoUrl != null
                            ? NetworkImage(u.photoUrl!)
                            : null,
                        backgroundColor: cs.primaryContainer,
                        child: u.photoUrl == null
                            ? Text(
                                (u.name ?? 'U').isNotEmpty
                                    ? (u.name ?? 'U')[0].toUpperCase()
                                    : '?',
                                style:
                                    TextStyle(color: cs.onPrimaryContainer),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              u.name ?? 'Usuário',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          UserBadge(user: u),
                        ],
                      ),
                      subtitle: Text(
                        dist != null
                            ? GeoUtils.formatDistance(dist)
                            : (u.username != null
                                ? '@${u.username}'
                                : u.email),
                        style: TextStyle(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.chat_bubble_outline_rounded),
                            tooltip: 'Enviar mensagem',
                            onPressed: () => _openChatWithUser(u),
                            visualDensity: VisualDensity.compact,
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                        ],
                      ),
                      onTap: () => AppNavigator.pushWithNavBar(
                          context, UserProfileScreen(userId: u.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openChatWith(PlayerAvailabilityModel player) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conv =
          await ref.read(chatRepositoryProvider).getOrCreateConversation(
                otherUid: player.userId,
                otherName: player.userName,
                otherPhoto: player.userPhotoUrl,
              );
      if (!mounted) return;
      AppNavigator.pushWithNavBar(
        context,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _openChatWithUser(UserModel u) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conv =
          await ref.read(chatRepositoryProvider).getOrCreateConversation(
                otherUid: u.id,
                otherName: u.name ?? 'Usuário',
                otherPhoto: u.photoUrl,
              );
      if (!mounted) return;
      AppNavigator.pushWithNavBar(
        context,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _showRadiusSheet(BuildContext context, WidgetRef ref, double current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RadiusSheet(currentRadius: current),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final PlayerAvailabilityModel player;
  final double? userLat;
  final double? userLng;
  final VoidCallback onChat;

  const _PlayerCard({
    required this.player,
    this.userLat,
    this.userLng,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dist = (userLat == null || userLng == null)
        ? null
        : GeoUtils.distanceKm(userLat!, userLng!, player.lat, player.lng);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: player.userPhotoUrl != null
              ? NetworkImage(player.userPhotoUrl!)
              : null,
          backgroundColor: cs.primaryContainer,
          child: player.userPhotoUrl == null
              ? Text(
                  player.userName.isNotEmpty
                      ? player.userName[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.titleMedium,
                )
              : null,
        ),
        title: Text(player.userName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${player.sport}${dist != null ? ' • ${GeoUtils.formatDistance(dist)}' : ''}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          tooltip: 'Abrir chat',
          onPressed: onChat,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? sport;
  final bool hasLocation;
  final VoidCallback onMark;

  const _EmptyState({
    this.sport,
    required this.hasLocation,
    required this.onMark,
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
            Icon(Icons.people_outline_rounded,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              sport != null
                  ? 'Nenhum jogador de $sport nas proximidades'
                  : 'Nenhum jogador disponível nas proximidades',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Seja o primeiro! Marque que você quer jogar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onMark,
              icon: const Icon(Icons.sports_rounded),
              label: const Text('Quero jogar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusSheet extends ConsumerWidget {
  final double currentRadius;
  const _RadiusSheet({required this.currentRadius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(mapRadiusProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Raio de busca',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(
            '${radius.toStringAsFixed(0)} km',
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          Slider(
            value: radius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${radius.toStringAsFixed(0)} km',
            onChanged: (v) =>
                ref.read(mapRadiusProvider.notifier).state = v,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text('50 km',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
