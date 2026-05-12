import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/player_availability_model.dart';
import '../../data/models/sports_venue_model.dart';
import '../../data/models/venue_attendance_model.dart';
import '../../data/repositories/sports_repository.dart';

final venuesStreamProvider = StreamProvider<List<SportsVenueModel>>((ref) {
  return ref.watch(sportsRepositoryProvider).venuesStream();
});

final availabilityStreamProvider =
    StreamProvider<List<PlayerAvailabilityModel>>((ref) {
  return ref.watch(sportsRepositoryProvider).availabilityStream();
});

/// My active "quero jogar" availability (null when expired or not set).
final myAvailabilityProvider =
    StreamProvider<PlayerAvailabilityModel?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('player_availability')
      .where('userId', isEqualTo: uid)
      .limit(1)
      .snapshots()
      .map((s) {
    if (s.docs.isEmpty) return null;
    final m = PlayerAvailabilityModel.fromFirestore(s.docs.first);
    return m.isActive ? m : null;
  });
});

/// Live attendance for a given venue (only docs where endAt > now).
final venueAttendanceProvider =
    StreamProvider.family<List<VenueAttendanceModel>, String>(
  (ref, venueId) =>
      ref.watch(sportsRepositoryProvider).attendanceStream(venueId),
);

/// Filtro de esporte selecionado, compartilhado entre Explorar e Mapa.
/// Persistido em `SharedPreferences` para sobreviver a restart do app.
/// `null` = "Todos" (sem filtro).
final selectedSportFilterProvider =
    StateNotifierProvider<SportFilterNotifier, String?>(
  (ref) => SportFilterNotifier(),
);

class SportFilterNotifier extends StateNotifier<String?> {
  SportFilterNotifier() : super(null) {
    _load();
  }

  static const _key = 'selected_sport_filter';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      if (v != null && v.isNotEmpty) state = v;
    } catch (_) {/* keep default null */}
  }

  Future<void> setSport(String? sport) async {
    state = sport;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (sport == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, sport);
      }
    } catch (_) {/* state is set, persistence is best-effort */}
  }
}

/// Raio de busca em km (padrão 5 km).
final mapRadiusProvider = StateProvider<double>((ref) => 5.0);

/// Toggle de "busca global" no mapa — ignora o raio quando ativo e
/// mostra tudo na região visível (otimizado pelo debounce). Útil quando
/// o usuário não encontra muita coisa no raio padrão.
final globalSearchProvider = StateProvider<bool>((ref) => false);
