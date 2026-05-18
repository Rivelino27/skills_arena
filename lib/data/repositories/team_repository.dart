import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../models/team_invite_model.dart';
import '../models/team_match_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(firestore: FirebaseFirestore.instance);
});

class TeamRepository {
  final FirebaseFirestore _db;

  TeamRepository({required FirebaseFirestore firestore}) : _db = firestore;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _db.collection('teams');

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('team_matches');

  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('team_invites');

  // ─── Teams ────────────────────────────────────────────────────────────

  /// Teams where the current user is a member.
  Stream<List<TeamModel>> myTeamsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _teams
        .where('memberIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TeamModel.fromFirestore).toList());
  }

  /// All teams for the public "Explorar times" browse list.
  Stream<List<TeamModel>> allTeamsStream({int limit = 100}) => _teams
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(TeamModel.fromFirestore).toList());

  Future<TeamModel?> getTeam(String teamId) async {
    final snap = await _teams.doc(teamId).get();
    if (!snap.exists) return null;
    return TeamModel.fromFirestore(snap);
  }

  /// Creates a team with the current user as captain + sole initial
  /// member. Premium gating is enforced both on the UI side and via
  /// Firestore rules — this method just builds the doc.
  Future<Either<AppFailure, TeamModel>> createTeam({
    required String name,
    required String sport,
    String? photoUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final member = TeamMember(
        userId: user.uid,
        userName: user.displayName ?? 'Capitão',
        userPhotoUrl: user.photoURL,
      );
      final docRef = _teams.doc();
      final team = TeamModel(
        id: docRef.id,
        name: name.trim(),
        sport: sport,
        captainId: user.uid,
        captainName: user.displayName ?? 'Capitão',
        photoUrl: photoUrl,
        members: [member],
        memberIds: [user.uid],
        createdAt: DateTime.now(),
      );
      await docRef.set(team.toMap());
      return Right(team);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao criar time.'));
    }
  }

  Future<Either<AppFailure, Unit>> addMember({
    required String teamId,
    required UserModel user,
  }) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      await _db.runTransaction((tx) async {
        final ref = _teams.doc(teamId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('Time não encontrado.');
        }
        final t = TeamModel.fromFirestore(snap);
        if (!t.isCaptain(me.uid)) {
          throw Exception('Apenas o capitão pode adicionar membros.');
        }
        if (t.hasMember(user.id)) return; // idempotent
        final updated = [
          ...t.members,
          TeamMember(
              userId: user.id,
              userName: user.name ?? 'Jogador',
              userPhotoUrl: user.photoUrl),
        ];
        tx.update(ref, {
          'members': updated.map((m) => m.toMap()).toList(),
          'memberIds': FieldValue.arrayUnion([user.id]),
        });
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Captain can remove anyone; a regular member can remove themselves.
  Future<Either<AppFailure, Unit>> removeMember({
    required String teamId,
    required String userId,
  }) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      await _db.runTransaction((tx) async {
        final ref = _teams.doc(teamId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('Time não encontrado.');
        }
        final t = TeamModel.fromFirestore(snap);
        final isCaptain = t.isCaptain(me.uid);
        final isSelf = me.uid == userId;
        if (!isCaptain && !isSelf) {
          throw Exception('Sem permissão para remover este membro.');
        }
        if (t.isCaptain(userId)) {
          throw Exception('O capitão não pode sair — apague o time.');
        }
        final updated =
            t.members.where((m) => m.userId != userId).toList();
        tx.update(ref, {
          'members': updated.map((m) => m.toMap()).toList(),
          'memberIds': FieldValue.arrayRemove([userId]),
        });
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Only the captain can delete the team. Pending matches are NOT
  /// cleaned up here — the UI hides them when the team no longer
  /// exists (Firestore reads return null).
  Future<Either<AppFailure, Unit>> deleteTeam(String teamId) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final team = await getTeam(teamId);
      if (team == null) {
        return const Left(ServerFailure(message: 'Time não encontrado.'));
      }
      if (!team.isCaptain(me.uid)) {
        return const Left(
            AuthFailure(message: 'Apenas o capitão pode apagar o time.'));
      }
      await _teams.doc(teamId).delete();
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao apagar time.'));
    }
  }

  // ─── Matches (desafios entre times) ───────────────────────────────────

  /// Live matches involving any of the teams I'm in. Filtered to the
  /// future + last 7 days to keep the list manageable.
  Stream<List<TeamMatchModel>> matchesForTeamsStream(List<String> teamIds) {
    if (teamIds.isEmpty) return Stream.value(const []);
    // Firestore arrayContainsAny caps at 30 — fine for MVP.
    final ids = teamIds.length > 30 ? teamIds.sublist(0, 30) : teamIds;
    return _matches
        .where('teamIds', arrayContainsAny: ids)
        .orderBy('startAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(TeamMatchModel.fromFirestore).toList());
  }

  Future<Either<AppFailure, TeamMatchModel>> proposeMatch({
    required String myTeamId,
    required String opponentTeamId,
    required String venueId,
    required String venueName,
    required DateTime startAt,
  }) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final myTeam = await getTeam(myTeamId);
      final opp = await getTeam(opponentTeamId);
      if (myTeam == null || opp == null) {
        return const Left(ServerFailure(message: 'Time não encontrado.'));
      }
      if (!myTeam.hasMember(me.uid)) {
        return const Left(
            AuthFailure(message: 'Você não é membro desse time.'));
      }
      final ref = _matches.doc();
      final match = TeamMatchModel(
        id: ref.id,
        team1Id: myTeam.id,
        team1Name: myTeam.name,
        team2Id: opp.id,
        team2Name: opp.name,
        teamIds: [myTeam.id, opp.id],
        venueId: venueId,
        venueName: venueName,
        startAt: startAt,
        status: TeamMatchStatus.proposed,
        createdBy: me.uid,
        createdAt: DateTime.now(),
      );
      await ref.set(match.toMap());
      return Right(match);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao propor desafio.'));
    }
  }

  /// Captain of the challenged team accepts/declines. Either captain
  /// can cancel after acceptance.
  Future<Either<AppFailure, Unit>> respondMatch({
    required String matchId,
    required TeamMatchStatus newStatus,
  }) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      await _matches.doc(matchId).update({'status': newStatus.storageKey});
      return const Right(unit);
    } catch (e) {
      return const Left(
          ServerFailure(message: 'Erro ao atualizar desafio.'));
    }
  }

  // ─── Invites (convites para entrar em time) ──────────────────────────

  /// Convites recebidos pelo usuário logado, em ordem de chegada.
  Stream<List<TeamInviteModel>> myInvitesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _invites
        .where('inviteeUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(TeamInviteModel.fromFirestore).toList());
  }

  /// Convites pendentes que o usuário (capitão) enviou. Usado pra mostrar
  /// "convite enviado" e permitir cancelar.
  Stream<List<TeamInviteModel>> invitesSentStream(String teamId) {
    return _invites
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TeamInviteModel.fromFirestore).toList());
  }

  /// Capitão envia convite. Rejeita se já houver um convite pendente pro
  /// mesmo time/usuário (regras + check client-side).
  Future<Either<AppFailure, Unit>> sendInvite({
    required String teamId,
    required UserModel invitee,
  }) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final team = await getTeam(teamId);
      if (team == null) {
        return const Left(
            ServerFailure(message: 'Time não encontrado.'));
      }
      if (!team.isCaptain(me.uid)) {
        return const Left(AuthFailure(
            message: 'Apenas o capitão pode convidar membros.'));
      }
      if (team.hasMember(invitee.id)) {
        return const Left(
            ServerFailure(message: 'Usuário já é membro.'));
      }
      // Deterministic ID: {teamId}_{inviteeUid}. Garante que a rule
      // de `teams.update` consiga validar "existe convite pendente"
      // com um exists(...) na mesma chave. Também impede duplicados.
      final inviteId = '${teamId}_${invitee.id}';
      final ref = _invites.doc(inviteId);
      final existing = await ref.get();
      if (existing.exists) {
        return const Left(
            ServerFailure(message: 'Já existe um convite para esse usuário.'));
      }
      final inv = TeamInviteModel(
        id: ref.id,
        teamId: team.id,
        teamName: team.name,
        captainId: me.uid,
        captainName: team.captainName,
        inviteeUid: invitee.id,
        inviteeName: invitee.name ?? 'Jogador',
        status: TeamInviteStatus.pending,
        createdAt: DateTime.now(),
      );
      await ref.set(inv.toMap());
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao convidar.'));
    }
  }

  /// O convidado aceita: marca invite como accepted E adiciona ele
  /// ao time numa única transação para garantir consistência.
  Future<Either<AppFailure, Unit>> acceptInvite(
      TeamInviteModel invite) async {
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      if (me.uid != invite.inviteeUid) {
        return const Left(
            AuthFailure(message: 'Convite não é para você.'));
      }
      await _db.runTransaction((tx) async {
        final teamRef = _teams.doc(invite.teamId);
        final inviteRef = _invites.doc(invite.id);
        final teamSnap = await tx.get(teamRef);
        if (!teamSnap.exists) {
          throw Exception('Time não encontrado.');
        }
        final team = TeamModel.fromFirestore(teamSnap);
        if (team.hasMember(me.uid)) {
          // já é membro — só marca o convite como aceito
          tx.update(inviteRef,
              {'status': TeamInviteStatus.accepted.storageKey});
          return;
        }
        final newMember = TeamMember(
          userId: me.uid,
          userName: me.displayName ?? invite.inviteeName,
          userPhotoUrl: me.photoURL,
        );
        final updated = [...team.members, newMember];
        tx.update(teamRef, {
          'members': updated.map((m) => m.toMap()).toList(),
          'memberIds': FieldValue.arrayUnion([me.uid]),
        });
        tx.update(inviteRef,
            {'status': TeamInviteStatus.accepted.storageKey});
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// O convidado recusa OU o capitão cancela. Como o doc usa ID
  /// determinístico ({teamId}_{inviteeUid}), recusar deleta o doc —
  /// assim o capitão pode mandar novo convite no futuro.
  Future<Either<AppFailure, Unit>> respondInvite({
    required String inviteId,
    required TeamInviteStatus newStatus,
  }) async {
    try {
      if (newStatus == TeamInviteStatus.declined ||
          newStatus == TeamInviteStatus.cancelled) {
        await _invites.doc(inviteId).delete();
      } else {
        await _invites.doc(inviteId).update({
          'status': newStatus.storageKey,
        });
      }
      return const Right(unit);
    } catch (e) {
      return const Left(
          ServerFailure(message: 'Erro ao atualizar convite.'));
    }
  }
}
