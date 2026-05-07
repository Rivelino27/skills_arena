import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? username;
  final String? photoUrl;
  final bool isPremium;
  final bool searchableByEmail;
  final List<String> blockedUsers;
  final bool visibleOnMap;
  final double? lastLat;
  final double? lastLng;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.username,
    this.photoUrl,
    this.isPremium = false,
    this.searchableByEmail = true,
    this.blockedUsers = const [],
    this.visibleOnMap = false,
    this.lastLat,
    this.lastLng,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      name: data['name'] as String?,
      username: data['username'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      searchableByEmail: data['searchableByEmail'] as bool? ?? true,
      blockedUsers: List<String>.from(data['blockedUsers'] as List? ?? []),
      visibleOnMap: data['visibleOnMap'] as bool? ?? false,
      lastLat: (data['lastLat'] as num?)?.toDouble(),
      lastLng: (data['lastLng'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'username': username,
        'photoUrl': photoUrl,
        'isPremium': isPremium,
        'searchableByEmail': searchableByEmail,
        'blockedUsers': blockedUsers,
        'visibleOnMap': visibleOnMap,
        'lastLat': lastLat,
        'lastLng': lastLng,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  bool hasBlocked(String otherUid) => blockedUsers.contains(otherUid);

  UserModel copyWith({
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    bool? isPremium,
    bool? searchableByEmail,
    List<String>? blockedUsers,
    bool? visibleOnMap,
    double? lastLat,
    double? lastLng,
  }) =>
      UserModel(
        id: id,
        email: email ?? this.email,
        name: name ?? this.name,
        username: username ?? this.username,
        photoUrl: photoUrl ?? this.photoUrl,
        isPremium: isPremium ?? this.isPremium,
        searchableByEmail: searchableByEmail ?? this.searchableByEmail,
        blockedUsers: blockedUsers ?? this.blockedUsers,
        visibleOnMap: visibleOnMap ?? this.visibleOnMap,
        lastLat: lastLat ?? this.lastLat,
        lastLng: lastLng ?? this.lastLng,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
