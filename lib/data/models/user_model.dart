import 'package:cloud_firestore/cloud_firestore.dart';

import 'player_card.dart';

/// One saved search address. Users can keep up to 20 of these (Casa,
/// Trabalho, Faculdade…) and switch the active one to change where their
/// map searches are anchored. The active one mirrors into the legacy
/// `address` / `addressLat` / `addressLng` fields for compatibility.
class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
      };

  factory SavedAddress.fromMap(Map<String, dynamic> m) => SavedAddress(
        id: m['id'] as String,
        label: m['label'] as String? ?? '',
        address: m['address'] as String? ?? '',
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
}

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? username;
  final String? photoUrl;
  final bool isPremium;
  final bool isAdmin;
  /// Verified by an admin (separate from premium/admin). Used to filter
  /// "Apenas verificados" in user search.
  final bool isVerified;
  /// Average user rating (0–5). `null` means "not rated yet".
  /// Set externally — currently no in-app rating UI; promote/seed via
  /// Firestore console or a future feedback flow.
  final double? rating;
  final int ratingCount;
  final bool searchableByEmail;
  final List<String> blockedUsers;
  final List<String> following;
  final int followersCount;
  final bool visibleOnMap;
  final double? lastLat;
  final double? lastLng;
  final String? address;
  final double? addressLat;
  final double? addressLng;
  /// Saved address book (up to 20 entries). The active one is mirrored
  /// into [address] / [addressLat] / [addressLng] so existing code that
  /// reads those fields keeps working.
  final List<SavedAddress> addresses;
  final String? activeAddressId;
  // ── Player card / coins (premium) ───────────────────────────────────
  /// Total moedas. Server-truth: only written via controlled grant rules
  /// (initial premium grant + monthly). Client never sets this directly.
  final int coins;
  /// Set once when the user first claims the initial premium grant (+5).
  /// Null = never granted. Used by rules to enforce one-shot.
  final DateTime? firstPremiumGrantAt;
  /// Last time the user claimed the monthly +2. Rules require the
  /// server-time delta to be ≥ 30 days before allowing the next one.
  final DateTime? lastMonthlyGrantAt;
  /// FIFA-style attributes (0–99). Premium-only. Cap depends on tier.
  /// See `defaultStats()` / `StatKeys`.
  final Map<String, int> stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.username,
    this.photoUrl,
    this.isPremium = false,
    this.isAdmin = false,
    this.isVerified = false,
    this.rating,
    this.ratingCount = 0,
    this.searchableByEmail = true,
    this.blockedUsers = const [],
    this.following = const [],
    this.followersCount = 0,
    this.visibleOnMap = false,
    this.lastLat,
    this.lastLng,
    this.address,
    this.addressLat,
    this.addressLng,
    this.addresses = const [],
    this.activeAddressId,
    this.coins = 0,
    this.firstPremiumGrantAt,
    this.lastMonthlyGrantAt,
    this.stats = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tier de card FIFA derivado de followersCount (server-truth field).
  CardTier get cardTier => cardTierFromFollowers(followersCount);

  /// Overall (média) das stats — usado no número grande do card.
  int get overall => overallRating(stats);

  /// True se o user é elegível pra reivindicar o grant inicial de 5 coins.
  bool get canClaimInitialPremiumGrant =>
      isPremium && firstPremiumGrantAt == null;

  /// True se já passou ≥ 30 dias desde o último grant mensal (ou nunca).
  bool canClaimMonthlyGrant([DateTime? now]) {
    if (!isPremium) return false;
    final last = lastMonthlyGrantAt;
    if (last == null) return true;
    final ref = now ?? DateTime.now();
    return ref.difference(last) >= const Duration(days: 30);
  }

  /// Preferred public location: fixed address if set, else last GPS reading.
  double? get effectiveLat => addressLat ?? lastLat;
  double? get effectiveLng => addressLng ?? lastLng;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAddresses = data['addresses'] as List? ?? const [];
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      name: data['name'] as String?,
      username: data['username'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      isAdmin: data['isAdmin'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      searchableByEmail: data['searchableByEmail'] as bool? ?? true,
      blockedUsers: List<String>.from(data['blockedUsers'] as List? ?? []),
      following: List<String>.from(data['following'] as List? ?? []),
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      visibleOnMap: data['visibleOnMap'] as bool? ?? false,
      lastLat: (data['lastLat'] as num?)?.toDouble(),
      lastLng: (data['lastLng'] as num?)?.toDouble(),
      address: data['address'] as String?,
      addressLat: (data['addressLat'] as num?)?.toDouble(),
      addressLng: (data['addressLng'] as num?)?.toDouble(),
      addresses: rawAddresses
          .map((e) => SavedAddress.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      activeAddressId: data['activeAddressId'] as String?,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      firstPremiumGrantAt:
          (data['firstPremiumGrantAt'] as Timestamp?)?.toDate(),
      lastMonthlyGrantAt:
          (data['lastMonthlyGrantAt'] as Timestamp?)?.toDate(),
      stats: () {
        final raw = data['stats'] as Map<String, dynamic>? ?? const {};
        return raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
      }(),
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
        'isAdmin': isAdmin,
        'isVerified': isVerified,
        if (rating != null) 'rating': rating,
        'ratingCount': ratingCount,
        'searchableByEmail': searchableByEmail,
        'blockedUsers': blockedUsers,
        'following': following,
        'followersCount': followersCount,
        'visibleOnMap': visibleOnMap,
        'lastLat': lastLat,
        'lastLng': lastLng,
        'address': address,
        'addressLat': addressLat,
        'addressLng': addressLng,
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'activeAddressId': activeAddressId,
        'coins': coins,
        if (firstPremiumGrantAt != null)
          'firstPremiumGrantAt': Timestamp.fromDate(firstPremiumGrantAt!),
        if (lastMonthlyGrantAt != null)
          'lastMonthlyGrantAt': Timestamp.fromDate(lastMonthlyGrantAt!),
        'stats': stats,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  bool hasBlocked(String otherUid) => blockedUsers.contains(otherUid);

  bool isFollowing(String otherUid) => following.contains(otherUid);

  UserModel copyWith({
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    bool? isPremium,
    bool? isAdmin,
    bool? isVerified,
    double? rating,
    int? ratingCount,
    bool? searchableByEmail,
    List<String>? blockedUsers,
    List<String>? following,
    int? followersCount,
    bool? visibleOnMap,
    double? lastLat,
    double? lastLng,
    String? address,
    double? addressLat,
    double? addressLng,
    List<SavedAddress>? addresses,
    String? activeAddressId,
    int? coins,
    DateTime? firstPremiumGrantAt,
    DateTime? lastMonthlyGrantAt,
    Map<String, int>? stats,
  }) =>
      UserModel(
        id: id,
        email: email ?? this.email,
        name: name ?? this.name,
        username: username ?? this.username,
        photoUrl: photoUrl ?? this.photoUrl,
        isPremium: isPremium ?? this.isPremium,
        isAdmin: isAdmin ?? this.isAdmin,
        isVerified: isVerified ?? this.isVerified,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        searchableByEmail: searchableByEmail ?? this.searchableByEmail,
        blockedUsers: blockedUsers ?? this.blockedUsers,
        following: following ?? this.following,
        followersCount: followersCount ?? this.followersCount,
        visibleOnMap: visibleOnMap ?? this.visibleOnMap,
        lastLat: lastLat ?? this.lastLat,
        lastLng: lastLng ?? this.lastLng,
        address: address ?? this.address,
        addressLat: addressLat ?? this.addressLat,
        addressLng: addressLng ?? this.addressLng,
        addresses: addresses ?? this.addresses,
        activeAddressId: activeAddressId ?? this.activeAddressId,
        coins: coins ?? this.coins,
        firstPremiumGrantAt: firstPremiumGrantAt ?? this.firstPremiumGrantAt,
        lastMonthlyGrantAt: lastMonthlyGrantAt ?? this.lastMonthlyGrantAt,
        stats: stats ?? this.stats,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
