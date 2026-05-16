import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/team_match_model.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';

/// Teams the current user is a member of.
final myTeamsProvider = StreamProvider<List<TeamModel>>((ref) {
  return ref.watch(teamRepositoryProvider).myTeamsStream();
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
