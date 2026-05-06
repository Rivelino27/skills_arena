import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/player_availability_model.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/sports_provider.dart';
import '../chat/conversation_screen.dart';
import 'add_venue_screen.dart';
import 'find_players_screen.dart';
import 'venue_detail_screen.dart';

// Cor por esporte
Color _sportColor(String sport) {
  switch (sport) {
    case 'Futebol':
      return Colors.green;
    case 'Basquete':
      return Colors.orange;
    case 'Vôlei':
      return Colors.yellow.shade700;
    case 'Tênis':
    case 'Beach Tennis':
      return Colors.lime.shade700;
    case 'Natação':
      return Colors.blue;
    default:
      return Colors.purple;
  }
}

IconData _sportIcon(String sport) {
  switch (sport) {
    case 'Futebol':
      return Icons.sports_soccer;
    case 'Basquete':
      return Icons.sports_basketball;
    case 'Vôlei':
      return Icons.sports_volleyball;
    case 'Tênis':
    case 'Beach Tennis':
      return Icons.sports_tennis;
    case 'Natação':
      return Icons.pool;
    case 'Corrida':
      return Icons.directions_run;
    default:
      return Icons.sports;
  }
}

class MapScreen extends ConsumerStatefulWidget {
  final String? initialSportFilter;

  const MapScreen({super.key, this.initialSportFilter});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  Position? _userPosition;
  bool _loadingLocation = true;
  bool _pinMode = false;
  bool _showSearch = false;
  bool _searching = false;
  List<_GeoResult> _suggestions = [];
  Timer? _debounce;
  LatLng _pinPosition = const LatLng(-23.5505, -46.6333);

  static const _defaultCenter = LatLng(-23.5505, -46.6333); // São Paulo

