import 'package:flutter/material.dart';

import '../../../core/utils/geo_utils.dart';
import '../../../data/models/sports_venue_model.dart';
import '../../widgets/navigation/custom_back_button.dart';

/// Detalhe da quadra — sem bottom nav bar (exemplo de pushWithoutNavBar).
/// Demonstra: CustomBackButton + PopScope interceptando gesto de voltar.
class VenueDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dist = (userLat == null || userLng == null)
        ? null
        : GeoUtils.distanceKm(userLat!, userLng!, venue.lat, venue.lng);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: CustomBackButton(
            options: [
              BackMenuOption(
                icon: Icons.map_rounded,
                label: 'Voltar ao mapa',
                subtitle: 'Fecha este detalhe',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          title: Text(venue.name),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Hero icon
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_rounded,
                  size: 48,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              venue.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Center(
              child: Chip(
                label: Text(venue.sport),
                avatar: const Icon(Icons.sports_rounded, size: 16),
                backgroundColor: cs.primaryContainer,
                labelStyle:
                    TextStyle(color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 24),
            _InfoTile(
              icon: Icons.location_on_rounded,
              label: 'Coordenadas',
              value: '${venue.lat.toStringAsFixed(5)}, '
                  '${venue.lng.toStringAsFixed(5)}',
            ),
            if (venue.address != null)
              _InfoTile(
                icon: Icons.home_outlined,
                label: 'Endereço',
                value: venue.address!,
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
              value: venue.addedByName,
            ),
            _InfoTile(
              icon: Icons.calendar_today_rounded,
              label: 'Data',
              value:
                  '${venue.createdAt.day.toString().padLeft(2, '0')}/'
                  '${venue.createdAt.month.toString().padLeft(2, '0')}/'
                  '${venue.createdAt.year}',
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar ao mapa'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBack(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
              title: const Text('Voltar'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.map_rounded, size: 18)),
              title: const Text('Ir para o mapa'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

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
