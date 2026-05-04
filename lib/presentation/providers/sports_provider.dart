import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_availability_model.dart';
import '../../data/models/sports_venue_model.dart';
import '../../data/repositories/sports_repository.dart';

final venuesStreamProvider = StreamProvider<List<SportsVenueModel>>((ref) {
  return ref.watch(sportsRepositoryProvider).venuesStream();
});

final availabilityStreamProvider =
    StreamProvider<List<PlayerAvailabilityModel>>((ref) {
  return ref.watch(sportsRepositoryProvider).availabilityStream();
});

/// Filtro de esporte selecionado no mapa (null = todos).
final selectedSportFilterProvider = StateProvider<String?>((ref) => null);

/// Raio de busca em km (padrão 5 km).
final mapRadiusProvider = StateProvider<double>((ref) => 5.0);
