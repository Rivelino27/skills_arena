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
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../providers/sports_provider.dart';
import '../../providers/user_provider.dart';
import '../chat/conversation_screen.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/mark_availability_sheet.dart';
import 'add_venue_screen.dart';
import 'venue_detail_screen.dart';

/// What to render on the map. Controlled by the segmented toggle on
/// the top-right (next to the count chips). 4 modes:
///   - all: venues + fixed-address users + players (querem jogar hoje)
///   - venues: only sports_venues markers
///   - fixedUsers: only users with `visibleOnMap=true` and a fixed addr
///   - players: only players who marked "Querem jogar hoje"
enum _MapDisplayMode { all, venues, fixedUsers, players }

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
  final double? initialLat;
  final double? initialLng;
  final double? initialZoom;

  const MapScreen({
    super.key,
    this.initialSportFilter,
    this.initialLat,
    this.initialLng,
    this.initialZoom,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  Position? _userPosition;
  bool _loadingLocation = true;
  bool _pinMode = false;
  // What to display on the map: venues+players (both), venues only, or
  // players only. Affects markers and the right-side counter chips.
  _MapDisplayMode _displayMode = _MapDisplayMode.all;
  bool _showSearch = false;
  bool _searching = false;
  List<_GeoResult> _suggestions = [];
  Timer? _debounce;
  LatLng _pinPosition = const LatLng(-23.5505, -46.6333);
  String? _pinAddress;
  bool _reverseGeocoding = false;
  Timer? _revGeoDebounce;

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
    // If caller passed an explicit center, jump there once the map mounts
    // and skip auto-centering on user GPS.
    if (widget.initialLat != null && widget.initialLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(widget.initialLat!, widget.initialLng!),
          widget.initialZoom ?? 16.0,
        );
      });
    }
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _revGeoDebounce?.cancel();
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

  void _reverseGeocode(LatLng pos) {
    _revGeoDebounce?.cancel();
    _revGeoDebounce = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      setState(() => _reverseGeocoding = true);
      try {
        final client = HttpClient();
        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'lat': pos.latitude.toString(),
          'lon': pos.longitude.toString(),
          'format': 'json',
        });
        final request = await client.getUrl(uri);
        request.headers
          ..set(HttpHeaders.userAgentHeader, 'SkillsArena/1.0')
          ..set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final body = await response.transform(const Utf8Decoder()).join();
        client.close();
        if (!mounted) return;
        final json = jsonDecode(body) as Map<String, dynamic>;
        final addr = json['address'] as Map<String, dynamic>?;
        String display = '';
        if (addr != null) {
          final road = addr['road'] as String? ??
              addr['pedestrian'] as String? ??
              addr['street'] as String? ??
              '';
          final number = addr['house_number'] as String? ?? '';
          final postcode = addr['postcode'] as String? ?? '';
          final suburb = addr['suburb'] as String? ??
              addr['neighbourhood'] as String? ??
              addr['city_district'] as String? ??
              '';
          final city = addr['city'] as String? ??
              addr['town'] as String? ??
              addr['municipality'] as String? ??
              '';
          final parts = <String>[];
          if (road.isNotEmpty) {
            parts.add(number.isNotEmpty ? '$road, $number' : road);
          }
          if (suburb.isNotEmpty) parts.add(suburb);
          if (city.isNotEmpty) parts.add(city);
          if (postcode.isNotEmpty) parts.add('CEP $postcode');
          display = parts.join(' • ');
        }
        if (display.isEmpty) {
          display = json['display_name'] as String? ?? '';
        }
        setState(() {
          _pinAddress = display;
          _reverseGeocoding = false;
        });
      } catch (_) {
        if (mounted) setState(() => _reverseGeocoding = false);
      }
    });
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

  /// Best lat/lng to anchor the map on:
  /// 1. live GPS (if granted),
  /// 2. user's fixed/last-known address from their profile,
  /// 3. São Paulo default.
  /// Map works fully without GPS as long as (2) is set.
  LatLng? _fallbackCenter() {
    if (_userPosition != null) {
      return LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me?.effectiveLat != null && me?.effectiveLng != null) {
      return LatLng(me!.effectiveLat!, me.effectiveLng!);
    }
    return null;
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (!serviceEnabled) {
        _useFixedAddressIfAny();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _useFixedAddressIfAny();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('GPS demorou para responder');
      });
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _loadingLocation = false;
      });
      // Don't override an explicit initial center.
      if (widget.initialLat == null || widget.initialLng == null) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          14.0,
        );
      }
      // Silently push the resolved location to the user doc so visibleOnMap /
      // markAvailability can use the latest known coords without re-prompting.
      final me = ref.read(currentUserProvider).valueOrNull;
      if (me != null) {
        await ref.read(socialRepositoryProvider).setVisibleOnMap(
              visible: me.visibleOnMap,
              lat: pos.latitude,
              lng: pos.longitude,
            );
      }
    } catch (_) {
      _useFixedAddressIfAny();
    }
  }

  /// GPS unavailable / denied — center the map on the user's fixed address
  /// if they have one. If not, the default São Paulo center is used.
  void _useFixedAddressIfAny() {
    if (!mounted) return;
    setState(() => _loadingLocation = false);
    if (widget.initialLat != null && widget.initialLng != null) return;
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me?.effectiveLat != null && me?.effectiveLng != null) {
      _mapController.move(
          LatLng(me!.effectiveLat!, me.effectiveLng!), 14.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venues = ref.watch(venuesStreamProvider).valueOrNull ?? [];
    final players = ref.watch(availabilityStreamProvider).valueOrNull ?? [];
    final visibleUsers =
        ref.watch(visibleUsersStreamProvider).valueOrNull ?? const [];
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final radius = ref.watch(mapRadiusProvider);
    final selectedSport = ref.watch(selectedSportFilterProvider);
    final cs = Theme.of(context).colorScheme;

    final filteredVenues = selectedSport == null
        ? venues
        : venues.where((v) => v.sport == selectedSport).toList();

    // Use GPS first, then user's fixed address. If neither, no distance
    // filter is applied (player markers all show).
    final center = _fallbackCenter();
    final filteredPlayers = players.where((p) {
      if (selectedSport != null && p.sport != selectedSport) return false;
      if (center == null) return true;
      return GeoUtils.distanceKm(
              center.latitude, center.longitude, p.lat, p.lng) <=
          radius;
    }).toList();

    // Visible users with a known location, minus self and minus those
    // already shown as "querem jogar" markers (no double-pin).
    final playerUids = players.map((p) => p.userId).toSet();
    final filteredVisibleUsers = visibleUsers.where((u) {
      if (u.id == myUid) return false;
      if (playerUids.contains(u.id)) return false;
      final lat = u.effectiveLat;
      final lng = u.effectiveLng;
      if (lat == null || lng == null) return false;
      if (center == null) return true;
      return GeoUtils.distanceKm(
              center.latitude, center.longitude, lat, lng) <=
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
              initialCenter: widget.initialLat != null &&
                      widget.initialLng != null
                  ? LatLng(widget.initialLat!, widget.initialLng!)
                  : (_fallbackCenter() ?? _defaultCenter),
              initialZoom: widget.initialZoom ?? 13.0,
              onMapEvent: (event) {
                if (_pinMode && event is MapEventMove) {
                  setState(() => _pinPosition = event.camera.center);
                  _reverseGeocode(event.camera.center);
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
              // Quadras — visíveis nos modos 'all' e 'venues'.
              if (_displayMode == _MapDisplayMode.all ||
                  _displayMode == _MapDisplayMode.venues)
                MarkerLayer(
                  markers: filteredVenues
                      .map((v) => Marker(
                            point: LatLng(v.lat, v.lng),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _showVenueSheet(context, v),
                              child: _VenueMarker(sport: v.sport),
                            ),
                          ))
                      .toList(),
                ),
              // Jogadores que marcaram "Quero jogar hoje" — visíveis
              // nos modos 'all' e 'players'.
              if (_displayMode == _MapDisplayMode.all ||
                  _displayMode == _MapDisplayMode.players)
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
              // Usuários com endereço fixo (visibleOnMap) — visíveis
              // nos modos 'all' e 'fixedUsers'.
              if (_displayMode == _MapDisplayMode.all ||
                  _displayMode == _MapDisplayMode.fixedUsers)
                MarkerLayer(
                  markers: filteredVisibleUsers
                      .map((u) => Marker(
                            point:
                                LatLng(u.effectiveLat!, u.effectiveLng!),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showUserSheet(context, u),
                              child: _UserMarker(user: u),
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
          // ── Counter chips (top-right) ──────────────────────────────────
          if (!_pinMode)
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MapDisplayToggle(
                    mode: _displayMode,
                    onChanged: (m) => setState(() => _displayMode = m),
                  ),
                  const SizedBox(height: 8),
                  if (_displayMode == _MapDisplayMode.all ||
                      _displayMode == _MapDisplayMode.players) ...[
                    _CountChip(
                      icon: Icons.sports_score_rounded,
                      color: cs.tertiary,
                      label: '${filteredPlayers.length} querem jogar'
                          '${filteredPlayers.length == 1 ? '' : ''}',
                      onTap: () =>
                          _showPlayersListSheet(context, filteredPlayers),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_displayMode == _MapDisplayMode.all ||
                      _displayMode == _MapDisplayMode.fixedUsers) ...[
                    _CountChip(
                      icon: Icons.people_alt_rounded,
                      color: cs.secondary,
                      label: '${filteredVisibleUsers.length} jogador'
                          '${filteredVisibleUsers.length == 1 ? '' : 'es'} fixo'
                          '${filteredVisibleUsers.length == 1 ? '' : 's'}',
                      onTap: null,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_displayMode == _MapDisplayMode.all ||
                      _displayMode == _MapDisplayMode.venues)
                    _CountChip(
                      icon: Icons.place_rounded,
                      color: cs.primary,
                      label: '${filteredVenues.length} quadra'
                          '${filteredVenues.length == 1 ? '' : 's'}',
                      onTap: () =>
                          _showVenuesListSheet(context, filteredVenues),
                    ),
                ],
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
          // ── Pin address card (bottom, above FABs) ──────────────────────
          if (_pinMode)
            Positioned(
              bottom: 104,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _reverseGeocoding
                            ? const LinearProgressIndicator(minHeight: 2)
                            : Text(
                                _pinAddress?.isNotEmpty == true
                                    ? _pinAddress!
                                    : 'Obtendo endereço…',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // ── Address search overlay (always on top) ─────────────────────
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
                  onPressed: () {
                    _revGeoDebounce?.cancel();
                    setState(() {
                      _pinMode = false;
                      _pinAddress = null;
                    });
                  },
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
                // "Quero jogar" toggle. Reads from myAvailabilityProvider
                // so it stays in sync with the Explore tab card.
                Consumer(
                  builder: (ctx, ref, _) {
                    final myAvail =
                        ref.watch(myAvailabilityProvider).valueOrNull;
                    final active = myAvail != null;
                    return FloatingActionButton.extended(
                      heroTag: 'quero_jogar',
                      backgroundColor:
                          active ? Colors.green : cs.tertiary,
                      foregroundColor:
                          active ? Colors.white : cs.onTertiary,
                      icon: Icon(active
                          ? Icons.sports_score_rounded
                          : Icons.sports_rounded),
                      label: Text(active
                          ? 'Disponível • ${myAvail.sport}'
                          : 'Quero jogar'),
                      onPressed: () => _toggleAvailability(ref, active),
                    );
                  },
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

  /// Opens the same "Quero jogar" sheet used on the Explore tab when
  /// currently inactive, or removes the availability when active.
  /// `myAvailabilityProvider` is the shared source of truth so both
  /// the Explore card and this FAB stay in sync.
  Future<void> _toggleAvailability(WidgetRef ref, bool active) async {
    if (active) {
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(sportsRepositoryProvider).removeAvailability();
      await ref
          .read(socialRepositoryProvider)
          .setVisibleOnMap(visible: false);
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Você não está mais disponível.')));
    } else {
      await showMarkAvailabilityAndApply(context, ref);
    }
  }

  void _centerOnUser() {
    final target = _fallbackCenter();
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sem GPS nem endereço fixo. Cadastre seu endereço no perfil.'),
        ),
      );
      return;
    }
    _mapController.move(target, 15.0);
  }

  void _enterPinMode() {
    final center = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _mapController.camera.center;
    setState(() {
      _pinPosition = center;
      _pinAddress = null;
      _reverseGeocoding = false;
      _pinMode = true;
    });
    _reverseGeocode(center);
  }

  Future<void> _confirmPin() async {
    _revGeoDebounce?.cancel();
    // Pass the reverse-geocoded address to AddVenueScreen as the
    // initial value, then clear local state.
    final pinAddress = _pinAddress;
    setState(() {
      _pinMode = false;
      _pinAddress = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final ok = await AppNavigator.pushWithNavBar<bool>(
      context,
      AddVenueScreen(
        userLat: _pinPosition.latitude,
        userLng: _pinPosition.longitude,
        initialAddress: pinAddress,
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

  void _animateTo(LatLng pos, {double zoom = 16.0}) {
    _mapController.move(pos, zoom);
  }

  void _showVenueSheet(BuildContext context, SportsVenueModel v) {
    final dist = _userPosition == null
        ? null
        : GeoUtils.distanceKm(_userPosition!.latitude,
            _userPosition!.longitude, v.lat, v.lng);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          _sportColor(v.sport).withValues(alpha: 0.2),
                      child: Icon(_sportIcon(v.sport),
                          color: _sportColor(v.sport)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${v.sport}${dist != null ? ' • ${GeoUtils.formatDistance(dist)}' : ''}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (v.address != null && v.address!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(v.address!,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _animateTo(LatLng(v.lat, v.lng));
                        },
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text('Centralizar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          AppNavigator.pushWithNavBar(
                            context,
                            VenueDetailScreen(
                              venue: v,
                              userLat: _userPosition?.latitude,
                              userLng: _userPosition?.longitude,
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('Detalhes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUserSheet(BuildContext context, UserModel user) {
    final center = _fallbackCenter();
    final dist = (center == null ||
            user.effectiveLat == null ||
            user.effectiveLng == null)
        ? null
        : GeoUtils.distanceKm(center.latitude, center.longitude,
            user.effectiveLat!, user.effectiveLng!);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final name = user.name ?? 'Usuário';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: user.photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: theme.textTheme.titleLarge,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_user_rounded,
                          size: 16, color: Colors.amber.shade700),
                    ] else if (user.isPremium) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.workspace_premium_rounded,
                          size: 16, color: Colors.amber.shade600),
                    ] else if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded,
                          size: 16, color: Colors.blue.shade400),
                    ],
                  ],
                ),
                if (dist != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      GeoUtils.formatDistance(dist),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (user.effectiveLat != null) {
                            _animateTo(LatLng(
                                user.effectiveLat!, user.effectiveLng!));
                          }
                        },
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text('Centralizar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          AppNavigator.pushWithNavBar(context,
                              UserProfileScreen(userId: user.id));
                        },
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Perfil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _animateTo(LatLng(player.lat, player.lng));
                        },
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text('Centralizar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
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
                                    chatId: conv.id,
                                    conv: conv,
                                    myUid: myUid),
                              );
                            }
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text('Mensagem'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlayersListSheet(
      BuildContext context, List<PlayerAvailabilityModel> players) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => _PlayersListSheet(
        players: players,
        userLat: _userPosition?.latitude,
        userLng: _userPosition?.longitude,
        onCenterOnMap: (p) {
          Navigator.of(sheetCtx).pop();
          _animateTo(LatLng(p.lat, p.lng));
        },
      ),
    );
  }

  void _showVenuesListSheet(
      BuildContext context, List<SportsVenueModel> venues) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => _VenuesListSheet(
        venues: venues,
        userLat: _userPosition?.latitude,
        userLng: _userPosition?.longitude,
        onTapVenue: (v) {
          Navigator.of(sheetCtx).pop();
          _animateTo(LatLng(v.lat, v.lng));
          // Open the venue summary sheet so user can see details / centralize.
          _showVenueSheet(context, v);
        },
      ),
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

/// Marker for users who opted into `visibleOnMap` but did not mark
/// "querem jogar hoje". Smaller and grayer than the active-player marker
/// to keep visual hierarchy: active players > regular visible users.
class _UserMarker extends StatelessWidget {
  final UserModel user;
  const _UserMarker({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = user.isVerified
        ? Colors.blue.shade400
        : (user.isPremium ? Colors.amber.shade700 : cs.outline);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: user.photoUrl != null
          ? ClipOval(
              child: Image.network(user.photoUrl!,
                  fit: BoxFit.cover, width: 40, height: 40),
            )
          : Icon(Icons.person_outline_rounded, color: color, size: 20),
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

// ─── Counter chip ───────────────────────────────────────────────────────────

/// 3-way segmented toggle that controls whether the map shows venues,
/// players, or both. Renders compact pill icons in the top-right.
class _MapDisplayToggle extends StatelessWidget {
  final _MapDisplayMode mode;
  final ValueChanged<_MapDisplayMode> onChanged;

  const _MapDisplayToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget pill(_MapDisplayMode m, IconData icon, String tip) {
      final selected = mode == m;
      return Tooltip(
        message: tip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(m),
          child: Container(
            width: 36,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon,
                size: 18,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            pill(_MapDisplayMode.all, Icons.layers_rounded, 'Mostrar tudo'),
            pill(_MapDisplayMode.venues, Icons.place_rounded, 'Só quadras'),
            pill(_MapDisplayMode.fixedUsers, Icons.people_alt_rounded,
                'Locais fixos de usuários'),
            pill(_MapDisplayMode.players, Icons.sports_score_rounded,
                'Querem jogar hoje'),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _CountChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Players list sheet (multi-select + group chat creator) ────────────────

class _PlayersListSheet extends ConsumerStatefulWidget {
  final List<PlayerAvailabilityModel> players;
  final double? userLat;
  final double? userLng;
  final ValueChanged<PlayerAvailabilityModel>? onCenterOnMap;

  const _PlayersListSheet({
    required this.players,
    this.userLat,
    this.userLng,
    this.onCenterOnMap,
  });

  @override
  ConsumerState<_PlayersListSheet> createState() =>
      _PlayersListSheetState();
}

class _PlayersListSheetState extends ConsumerState<_PlayersListSheet> {
  final Set<String> _selected = {};
  final TextEditingController _groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  bool get _isSelectMode => _selected.isNotEmpty;

  void _toggle(String uid) {
    setState(() {
      if (_selected.contains(uid)) {
        _selected.remove(uid);
      } else {
        _selected.add(uid);
      }
    });
  }

  Future<void> _openSingleChat(PlayerAvailabilityModel p) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final outerCtx = context;
    final messenger = ScaffoldMessenger.of(outerCtx);
    try {
      final conv =
          await ref.read(chatRepositoryProvider).getOrCreateConversation(
                otherUid: p.userId,
                otherName: p.userName,
                otherPhoto: p.userPhotoUrl,
              );
      if (!outerCtx.mounted) return;
      Navigator.of(outerCtx).pop();
      AppNavigator.pushWithNavBar(
        outerCtx,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _createGroup() async {
    final messenger = ScaffoldMessenger.of(context);
    final outerCtx = context;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Hydrate UserModels for selected uids from the player list.
    final selectedPlayers = widget.players
        .where((p) => _selected.contains(p.userId))
        .toList();
    final members = selectedPlayers
        .map((p) => UserModel(
              id: p.userId,
              email: '',
              name: p.userName,
              photoUrl: p.userPhotoUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .toList();
    try {
      final name = _groupNameCtrl.text.trim();
      final conv = await ref.read(chatRepositoryProvider).createGroupChat(
            members: members,
            groupName: name.isEmpty ? null : name,
          );
      if (!outerCtx.mounted) return;
      Navigator.of(outerCtx).pop();
      AppNavigator.pushWithNavBar(
        outerCtx,
        ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final me = ref.watch(currentUserProvider).valueOrNull;
    final blocked = me?.blockedUsers ?? const <String>[];
    final visible = widget.players
        .where((p) => !blocked.contains(p.userId))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_alt_rounded, color: cs.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSelectMode
                        ? '${_selected.length} selecionado(s)'
                        : 'Jogadores na área (${visible.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isSelectMode)
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Limpar'),
                  ),
              ],
            ),
            if (!_isSelectMode)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'Toque para conversar · segure para selecionar e criar grupo.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            const Divider(height: 16),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text('Ninguém por perto agora.',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 76),
                      itemBuilder: (_, i) {
                        final p = visible[i];
                        final selected = _selected.contains(p.userId);
                        final dist = (widget.userLat == null ||
                                widget.userLng == null)
                            ? null
                            : GeoUtils.distanceKm(widget.userLat!,
                                widget.userLng!, p.lat, p.lng);
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: p.userPhotoUrl != null
                                    ? NetworkImage(p.userPhotoUrl!)
                                    : null,
                                backgroundColor: cs.primaryContainer,
                                child: p.userPhotoUrl == null
                                    ? Text(p.userName.isNotEmpty
                                        ? p.userName[0].toUpperCase()
                                        : '?')
                                    : null,
                              ),
                              if (selected)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: cs.surface, width: 2),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(Icons.check,
                                        size: 12, color: cs.onPrimary),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(p.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${p.sport}${dist != null ? ' • ${GeoUtils.formatDistance(dist)}' : ''}',
                          ),
                          trailing: _isSelectMode
                              ? null
                              : (widget.onCenterOnMap != null
                                  ? IconButton(
                                      icon: const Icon(
                                          Icons.center_focus_strong_rounded),
                                      tooltip: 'Centralizar no mapa',
                                      onPressed: () =>
                                          widget.onCenterOnMap!(p),
                                    )
                                  : null),
                          onTap: _isSelectMode
                              ? () => _toggle(p.userId)
                              : () => _openSingleChat(p),
                          onLongPress: () => _toggle(p.userId),
                          selected: selected,
                          selectedTileColor:
                              cs.primaryContainer.withValues(alpha: 0.3),
                        );
                      },
                    ),
            ),
            if (_isSelectMode)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    0, 8, 0, MediaQuery.of(context).viewInsets.bottom + 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _groupNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do grupo (opcional)',
                        prefixIcon: Icon(Icons.group_rounded),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _createGroup,
                      icon: const Icon(Icons.chat_rounded),
                      label: Text(
                        _selected.length == 1
                            ? 'Conversar com 1 jogador'
                            : 'Criar grupo (${_selected.length})',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Venues list sheet ─────────────────────────────────────────────────────

class _VenuesListSheet extends StatelessWidget {
  final List<SportsVenueModel> venues;
  final double? userLat;
  final double? userLng;
  final ValueChanged<SportsVenueModel> onTapVenue;

  const _VenuesListSheet({
    required this.venues,
    required this.onTapVenue,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sorted = [...venues];
    if (userLat != null && userLng != null) {
      sorted.sort((a, b) {
        final da = GeoUtils.distanceKm(userLat!, userLng!, a.lat, a.lng);
        final db = GeoUtils.distanceKm(userLat!, userLng!, b.lat, b.lng);
        return da.compareTo(db);
      });
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Quadras na área (${sorted.length})',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            Expanded(
              child: sorted.isEmpty
                  ? Center(
                      child: Text('Nenhuma quadra cadastrada por perto.',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 60),
                      itemBuilder: (_, i) {
                        final v = sorted[i];
                        final dist = (userLat == null || userLng == null)
                            ? null
                            : GeoUtils.distanceKm(
                                userLat!, userLng!, v.lat, v.lng);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _sportColor(v.sport).withValues(alpha: 0.2),
                            child: Icon(_sportIcon(v.sport),
                                color: _sportColor(v.sport), size: 20),
                          ),
                          title: Text(v.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${v.sport}${dist != null ? ' • ${GeoUtils.formatDistance(dist)}' : ''}',
                          ),
                          trailing: const Icon(
                              Icons.chevron_right_rounded),
                          onTap: () => onTapVenue(v),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

