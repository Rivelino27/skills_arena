import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../providers/sports_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/verified_badge.dart';
import 'map_screen.dart';
import 'venue_detail_screen.dart';

/// Direct list of venues sorted by distance from the user.
/// Tap → centers the map on that venue.
class FindVenuesScreen extends ConsumerStatefulWidget {
  final double? userLat;
  final double? userLng;

  const FindVenuesScreen({super.key, this.userLat, this.userLng});

  @override
  ConsumerState<FindVenuesScreen> createState() => _FindVenuesScreenState();
}

class _FindVenuesScreenState extends ConsumerState<FindVenuesScreen> {
  String? _sportFilter;
  bool _verifiedOnly = false;

  @override
  Widget build(BuildContext context) {
    final allVenues = ref.watch(venuesStreamProvider).valueOrNull ?? [];
    final me = ref.watch(currentUserProvider).valueOrNull;
    final lat = widget.userLat ?? me?.effectiveLat;
    final lng = widget.userLng ?? me?.effectiveLng;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final venues = allVenues.where((v) {
      if (_sportFilter != null && v.sport != _sportFilter) return false;
      if (_verifiedOnly && !v.isVerified) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        if (lat == null || lng == null) return a.name.compareTo(b.name);
        final da = GeoUtils.distanceKm(lat, lng, a.lat, a.lng);
        final db = GeoUtils.distanceKm(lat, lng, b.lat, b.lng);
        return da.compareTo(db);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Quadras / Locais')),
      body: Column(
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(Icons.verified_rounded,
                        size: 16, color: Colors.blue.shade400),
                    label: const Text('Apenas verificadas'),
                    selected: _verifiedOnly,
                    onSelected: (v) =>
                        setState(() => _verifiedOnly = v),
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
                Icon(Icons.place_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  '${venues.length} quadra${venues.length == 1 ? '' : 's'} encontrada${venues.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: venues.isEmpty
                ? _Empty(sport: _sportFilter)
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: venues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _VenueTile(
                      venue: venues[i],
                      userLat: lat,
                      userLng: lng,
                      onOpenMap: () => _openMap(venues[i]),
                      onOpenDetail: () => _openDetail(venues[i], lat, lng),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openMap(SportsVenueModel v) {
    AppNavigator.pushWithNavBar(
      context,
      MapScreen(
        initialLat: v.lat,
        initialLng: v.lng,
        initialZoom: 16.0,
        initialSportFilter: v.sport,
      ),
    );
  }

  void _openDetail(SportsVenueModel v, double? lat, double? lng) {
    AppNavigator.pushWithNavBar(
      context,
      VenueDetailScreen(venue: v, userLat: lat, userLng: lng),
    );
  }
}

class _VenueTile extends StatelessWidget {
  final SportsVenueModel venue;
  final double? userLat;
  final double? userLng;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenDetail;

  const _VenueTile({
    required this.venue,
    required this.onOpenMap,
    required this.onOpenDetail,
    this.userLat,
    this.userLng,
  });

  Color _occColor(VenueOccupancy o) {
    switch (o) {
      case VenueOccupancy.empty:
        return Colors.green;
      case VenueOccupancy.few:
        return Colors.orange;
      case VenueOccupancy.full:
        return Colors.red;
      case VenueOccupancy.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dist = (userLat == null || userLng == null)
        ? null
        : GeoUtils.distanceKm(userLat!, userLng!, venue.lat, venue.lng);

    final occLabel = venue.occupancy == VenueOccupancy.unknown
        ? null
        : venue.occupancy.label;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(
            venue.isPublic
                ? Icons.public_rounded
                : Icons.lock_outline_rounded,
            color: cs.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(venue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (venue.isVerified) ...[
              const SizedBox(width: 4),
              const VerifiedBadge(size: 14),
            ],
            if (occLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _occColor(venue.occupancy)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  occLabel,
                  style: TextStyle(
                    color: _occColor(venue.occupancy),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${venue.sport} • ${venue.isPublic ? 'Público' : 'Privado'}'
          '${dist != null ? ' • ${GeoUtils.formatDistance(dist)}' : ''}'
          '${venue.address != null && venue.address!.isNotEmpty ? '\n${venue.address!}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine:
            venue.address != null && venue.address!.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.map_rounded),
              tooltip: 'Ver no mapa',
              onPressed: onOpenMap,
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onOpenDetail,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String? sport;
  const _Empty({this.sport});

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
            Icon(Icons.place_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              sport != null
                  ? 'Nenhuma quadra de $sport cadastrada'
                  : 'Nenhuma quadra cadastrada',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione a primeira pelo mapa.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
