import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerAvailabilityModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String sport;
  final double lat;
  final double lng;
  final double radiusKm;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PlayerAvailabilityModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.sport,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  factory PlayerAvailabilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerAvailabilityModel(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      sport: data['sport'] as String,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      radiusKm: (data['radiusKm'] as num).toDouble(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'sport': sport,
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
