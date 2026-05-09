import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/sports_provider.dart';
import '../../widgets/user_badge.dart';
import '../profile/user_profile_screen.dart';

enum _UsersFilter { all, premium, wantingToday }

/// Busca unificada de usuários: todos, premium, ou querem jogar hoje.
/// Ordenado por distância quando o usuário tem coordenadas.
class FindUsersScreen extends ConsumerStatefulWidget {
  final double? userLat;
  final double? userLng;

  const FindUsersScreen({super.key, this.userLat, this.userLng});

  @override
  ConsumerState<FindUsersScreen> createState() => _FindUsersScreenState();
}

class _FindUsersScreenState extends ConsumerState<FindUsersScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  _UsersFilter _filter = _UsersFilter.all;

  // Pagination cap (avoid rendering 10k tiles).
  static const int _pageSize = 100;
  int _visibleCount = _pageSize;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final radius = ref.watch(mapRadiusProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final players = ref.watch(availabilityStreamProvider).valueOrNull ?? [];

    final wantingTodayUids = players.map((p) => p.userId).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar usuários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Raio de busca',
            onPressed: () => _showRadiusSheet(context),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (users) {
          // Filter chain
          var list = users.where((u) => u.id != myUid).toList();

          if (_query.isNotEmpty) {
            list = list.where((u) {
              final q = _query.toLowerCase();
              return (u.name ?? '').toLowerCase().contains(q) ||
                  (u.username ?? '').toLowerCase().contains(q) ||
                  (u.searchableByEmail &&
                      u.email.toLowerCase().contains(q));
            }).toList();
          }

          switch (_filter) {
            case _UsersFilter.all:
              break;
            case _UsersFilter.premium:
              list = list.where((u) => u.isPremium || u.isAdmin).toList();
              break;
            case _UsersFilter.wantingToday:
              list = list
                  .where((u) => wantingTodayUids.contains(u.id))
                  .toList();
              break;
          }

          // Distance filter + sort
          final hasLoc =
              widget.userLat != null && widget.userLng != null;
          if (hasLoc) {
            list = list.where((u) {
              final lat = u.effectiveLat;
              final lng = u.effectiveLng;
              if (lat == null || lng == null) return true;
              return GeoUtils.distanceKm(
                      widget.userLat!, widget.userLng!, lat, lng) <=
                  radius;
            }).toList()
              ..sort((a, b) {
                final da = (a.effectiveLat == null || a.effectiveLng == null)
                    ? double.infinity
                    : GeoUtils.distanceKm(widget.userLat!, widget.userLng!,
                        a.effectiveLat!, a.effectiveLng!);
                final db = (b.effectiveLat == null || b.effectiveLng == null)
                    ? double.infinity
                    : GeoUtils.distanceKm(widget.userLat!, widget.userLng!,
                        b.effectiveLat!, b.effectiveLng!);
                return da.compareTo(db);
              });
          }

          final total = list.length;
          final showing = list.take(_visibleCount).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Nome, @usuário ou e-mail…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _ctrl.clear();
                              setState(() {
                                _query = '';
                                _visibleCount = _pageSize;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() {
                    _query = v.trim();
                    _visibleCount = _pageSize;
                  }),
                ),
              ),
              // Filter chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todos'),
                        selected: _filter == _UsersFilter.all,
                        onSelected: (_) => setState(() {
                          _filter = _UsersFilter.all;
                          _visibleCount = _pageSize;
                        }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(Icons.workspace_premium_rounded,
                            size: 16, color: Colors.amber.shade700),
                        label: const Text('Premium'),
                        selected: _filter == _UsersFilter.premium,
                        onSelected: (_) => setState(() {
                          _filter = _UsersFilter.premium;
                          _visibleCount = _pageSize;
                        }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar:
                            const Icon(Icons.sports_score_rounded, size: 16),
                        label: const Text('Querem jogar hoje'),
                        selected: _filter == _UsersFilter.wantingToday,
                        onSelected: (_) => setState(() {
                          _filter = _UsersFilter.wantingToday;
                          _visibleCount = _pageSize;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              // Stats
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.radar_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasLoc
                            ? 'Raio: ${radius.toStringAsFixed(0)} km • $total usuário(s)'
                            : '$total usuário(s) • sem GPS para ordenar por distância',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: showing.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_rounded,
                                size: 56, color: cs.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              _filter == _UsersFilter.wantingToday
                                  ? 'Ninguém marcou que quer jogar hoje aqui.'
                                  : _filter == _UsersFilter.premium
                                      ? 'Nenhum usuário premium nas proximidades.'
                                      : 'Nenhum usuário encontrado.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount:
                            showing.length + (showing.length < total ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) {
                          if (i == showing.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: OutlinedButton(
                                onPressed: () => setState(() {
                                  _visibleCount += _pageSize;
                                }),
                                child: Text(
                                    'Carregar mais (${total - showing.length})'),
                              ),
                            );
                          }
                          final u = showing[i];
                          final dist = (hasLoc &&
                                  u.effectiveLat != null &&
                                  u.effectiveLng != null)
                              ? GeoUtils.distanceKm(
                                  widget.userLat!,
                                  widget.userLng!,
                                  u.effectiveLat!,
                                  u.effectiveLng!)
                              : null;
                          final wantingToday =
                              wantingTodayUids.contains(u.id);
                          final player = wantingToday
                              ? players.firstWhere((p) => p.userId == u.id)
                              : null;
                          return _UserTile(
                            user: u,
                            distanceKm: dist,
                            sportTodayLabel: player?.sport,
                            onTap: () => AppNavigator.pushWithNavBar(
                              context,
                              UserProfileScreen(userId: u.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRadiusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final radius = ref.watch(mapRadiusProvider);
          final theme = Theme.of(ctx);
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final double? distanceKm;
  final String? sportTodayLabel;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    this.distanceKm,
    this.sportTodayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = user.name ?? 'Usuário';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final subtitleParts = <String>[];
    if (sportTodayLabel != null) {
      subtitleParts.add('🏟️ Quer jogar $sportTodayLabel');
    }
    if (distanceKm != null) {
      subtitleParts.add(GeoUtils.formatDistance(distanceKm!));
    }
    if (subtitleParts.isEmpty && user.username != null) {
      subtitleParts.add('@${user.username}');
    } else if (subtitleParts.isEmpty) {
      subtitleParts.add(user.email);
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        backgroundColor: cs.primaryContainer,
        child: user.photoUrl == null
            ? Text(initial, style: TextStyle(color: cs.onPrimaryContainer))
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          UserBadge(user: user),
        ],
      ),
      subtitle: Text(
        subtitleParts.join(' • '),
        style: TextStyle(color: cs.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
