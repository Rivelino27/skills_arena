import 'package:cloud_firestore/cloud_firestore.dart';

/// One user's commitment to be at a specific venue between [startAt] and
/// [endAt]. Stored in the top-level `venue_attendance` collection.
class VenueAttendanceModel {
  final String id;
  final String venueId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;

  const VenueAttendanceModel({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
  });

  /// Active = endAt is still in the future (or right now).
  bool get isActive => endAt.isAfter(DateTime.now());

  Duration get duration => endAt.difference(startAt);

  factory VenueAttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VenueAttendanceModel(
      id: doc.id,
      venueId: d['venueId'] as String,
      userId: d['userId'] as String,
      userName: d['userName'] as String? ?? 'Usuário',
      userPhotoUrl: d['userPhotoUrl'] as String?,
      startAt: (d['startAt'] as Timestamp).toDate(),
      endAt: (d['endAt'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'venueId': venueId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
