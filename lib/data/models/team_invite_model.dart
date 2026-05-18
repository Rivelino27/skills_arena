import 'package:cloud_firestore/cloud_firestore.dart';

enum TeamInviteStatus { pending, accepted, declined, cancelled }

extension TeamInviteStatusX on TeamInviteStatus {
  String get label {
    switch (this) {
      case TeamInviteStatus.pending:
        return 'Pendente';
      case TeamInviteStatus.accepted:
        return 'Aceito';
      case TeamInviteStatus.declined:
        return 'Recusado';
      case TeamInviteStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get storageKey => name;
}

TeamInviteStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'accepted':
      return TeamInviteStatus.accepted;
    case 'declined':
      return TeamInviteStatus.declined;
    case 'cancelled':
      return TeamInviteStatus.cancelled;
    default:
      return TeamInviteStatus.pending;
  }
}

/// Convite que o capitão de um time envia para um usuário entrar.
/// Status flow: pending → accepted (joins) | declined | cancelled.
/// Stored top-level (`team_invites`) so the invitee's "inbox" can be a
/// single arrayContains query on `inviteeUid`.
class TeamInviteModel {
  final String id;
  final String teamId;
  final String teamName;
  final String captainId;
  final String captainName;
  final String inviteeUid;
  final String inviteeName;
  final TeamInviteStatus status;
  final DateTime createdAt;

  const TeamInviteModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.captainId,
    required this.captainName,
    required this.inviteeUid,
    required this.inviteeName,
    required this.status,
    required this.createdAt,
  });

  factory TeamInviteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamInviteModel(
      id: doc.id,
      teamId: d['teamId'] as String,
      teamName: d['teamName'] as String? ?? 'Time',
      captainId: d['captainId'] as String,
      captainName: d['captainName'] as String? ?? 'Capitão',
      inviteeUid: d['inviteeUid'] as String,
      inviteeName: d['inviteeName'] as String? ?? 'Jogador',
      status: _statusFromString(d['status'] as String?),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'teamId': teamId,
        'teamName': teamName,
        'captainId': captainId,
        'captainName': captainName,
        'inviteeUid': inviteeUid,
        'inviteeName': inviteeName,
        'status': status.storageKey,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
