import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/geo_utils.dart';
import '../../../data/models/player_availability_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../providers/sports_provider.dart';

/// Tela de busca de jogadores — com bottom nav bar visível (pushWithNavBar).
class FindPlayersScreen extends ConsumerStatefulWidget {
  final double? userLat;
  final double? userLng;

  const FindPlayersScreen({super.key, this.userLat, this.userLng});

  @override
  ConsumerState<FindPlayersScreen> createState() => _FindPlayersScreenState();
}

class _FindPlayersScreenState extends ConsumerState<FindPlayersScreen> {
  String? _sportFilter;

  @override
  Widget build(BuildContext context) {
    final allPlayers =
        ref.watch(availabilityStreamProvider).valueOrNull ?? [];
    final radius = ref.watch(mapRadiusProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final players = allPlayers.where((p) {
      if (p.userId == currentUid) return false;
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
      ),
      body: Column(
        children: [
          // Filtro de esporte
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
                    onMark: () => _showMarkAvailabilitySheet(context, ref),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PlayerCard(
                      player: players[i],
                      userLat: widget.userLat,
                      userLng: widget.userLng,
                      onChat: () => context.go('/chat'),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMarkAvailabilitySheet(context, ref),
        icon: const Icon(Icons.sports_rounded),
        label: const Text('Quero jogar'),
      ),
    );
  }

  void _showRadiusSheet(BuildContext context, WidgetRef ref, double current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RadiusSheet(currentRadius: current),
    );
  }

  void _showMarkAvailabilitySheet(BuildContext context, WidgetRef ref) {
    if (widget.userLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ative o GPS para marcar sua localização.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _MarkAvailabilitySheet(
        userLat: widget.userLat!,
        userLng: widget.userLng!,
      ),
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
            Icon(Icons.people_outline_rounded, size: 64,
                color: cs.onSurfaceVariant),
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

class _MarkAvailabilitySheet extends ConsumerStatefulWidget {
  final double userLat;
  final double userLng;

  const _MarkAvailabilitySheet({
    required this.userLat,
    required this.userLng,
  });

  @override
  ConsumerState<_MarkAvailabilitySheet> createState() =>
      _MarkAvailabilitySheetState();
}

class _MarkAvailabilitySheetState
    extends ConsumerState<_MarkAvailabilitySheet> {
  String _sport = kSportsList.first;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final radius = ref.watch(mapRadiusProvider);
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
          Text('Quero jogar agora!',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Sua disponibilidade ficará visível por 24 horas '
            'para jogadores no raio de ${radius.toStringAsFixed(0)} km.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _sport,
            decoration: const InputDecoration(
              labelText: 'Esporte',
              prefixIcon: Icon(Icons.sports_rounded),
            ),
            items: kSportsList
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sport = v!),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _confirm,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    final radius = ref.read(mapRadiusProvider);
    final result =
        await ref.read(sportsRepositoryProvider).markAvailability(
              sport: _sport,
              lat: widget.userLat,
              lng: widget.userLng,
              radiusKm: radius,
            );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(f.message),
              backgroundColor: Theme.of(context).colorScheme.error)),
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Você está disponível para jogar! (24h)')),
        );
      },
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
