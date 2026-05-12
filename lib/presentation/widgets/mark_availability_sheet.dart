import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/navigation/app_navigator.dart';
import '../../data/models/sports_venue_model.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/sports_repository.dart';
import '../providers/user_provider.dart';
import '../screens/profile/edit_address_screen.dart';

/// Sport + location + radius + duration selection sheet for "Quero
/// jogar hoje". Shared by ExploreScreen card and MapScreen FAB.
class MarkAvailabilitySheet extends ConsumerStatefulWidget {
  const MarkAvailabilitySheet({super.key});

  @override
  ConsumerState<MarkAvailabilitySheet> createState() =>
      _MarkAvailabilitySheetState();
}

class MarkResult {
  final String sport;
  final double lat;
  final double lng;
  final double radiusKm;
  final int durationHours;
  const MarkResult(
      this.sport, this.lat, this.lng, this.radiusKm, this.durationHours);
}

/// Top-level helper: open the sheet, persist the availability, and
/// flip `visibleOnMap` to true (so the user shows up on the map). Both
/// the Explore card and the Map FAB call this so the flows stay in sync.
Future<bool> showMarkAvailabilityAndApply(
    BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await showModalBottomSheet<MarkResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const MarkAvailabilitySheet(),
  );
  if (result == null) return false;
  final res = await ref.read(sportsRepositoryProvider).markAvailability(
        sport: result.sport,
        lat: result.lat,
        lng: result.lng,
        radiusKm: result.radiusKm,
        duration: Duration(hours: result.durationHours),
      );
  return res.fold(
    (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
      return false;
    },
    (_) async {
      await ref.read(socialRepositoryProvider).setVisibleOnMap(
            visible: true,
            lat: result.lat,
            lng: result.lng,
          );
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Disponibilidade ativada por ${result.durationHours}h.')),
      );
      return true;
    },
  );
}

class _MarkAvailabilitySheetState
    extends ConsumerState<MarkAvailabilitySheet> {
  String _sport = kSportsList.first;
  double _radius = 5;
  int _durationHours = 5;
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
      messenger.showSnackBar(SnackBar(content: Text('Erro no GPS: $e')));
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
    await AppNavigator.pushWithNavBar(context, const EditAddressScreen());
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
              subtitle:
                  const Text('Buscar e salvar um endereço personalizado'),
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
            'Sua disponibilidade ficará visível dentro do raio escolhido. '
            'Você também aparece no mapa enquanto estiver ativa.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
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
                  onPressed:
                      _gettingGps ? null : _showLocationSourceSheet,
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule_rounded),
              const SizedBox(width: 8),
              Text('Disponível por: ${_durationHours}h',
                  style: theme.textTheme.bodyLarge),
            ],
          ),
          Slider(
            value: _durationHours.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            label: '${_durationHours}h',
            onChanged: (v) => setState(() => _durationHours = v.round()),
          ),
          Wrap(
            spacing: 8,
            children: const [2, 5, 8, 12]
                .map((h) => ChoiceChip(
                      label: Text('${h}h'),
                      selected: _durationHours == h,
                      onSelected: (_) =>
                          setState(() => _durationHours = h),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                MarkResult(_sport, lat, lng, _radius, _durationHours),
              );
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
