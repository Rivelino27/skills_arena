import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/player_availability_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../providers/sports_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/mark_availability_sheet.dart';
import '../profile/search_users_screen.dart';
import 'find_players_screen.dart';
import 'find_users_screen.dart';
import 'find_venues_screen.dart';
import 'map_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  void _openMap({String? sport}) {
    AppNavigator.pushWithNavBar(
      context,
      MapScreen(initialSportFilter: sport),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final venues = ref.watch(venuesStreamProvider).valueOrNull ?? [];
    final players = ref.watch(availabilityStreamProvider).valueOrNull ?? [];
    final myAvail = ref.watch(myAvailabilityProvider).valueOrNull;
    final me = ref.watch(currentUserProvider).valueOrNull;
    final selectedSport = ref.watch(selectedSportFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            tooltip: 'Buscar usuÃ¡rios',
            onPressed: () => AppNavigator.pushWithNavBar(
                context, const SearchUsersScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // â”€â”€ Quero jogar hoje (status do usuÃ¡rio) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PlayStatusCard(availability: myAvail),
          ),
          const SizedBox(height: 16),

          // Map card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MapCard(
              venueCount: venues.length,
              playerCount: players.length,
              onTap: () => _openMap(sport: selectedSport),
            ),
          ),
          const SizedBox(height: 20),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Filtrar por esporte',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),

          // Sport filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: selectedSport == null,
                    onSelected: (_) => ref
                        .read(selectedSportFilterProvider.notifier)
                        .setSport(null),
                  ),
                ),
                ...kSportsList.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s),
                        selected: selectedSport == s,
                        onSelected: (_) => ref
                            .read(selectedSportFilterProvider.notifier)
                            .setSport(selectedSport == s ? null : s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick-action tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Acesso rÃ¡pido',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    icon: Icons.place_rounded,
                    label: 'Quadras',
                    count: venues.length,
                    color: cs.primary,
                    onTap: () => AppNavigator.pushWithNavBar(
                      context,
                      FindVenuesScreen(
                        userLat: me?.effectiveLat,
                        userLng: me?.effectiveLng,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.sports_score_rounded,
                    label: 'Querem jogar',
                    count: players.length,
                    color: cs.tertiary,
                    onTap: () => AppNavigator.pushWithNavBar(
                      context,
                      FindPlayersScreen(
                        userLat: me?.effectiveLat,
                        userLng: me?.effectiveLng,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _QuickTile(
              icon: Icons.people_rounded,
              label: 'Buscar usuÃ¡rios',
              count: null,
              color: cs.secondary,
              onTap: () => AppNavigator.pushWithNavBar(
                context,
                FindUsersScreen(
                  userLat: me?.effectiveLat,
                  userLng: me?.effectiveLng,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Quero jogar hoje â€” status card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PlayStatusCard extends ConsumerWidget {
  final PlayerAvailabilityModel? availability;

  const _PlayStatusCard({required this.availability});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = availability != null;
    final remaining = isActive
        ? availability!.expiresAt.difference(DateTime.now())
        : Duration.zero;

    String remainingText() {
      if (!isActive) return '';
      final h = remaining.inHours;
      final m = remaining.inMinutes.remainder(60);
      return h > 0 ? 'expira em ${h}h ${m}m' : 'expira em ${m}m';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? cs.primary.withValues(alpha: 0.7)
              : cs.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isActive
                      ? Icons.sports_score_rounded
                      : Icons.sports_outlined,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? 'VocÃª quer jogar â€” ${availability!.sport}'
                            : 'Quero jogar hoje',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isActive
                            ? '${availability!.radiusKm.toStringAsFixed(0)} km Â· ${remainingText()}'
                            : 'Ative para que outros jogadores te encontrem.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) async {
                    if (v) {
                      await _showMarkSheet(context, ref);
                    } else {
                      // Turn off availability AND remove the user from
                      // the map at the same time.
                      await ref
                          .read(sportsRepositoryProvider)
                          .removeAvailability();
                      await ref
                          .read(socialRepositoryProvider)
                          .setVisibleOnMap(visible: false);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMarkSheet(BuildContext context, WidgetRef ref) async {
    await showMarkAvailabilityAndApply(context, ref);
  }
}


// â”€â”€â”€ Map card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MapCard extends StatelessWidget {
  final int venueCount;
  final int playerCount;
  final VoidCallback onTap;

  const _MapCard({
    required this.venueCount,
    required this.playerCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer,
                cs.secondaryContainer,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter(cs.primary)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.map_rounded,
                              color: cs.onPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mapa Esportivo',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: cs.onPrimaryContainer),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.place_rounded,
                          label: '$venueCount quadras',
                          cs: cs,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.people_rounded,
                          label: '$playerCount jogadores',
                          cs: cs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque para abrir o mapa interativo',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              if (count != null)
                Text(
                  '$count',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
