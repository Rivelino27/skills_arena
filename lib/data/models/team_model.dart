import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight team membership info — denormalized into the team doc
/// so we can render member chips without N extra reads.
class TeamMember {
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const TeamMember({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  factory TeamMember.fromMap(Map<String, dynamic> m) => TeamMember(
        userId: m['userId'] as String,
        userName: m['userName'] as String? ?? 'Jogador',
        userPhotoUrl: m['userPhotoUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
      };
}

/// Premium-only team. Captain creates it and can manage membership;
/// matches are proposed via `TeamMatchModel`.
class TeamModel {
  final String id;
  final String name;
  final String sport;
  final String captainId;
  final String captainName;
  final String? photoUrl;
  final List<TeamMember> members;
  /// Flat list of UIDs duplicated from `members` so we can run
  /// `arrayContains` queries without unpacking the member objects.
  final List<String> memberIds;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.captainId,
    required this.captainName,
    this.photoUrl,
    required this.members,
    required this.memberIds,
    required this.createdAt,
  });

  bool hasMember(String uid) => memberIds.contains(uid);
  bool isCaptain(String uid) => captainId == uid;

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final raw = (d['members'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TeamMember.fromMap)
        .toList();
    return TeamModel(
      id: doc.id,
      name: d['name'] as String,
      sport: d['sport'] as String,
      captainId: d['captainId'] as String,
      captainName: d['captainName'] as String? ?? 'Capitão',
      photoUrl: d['photoUrl'] as String?,
      members: raw,
      memberIds: List<String>.from(d['memberIds'] as List? ?? []),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sport': sport,
        'captainId': captainId,
        'captainName': captainName,
        'photoUrl': photoUrl,
        'members': members.map((m) => m.toMap()).toList(),
        'memberIds': memberIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
