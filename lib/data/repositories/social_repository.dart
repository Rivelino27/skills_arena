import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

/// Hard cap on saved addresses per user. Anything above this rejects.
const int kMaxSavedAddresses = 20;

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(firestore: FirebaseFirestore.instance);
});

class SocialRepository {
  final FirebaseFirestore _db;

  SocialRepository({required FirebaseFirestore firestore}) : _db = firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> blockUser(String otherUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await _userDoc(me.uid).update({
      'blockedUsers': FieldValue.arrayUnion([otherUid]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> unblockUser(String otherUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await _userDoc(me.uid).update({
      'blockedUsers': FieldValue.arrayRemove([otherUid]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Persists the user's fixed home/work address (display + coordinates).
  /// Pass nulls to clear it.
  Future<void> setFixedAddress({
    String? address,
    double? lat,
    double? lng,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await _userDoc(me.uid).update({
      'address': address,
      'addressLat': lat,
      'addressLng': lng,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Adds a new entry to the user's address book. Throws if the book
  /// already has [kMaxSavedAddresses] entries. If the user didn't have a
  /// fixed address yet, the new one becomes active automatically.
  Future<SavedAddress> addSavedAddress({
    required String label,
    required String address,
    required double lat,
    required double lng,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) throw Exception('Não autenticado.');

    return _db.runTransaction((tx) async {
      final ref = _userDoc(me.uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final rawList = (data['addresses'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (rawList.length >= kMaxSavedAddresses) {
        throw Exception('Limite de $kMaxSavedAddresses endereços atingido.');
      }
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final entry = SavedAddress(
        id: id,
        label: label.trim().isEmpty ? 'Endereço' : label.trim(),
        address: address,
        lat: lat,
        lng: lng,
      );
      rawList.add(entry.toMap());
      final patch = <String, dynamic>{
        'addresses': rawList,
        'updatedAt': Timestamp.now(),
      };
      // Auto-activate if no active address yet.
      if ((data['activeAddressId'] as String?) == null) {
        patch['activeAddressId'] = id;
        patch['address'] = address;
        patch['addressLat'] = lat;
        patch['addressLng'] = lng;
      }
      tx.update(ref, patch);
      return entry;
    });
  }

  /// Removes a saved address by id. If it was the active one, picks the
  /// first remaining (or clears the legacy fields when none are left).
  Future<void> removeSavedAddress(String addressId) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await _db.runTransaction((tx) async {
      final ref = _userDoc(me.uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final rawList = (data['addresses'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      rawList.removeWhere((m) => m['id'] == addressId);
      final wasActive = (data['activeAddressId'] as String?) == addressId;
      final patch = <String, dynamic>{
        'addresses': rawList,
        'updatedAt': Timestamp.now(),
      };
      if (wasActive) {
        if (rawList.isEmpty) {
          patch['activeAddressId'] = null;
          patch['address'] = null;
          patch['addressLat'] = null;
          patch['addressLng'] = null;
        } else {
          final next = rawList.first;
          patch['activeAddressId'] = next['id'];
          patch['address'] = next['address'];
          patch['addressLat'] = next['lat'];
          patch['addressLng'] = next['lng'];
        }
      }
      tx.update(ref, patch);
    });
  }

  /// Switches the active address to [addressId] and mirrors its
  /// coordinates into the legacy fields.
  Future<void> setActiveAddress(String addressId) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    await _db.runTransaction((tx) async {
      final ref = _userDoc(me.uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final rawList = (data['addresses'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final target = rawList.firstWhere(
        (m) => m['id'] == addressId,
        orElse: () => const {},
      );
      if (target.isEmpty) return;
      tx.update(ref, {
        'activeAddressId': addressId,
        'address': target['address'],
        'addressLat': target['lat'],
        'addressLng': target['lng'],
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Follows / unfollows another user in a single transaction, keeping
  /// the target's `followersCount` in sync. No-op when targeting self.
  Future<void> toggleFollow(String otherUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid == otherUid) return;
    final myRef = _userDoc(me.uid);
    final otherRef = _userDoc(otherUid);
    await _db.runTransaction((tx) async {
      final mySnap = await tx.get(myRef);
      final following =
          List<String>.from(mySnap.data()?['following'] as List? ?? []);
      final isFollowing = following.contains(otherUid);
      if (isFollowing) {
        tx.update(myRef, {
          'following': FieldValue.arrayRemove([otherUid]),
          'updatedAt': Timestamp.now(),
        });
        tx.update(otherRef, {
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        tx.update(myRef, {
          'following': FieldValue.arrayUnion([otherUid]),
          'updatedAt': Timestamp.now(),
        });
        tx.update(otherRef, {
          'followersCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> setVisibleOnMap({
    required bool visible,
    double? lat,
    double? lng,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final patch = <String, dynamic>{
      'visibleOnMap': visible,
      'updatedAt': Timestamp.now(),
    };
    if (visible && lat != null && lng != null) {
      patch['lastLat'] = lat;
      patch['lastLng'] = lng;
    }
    await _userDoc(me.uid).update(patch);
  }

  /// Returns whether `otherUid` blocked `myUid` OR `myUid` blocked `otherUid`.
  Future<bool> isBlockedEitherWay({
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final results = await Future.wait([
        _userDoc(myUid).get(),
        _userDoc(otherUid).get(),
      ]);
      final me = results[0].data();
      final other = results[1].data();
      final iBlocked =
          List<String>.from(me?['blockedUsers'] as List? ?? []);
      final theyBlocked =
          List<String>.from(other?['blockedUsers'] as List? ?? []);
      return iBlocked.contains(otherUid) || theyBlocked.contains(myUid);
    } catch (_) {
      return false;
    }
  }

  /// Stream of users who opted in to `visibleOnMap = true`.
  Stream<List<UserModel>> visibleUsersStream({int limit = 300}) => _db
      .collection('users')
      .where('visibleOnMap', isEqualTo: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());

  /// Top users ordered by followersCount desc. Used by the global
  /// ranking screen. Requires a Firestore index on `followersCount`
  /// (Firestore auto-creates the single-field index by default).
  Stream<List<UserModel>> topUsersByFollowersStream({int limit = 100}) => _db
      .collection('users')
      .orderBy('followersCount', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
}