  @override
  void initState() {
    super.initState();
    if (widget.initialSportFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedSportFilterProvider.notifier).state =
            widget.initialSportFilter;
      });
    }
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetchSuggestions(query),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _searching = true);
    try {
      final client = HttpClient();
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query.trim(),
        'format': 'json',
        'limit': '5',
        'countrycodes': 'br',
      });
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.userAgentHeader, 'SkillsArena/1.0')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      client.close();
      if (!mounted) return;
      final list = jsonDecode(body) as List<dynamic>;
      setState(() {
        _suggestions = list.map((e) {
          final m = e as Map<String, dynamic>;
          return _GeoResult(
            displayName: m['display_name'] as String,
            lat: double.parse(m['lat'] as String),
            lon: double.parse(m['lon'] as String),
          );
        }).toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectSuggestion(_GeoResult r) {
    _debounce?.cancel();
    _mapController.move(LatLng(r.lat, r.lon), 15.0);
    setState(() {
      _showSearch = false;
      _suggestions = [];
      _searching = false;
    });
    _searchCtrl.clear();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        setState(() {
          _userPosition = pos;
          _loadingLocation = false;
        });
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          14.0,
        );
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(venuesStreamProvider).valueOrNull ?? [];
    final players = ref.watch(availabilityStreamProvider).valueOrNull ?? [];
    final radius = ref.watch(mapRadiusProvider);
    final selectedSport = ref.watch(selectedSportFilterProvider);
    final cs = Theme.of(context).colorScheme;

    final filteredVenues = selectedSport == null
        ? venues
        : venues.where((v) => v.sport == selectedSport).toList();

    final filteredPlayers = players.where((p) {
      if (selectedSport != null && p.sport != selectedSport) return false;
      if (_userPosition == null) return true;
      return GeoUtils.distanceKm(
            _userPosition!.latitude, _userPosition!.longitude,
            p.lat, p.lng) <=
          radius;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Quadras'),
        actions: [
          IconButton(
            icon: Icon(
                _showSearch ? Icons.search_off_rounded : Icons.search_rounded),
            tooltip: _showSearch ? 'Fechar busca' : 'Buscar endereço',
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _suggestions = [];
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Raio de busca',
            onPressed: () => _showRadiusSheet(context, ref, radius),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _SportFilterBar(
            selected: selectedSport,
            onChanged: (s) =>
                ref.read(selectedSportFilterProvider.notifier).state = s,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition != null
                  ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                  : _defaultCenter,
              initialZoom: 13.0,
              onMapEvent: (event) {
                if (_pinMode && event is MapEventMove) {
                  setState(() => _pinPosition = event.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.r27systems.skills_arena',
              ),
              if (_userPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                          _userPosition!.latitude, _userPosition!.longitude),
                      radius: radius * 1000,
                      useRadiusInMeter: true,
                      color: cs.primary.withValues(alpha: 0.08),
                      borderColor: cs.primary.withValues(alpha: 0.4),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              // Marcadores de quadras
              MarkerLayer(
                markers: filteredVenues
                    .map((v) => Marker(
                          point: LatLng(v.lat, v.lng),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => AppNavigator.pushWithoutNavBar(
                              context,
                              VenueDetailScreen(
                                venue: v,
                                userLat: _userPosition?.latitude,
                                userLng: _userPosition?.longitude,
                              ),
                            ),
                            child: _VenueMarker(sport: v.sport),
                          ),
                        ))
                    .toList(),
              ),
              // Marcadores de jogadores
              MarkerLayer(
                markers: filteredPlayers
                    .map((p) => Marker(
                          point: LatLng(p.lat, p.lng),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () =>
                                _showPlayerSheet(context, p),
                            child: _PlayerMarker(player: p),
                          ),
                        ))
                    .toList(),
              ),
              // Marcador do usuário
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          _userPosition!.latitude, _userPosition!.longitude),
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // ── Address search overlay ────────────────────────────────────
          if (_showSearch)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (q) {
                        if (_suggestions.isNotEmpty) {
                          _selectSuggestion(_suggestions.first);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar endereço...',
                        prefixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _showSearch = false;
                            _suggestions = [];
                            _searchCtrl.clear();
                          }),
                        ),
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = _suggestions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                  Icons.location_on_outlined,
                                  size: 20),
                              title: Text(
                                r.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => _selectSuggestion(r),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_loadingLocation)
            Positioned(
              top: 12,
              left: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text('Obtendo localização…'),
                    ],
                  ),
                ),
              ),
            ),
          // ── Pin placement overlay ──────────────────────────────────────
          if (_pinMode) ...[
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 48, color: Colors.red),
                  SizedBox(height: 44),
                ],
              ),
            ),
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(
                      'Mova o mapa para posicionar o pin',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _pinMode
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'pin_cancel',
                  tooltip: 'Cancelar',
                  backgroundColor: cs.errorContainer,
                  foregroundColor: cs.onErrorContainer,
                  onPressed: () => setState(() => _pinMode = false),
                  child: const Icon(Icons.close_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'pin_confirm',
                  label: const Text('Confirmar local'),
                  icon: const Icon(Icons.check_rounded),
                  onPressed: _confirmPin,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate_me',
                  tooltip: 'Minha localização',
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'find_players',
                  tooltip: 'Buscar jogadores',
                  backgroundColor: cs.tertiary,
                  foregroundColor: cs.onTertiary,
                  onPressed: () => AppNavigator.pushWithNavBar(
                    context,
                    FindPlayersScreen(
                      userLat: _userPosition?.latitude,
                      userLng: _userPosition?.longitude,
                    ),
                  ),
                  child: const Icon(Icons.people_alt_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'add_venue',
                  tooltip: 'Adicionar quadra',
                  onPressed: _enterPinMode,
                  child: const Icon(Icons.add_location_alt_rounded),
                ),
              ],
            ),
    );
  }

  void _centerOnUser() {
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.0,
      );
    }
  }

  void _enterPinMode() {
    final center = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _mapController.camera.center;
    setState(() {
      _pinPosition = center;
      _pinMode = true;
    });
  }

  Future<void> _confirmPin() async {
    setState(() => _pinMode = false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await AppNavigator.pushWithoutNavBar<bool>(
      context,
      AddVenueScreen(
        userLat: _pinPosition.latitude,
        userLng: _pinPosition.longitude,
      ),
    );
    if (ok == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Quadra adicionada!')),
      );
    }
  }

  void _showRadiusSheet(BuildContext context, WidgetRef ref, double current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RadiusSheet(currentRadius: current),
    );
  }

  void _showPlayerSheet(BuildContext context, PlayerAvailabilityModel player) {
    final dist = _userPosition == null
        ? null
        : GeoUtils.distanceKm(_userPosition!.latitude, _userPosition!.longitude,
            player.lat, player.lng);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: player.userPhotoUrl != null
                      ? NetworkImage(player.userPhotoUrl!)
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: player.userPhotoUrl == null
                      ? Text(
                          player.userName.isNotEmpty
                              ? player.userName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(player.userName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Quer jogar ${player.sport}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                if (dist != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    GeoUtils.formatDistance(dist),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.primary),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final conv = await ref
                          .read(chatRepositoryProvider)
                          .getOrCreateConversation(
                            otherUid: player.userId,
                            otherName: player.userName,
                            otherPhoto: player.userPhotoUrl,
                          );
                      final myUid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      if (context.mounted) {
                        AppNavigator.pushWithNavBar(
                          context,
                          ConversationScreen(
                              chatId: conv.id, conv: conv, myUid: myUid),
                        );
                      }
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('Enviar mensagem'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

class _GeoResult {
  final String displayName;
  final double lat;
  final double lon;
  const _GeoResult(
      {required this.displayName, required this.lat, required this.lon});
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _VenueMarker extends StatelessWidget {
  final String sport;
  const _VenueMarker({required this.sport});

  @override
  Widget build(BuildContext context) {
    final color = _sportColor(sport);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(_sportIcon(sport), color: Colors.white, size: 20),
    );
  }
}

class _PlayerMarker extends StatelessWidget {
  final PlayerAvailabilityModel player;
  const _PlayerMarker({required this.player});

  @override
  Widget build(BuildContext context) {
    final color = _sportColor(player.sport);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: player.userPhotoUrl != null
              ? ClipOval(
                  child: Image.network(player.userPhotoUrl!,
                      fit: BoxFit.cover, width: 44, height: 44),
                )
              : Icon(Icons.person, color: color, size: 22),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(_sportIcon(player.sport),
                color: Colors.white, size: 10),
          ),
        ),
      ],
    );
  }
}

class _SportFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SportFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todos'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...kSportsList.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s),
                selected: selected == s,
                selectedColor:
                    _sportColor(s).withValues(alpha: 0.25),
                onSelected: (_) => onChanged(selected == s ? null : s),
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 4),
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('50 km',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
