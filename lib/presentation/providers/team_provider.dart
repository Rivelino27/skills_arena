import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/team_invite_model.dart';
import '../../data/models/team_match_model.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';

/// Teams the current user is a member of.
final myTeamsProvider = StreamProvider<List<TeamModel>>((ref) {
  return ref.watch(teamRepositoryProvider).myTeamsStream();
});

/// Teams any specific user is a member of — used by the user profile
/// screen to display the user's teams.
final userTeamsProvider =
    StreamProvider.family<List<TeamModel>, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('teams')
      .where('memberIds', arrayContains: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TeamModel.fromFirestore).toList());
});

/// All public teams, ordered by createdAt desc — for the "Explorar"
/// browse list.
final allTeamsProvider = StreamProvider<List<TeamModel>>((ref) {
  return ref.watch(teamRepositoryProvider).allTeamsStream();
});

/// Matches involving any of the user's teams (proposals + accepted).
/// Wraps `myTeamsProvider` so it auto-rebuilds when the membership
/// changes.
final myTeamMatchesProvider = StreamProvider<List<TeamMatchModel>>((ref) {
  final myTeams = ref.watch(myTeamsProvider).valueOrNull ?? const [];
  final ids = myTeams.map((t) => t.id).toList();
  return ref.watch(teamRepositoryProvider).matchesForTeamsStream(ids);
});

/// Convites recebidos pelo usuário logado (inbox de team invites).
final myTeamInvitesProvider =
    StreamProvider<List<TeamInviteModel>>((ref) {
  return ref.watch(teamRepositoryProvider).myInvitesStream();
});

/// Convites associados a um time específico — usado pelo detalhe do
/// time para o capitão visualizar quem ele convidou.
final teamInvitesProvider =
    StreamProvider.family<List<TeamInviteModel>, String>((ref, teamId) {
  return ref.watch(teamRepositoryProvider).invitesSentStream(teamId);
});
