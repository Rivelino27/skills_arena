import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../models/player_availability_model.dart';
import '../models/sports_venue_model.dart';

final sportsRepositoryProvider = Provider<SportsRepository>((ref) {
  return SportsRepository(firestore: FirebaseFirestore.instance);
});

class SportsRepository {
  final FirebaseFirestore _db;

  SportsRepository({required FirebaseFirestore firestore}) : _db = firestore;

  CollectionReference<Map<String, dynamic>> get _venues =>
      _db.collection('sports_venues');

  CollectionReference<Map<String, dynamic>> get _availability =>
      _db.collection('player_availability');

  // ─── Quadras ───────────────────────────────────────────────────────────────

  Stream<List<SportsVenueModel>> venuesStream() => _venues
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SportsVenueModel.fromFirestore).toList());

  Future<Either<AppFailure, Unit>> addVenue(SportsVenueModel venue) async {
    try {
      await _venues.add(venue.toMap());
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao adicionar quadra.'));
    }
  }

  /// Any signed-in user can update the live occupancy + timestamp.
  /// Permission to write only the three fields is enforced by Firestore rules.
  Future<Either<AppFailure, Unit>> updateOccupancy({
    required String venueId,
    required VenueOccupancy occupancy,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Usuário não autenticado.'));
      }
      await _venues.doc(venueId).update({
        'occupancy': occupancy.storageKey,
        'occupancyUpdatedAt': Timestamp.now(),
        'occupancyUpdatedBy': user.uid,
      });
      return const Right(unit);
    } catch (e) {
      return const Left(
          ServerFailure(message: 'Erro ao atualizar status da quadra.'));
    }
  }

  // ─── Disponibilidade de Jogadores ──────────────────────────────────────────

  Stream<List<PlayerAvailabilityModel>> availabilityStream() => _availability
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .snapshots()
      .map((s) => s.docs.map(PlayerAvailabilityModel.fromFirestore).toList());

  Future<Either<AppFailure, Unit>> markAvailability({
    required String sport,
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Usuário não autenticado.'));
      }
      // Remove disponibilidade anterior do mesmo usuário
      final existing =
          await _availability.where('userId', isEqualTo: user.uid).get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      final now = DateTime.now();
      final model = PlayerAvailabilityModel(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'Usuário',
        userPhotoUrl: user.photoURL,
        sport: sport,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        expiresAt: now.add(const Duration(hours: 24)),
        createdAt: now,
      );
      await _availability.add(model.toMap());
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao marcar disponibilidade.'));
    }
  }

  Future<Either<AppFailure, Unit>> removeAvailability() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Usuário não autenticado.'));
      }
      final existing =
          await _availability.where('userId', isEqualTo: user.uid).get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<PlayerAvailabilityModel?> myAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap = await _availability
        .where('userId', isEqualTo: user.uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PlayerAvailabilityModel.fromFirestore(snap.docs.first);
  }
}
