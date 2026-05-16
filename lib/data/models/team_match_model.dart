import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a team match proposal.
enum TeamMatchStatus { proposed, accepted, declined, cancelled, played }

extension TeamMatchStatusX on TeamMatchStatus {
  String get label {
    switch (this) {
      case TeamMatchStatus.proposed:
        return 'Aguardando resposta';
      case TeamMatchStatus.accepted:
        return 'Aceita';
      case TeamMatchStatus.declined:
        return 'Recusada';
      case TeamMatchStatus.cancelled:
        return 'Cancelada';
      case TeamMatchStatus.played:
        return 'Realizada';
    }
  }

  String get storageKey => name;
}

TeamMatchStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'accepted':
      return TeamMatchStatus.accepted;
    case 'declined':
      return TeamMatchStatus.declined;
    case 'cancelled':
      return TeamMatchStatus.cancelled;
    case 'played':
      return TeamMatchStatus.played;
    default:
      return TeamMatchStatus.proposed;
  }
}

/// A team-vs-team challenge scheduled at a venue. `team1` is always the
/// proposer; `team2` is the challenged team. Both `teamIds` are stored
/// in a flat array so we can query "matches involving my team" with a
/// single `arrayContains`.
class TeamMatchModel {
  final String id;
  final String team1Id;
  final String team1Name;
  final String team2Id;
  final String team2Name;
  final List<String> teamIds;
  final String venueId;
  final String venueName;
  final DateTime startAt;
  final TeamMatchStatus status;
  final String createdBy;
  final DateTime createdAt;

  const TeamMatchModel({
    required this.id,
    required this.team1Id,
    required this.team1Name,
    required this.team2Id,
    required this.team2Name,
    required this.teamIds,
    required this.venueId,
    required this.venueName,
    required this.startAt,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory TeamMatchModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamMatchModel(
      id: doc.id,
      team1Id: d['team1Id'] as String,
      team1Name: d['team1Name'] as String? ?? 'Time A',
      team2Id: d['team2Id'] as String,
      team2Name: d['team2Name'] as String? ?? 'Time B',
      teamIds: List<String>.from(d['teamIds'] as List? ?? []),
      venueId: d['venueId'] as String,
      venueName: d['venueName'] as String? ?? 'Quadra',
      startAt:
          (d['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _statusFromString(d['status'] as String?),
      createdBy: d['createdBy'] as String,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'team1Id': team1Id,
        'team1Name': team1Name,
        'team2Id': team2Id,
        'team2Name': team2Name,
        'teamIds': teamIds,
        'venueId': venueId,
        'venueName': venueName,
        'startAt': Timestamp.fromDate(startAt),
        'status': status.storageKey,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
