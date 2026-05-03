class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final String? sport; // futebol, basquete, etc.
  final bool isPremium;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.sport,
    this.isPremium = false,
    this.isAdmin = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      sport: map['sport'],
      isPremium: map['isPremium'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'sport': sport,
        'isPremium': isPremium,
        'isAdmin': isAdmin,
      };
}