import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/player_availability_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../providers/sports_provider.dart';
import '../../providers/user_provider.dart';
import '../profile/edit_address_screen.dart';
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
  String? _selectedSport;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            tooltip: 'Buscar usuários',
            onPressed: () => AppNavigator.pushWithNavBar(
                context, const SearchUsersScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Quero jogar hoje (status do usuário) ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PlayStatusCard(
              availability: myAvail,
              visibleOnMap: me?.visibleOnMap ?? false,
            ),
          ),
          const SizedBox(height: 16),

          // Map card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MapCard(
              venueCount: venues.length,
              playerCount: players.length,
              onTap: () => _openMap(sport: _selectedSport),
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
                    selected: _selectedSport == null,
                    onSelected: (_) => setState(() => _selectedSport = null),
                  ),
                ),
                ...kSportsList.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s),
                        selected: _selectedSport == s,
                        onSelected: (_) {
                          setState(() =>
                              _selectedSport = _selectedSport == s ? null : s);
                        },
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
              'Acesso rápido',
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
              label: 'Buscar usuários',
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

// ─── Quero jogar hoje — status card ─────────────────────────────────────────

class _PlayStatusCard extends ConsumerWidget {
  final PlayerAvailabilityModel? availability;
  final bool visibleOnMap;

  const _PlayStatusCard({
    required this.availability,
    required this.visibleOnMap,
  });

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
                            ? 'Você quer jogar — ${availability!.sport}'
                            : 'Quero jogar hoje',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isActive
                            ? '${availability!.radiusKm.toStringAsFixed(0)} km · ${remainingText()}'
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
                      await ref
                          .read(sportsRepositoryProvider)
                          .removeAvailability();
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  visibleOnMap
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_outlined,
                  color: visibleOnMap ? cs.tertiary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visível no mapa',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        visibleOnMap
                            ? 'Outros usuários veem sua localização aproximada.'
                            : 'Sua localização não aparece para ninguém.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: visibleOnMap,
                  onChanged: (v) async {
                    final lat = availability?.lat;
                    final lng = availability?.lng;
                    await ref
                        .read(socialRepositoryProvider)
                        .setVisibleOnMap(visible: v, lat: lat, lng: lng);
                    if (v && lat == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Abra o mapa para registrar sua localização.',
                          ),
                        ),
                      );
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
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_MarkResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _MarkAvailabilitySheet(),
    );
    if (result == null) return;
    final res = await ref.read(sportsRepositoryProvider).markAvailability(
          sport: result.sport,
          lat: result.lat,
          lng: result.lng,
          radiusKm: result.radiusKm,
        );
    res.fold(
      (f) => messenger.showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Disponibilidade ativada por 24h.')),
      ),
    );
  }
}

class _MarkResult {
  final String sport;
  final double lat;
  final double lng;
  final double radiusKm;
  const _MarkResult(this.sport, this.lat, this.lng, this.radiusKm);
}

class _MarkAvailabilitySheet extends ConsumerStatefulWidget {
  const _MarkAvailabilitySheet();

  @override
  ConsumerState<_MarkAvailabilitySheet> createState() =>
      _MarkAvailabilitySheetState();
}

class _MarkAvailabilitySheetState
    extends ConsumerState<_MarkAvailabilitySheet> {
  String _sport = kSportsList.first;
  double _radius = 5;
  // Default to São Paulo center; user must open map for real location.
  static const double _defaultLat = -23.5505;
  static const double _defaultLng = -46.6333;

  // Override location: null = use user's effective (fixed > lastLat).
  double? _overrideLat;
  double? _overrideLng;
  String? _overrideLabel;
  bool _gettingGps = false;

  Future<void> _useGpsNow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _gettingGps = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (!enabled) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Ative o GPS para usar localização atual.')));
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Permissão de localização negada.')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      if (!mounted) return;
      setState(() {
        _overrideLat = pos.latitude;
        _overrideLng = pos.longitude;
        _overrideLabel = 'GPS atual';
      });
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Erro no GPS: $e')));
    } finally {
      if (mounted) setState(() => _gettingGps = false);
    }
  }

  void _useFixedAddress() {
    setState(() {
      _overrideLat = null;
      _overrideLng = null;
      _overrideLabel = null;
    });
  }

  Future<void> _editFixedAddress() async {
    Navigator.of(context).pop();
    await AppNavigator.pushWithNavBar(
        context, const EditAddressScreen());
  }

  Future<void> _showLocationSourceSheet() async {
    final me = ref.read(currentUserProvider).valueOrNull;
    final hasFixed = me?.addressLat != null;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(sheetCtx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Usar meu endereço fixo'),
              subtitle: Text(hasFixed
                  ? (me?.address ?? 'Endereço cadastrado')
                  : 'Nenhum endereço fixo cadastrado'),
              enabled: hasFixed,
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _useFixedAddress();
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location_rounded),
              title: const Text('Usar GPS atual'),
              subtitle: const Text('Pega sua localização agora'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _useGpsNow();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_location_alt_outlined),
              title: const Text('Cadastrar / editar endereço fixo'),
              subtitle: const Text('Buscar e salvar um endereço personalizado'),
              onTap: _editFixedAddress,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final me = ref.watch(currentUserProvider).valueOrNull;
    final fixedLat = me?.effectiveLat;
    final fixedLng = me?.effectiveLng;
    final lat = _overrideLat ?? fixedLat ?? _defaultLat;
    final lng = _overrideLng ?? fixedLng ?? _defaultLng;
    final hasRealLocation = _overrideLat != null || fixedLat != null;
    final usingFixedAddress =
        _overrideLat == null && me?.addressLat != null;
    final usingOverride = _overrideLat != null;

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
          Text('Quero jogar hoje',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Sua disponibilidade ficará visível por 24h dentro do raio escolhido.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          // ── Local de busca (clicável) ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: usingOverride
                  ? cs.tertiaryContainer
                  : usingFixedAddress
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: usingOverride
                    ? cs.tertiary.withValues(alpha: 0.4)
                    : cs.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  usingOverride
                      ? Icons.my_location_rounded
                      : usingFixedAddress
                          ? Icons.home_rounded
                          : Icons.location_off_outlined,
                  color: usingOverride
                      ? cs.onTertiaryContainer
                      : usingFixedAddress
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buscar a partir de:',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        _overrideLabel ??
                            (usingFixedAddress
                                ? (me?.address ?? 'Endereço fixo')
                                : hasRealLocation
                                    ? 'Última localização'
                                    : 'São Paulo (sem endereço)'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: usingOverride
                              ? cs.onTertiaryContainer
                              : usingFixedAddress
                                  ? cs.onPrimaryContainer
                                  : cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _gettingGps ? null : _showLocationSourceSheet,
                  child: _gettingGps
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mudar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.radar_rounded),
              const SizedBox(width: 8),
              Text('Raio: ${_radius.toStringAsFixed(0)} km',
                  style: theme.textTheme.bodyLarge),
            ],
          ),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radius.toStringAsFixed(0)} km',
            onChanged: (v) => setState(() => _radius = v),
          ),
          Wrap(
            spacing: 8,
            children: const [5.0, 7.0, 10.0, 15.0, 25.0]
                .map((r) => ChoiceChip(
                      label: Text('${r.toStringAsFixed(0)} km'),
                      selected: _radius == r,
                      onSelected: (_) => setState(() => _radius = r),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .pop(_MarkResult(_sport, lat, lng, _radius));
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

// ─── Map card ───────────────────────────────────────────────────────────────

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
