import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

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
  Stream<List<UserModel>> visibleUsersStream() => _db
      .collection('users')
      .where('visibleOnMap', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
}
