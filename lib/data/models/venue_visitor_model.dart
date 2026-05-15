import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's history of visits to a venue.
/// Counted once per 4-hour window to limit spam-tapping the check-in
/// button. Used by the "Hall da Fama" + "Visitantes" section of the
/// venue detail screen.
class VenueVisitorModel {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int visitCount;
  final DateTime firstVisitAt;
  final DateTime lastVisitAt;

  const VenueVisitorModel({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.visitCount,
    required this.firstVisitAt,
    required this.lastVisitAt,
  });

  factory VenueVisitorModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VenueVisitorModel(
      userId: d['userId'] as String? ?? doc.id,
      userName: d['userName'] as String? ?? 'Usuário',
      userPhotoUrl: d['userPhotoUrl'] as String?,
      visitCount: (d['visitCount'] as num?)?.toInt() ?? 1,
      firstVisitAt:
          (d['firstVisitAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastVisitAt:
          (d['lastVisitAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
