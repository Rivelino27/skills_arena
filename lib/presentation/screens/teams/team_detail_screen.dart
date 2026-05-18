import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/team_provider.dart';
import '../profile/user_profile_screen.dart';
import 'invite_member_sheet.dart';
import 'propose_match_sheet.dart';

/// Detail view of a single team. Shows captain + members and exposes:
///   * "Desafiar" — open the propose-match sheet (any member of any
///                  OTHER team can challenge this one)
///   * captain-only: rename / delete / remove member
class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Watch myTeams + allTeams so the screen rebuilds when membership
    // or team data changes.
    final myTeams = ref.watch(myTeamsProvider).valueOrNull ?? const [];
    final allTeams = ref.watch(allTeamsProvider).valueOrNull ?? const [];
    final TeamModel? team = [...myTeams, ...allTeams]
        .where((t) => t.id == teamId)
        .firstOrNull;

    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Time')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isCaptain = team.isCaptain(myUid);
    final iAmIn = team.hasMember(myUid);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (isCaptain)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) async {
                if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Apagar time?'),
                      content: const Text(
                          'Esta ação não pode ser desfeita. '
                          'Desafios pendentes serão ignorados.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar')),
                        FilledButton.tonal(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Apagar')),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  if (!context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final res = await ref
                      .read(teamRepositoryProvider)
                      .deleteTeam(team.id);
                  res.fold(
                    (f) => messenger.showSnackBar(
                        SnackBar(content: Text(f.message))),
                    (_) {
                      messenger.showSnackBar(const SnackBar(
                          content: Text('Time apagado.')));
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    title: Text('Apagar time'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage: team.photoUrl != null
                  ? NetworkImage(team.photoUrl!)
                  : null,
              backgroundColor: cs.primaryContainer,
              child: team.photoUrl == null
                  ? Text(
                      team.name.isNotEmpty
                          ? team.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(team.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.sports_rounded, size: 16),
                  label: Text(team.sport),
                ),
                Chip(
                  avatar: const Icon(Icons.group_rounded, size: 16),
                  label: Text('${team.members.length} '
                      'membro${team.members.length == 1 ? '' : 's'}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (iAmIn) ...[
            FilledButton.tonalIcon(
              onPressed: () => _openProposeMatch(context, team),
              icon: const Icon(Icons.sports_kabaddi_rounded),
              label: const Text('Desafiar outro time'),
            ),
            if (isCaptain) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => InviteMemberSheet(team: team),
                ),
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Convidar membro'),
              ),
            ],
          ]
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                        'Para desafiar, peça pra alguém te adicionar a um time.'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text('CAPITÃO',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.2,
                  )),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(team.captainName.isNotEmpty
                    ? team.captainName[0].toUpperCase()
                    : '?'),
              ),
              title: Text(team.captainName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.shield_moon_rounded,
                  color: Colors.amber.shade700),
              onTap: () => AppNavigator.pushWithNavBar(
                  context, UserProfileScreen(userId: team.captainId)),
            ),
          ),
          const SizedBox(height: 16),
          Text('MEMBROS (${team.members.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.2,
                  )),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                for (final m in team.members)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: m.userPhotoUrl != null
                          ? NetworkImage(m.userPhotoUrl!)
                          : null,
                      child: m.userPhotoUrl == null
                          ? Text(m.userName.isNotEmpty
                              ? m.userName[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(m.userName),
                    subtitle: m.userId == team.captainId
                        ? const Text('Capitão')
                        : null,
                    trailing: (isCaptain && m.userId != team.captainId)
                        ? IconButton(
                            tooltip: 'Remover membro',
                            icon: Icon(Icons.person_remove_rounded,
                                color: cs.error),
                            onPressed: () => _confirmRemove(
                                context, ref, team.id, m.userId,
                                m.userName),
                          )
                        : (m.userId == myUid && !isCaptain
                            ? TextButton(
                                onPressed: () => _confirmLeave(
                                    context, ref, team.id, myUid),
                                child: const Text('Sair'),
                              )
                            : null),
                    onTap: () => AppNavigator.pushWithNavBar(
                        context, UserProfileScreen(userId: m.userId)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openProposeMatch(BuildContext context, TeamModel myTeam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ProposeMatchSheet(myTeam: myTeam),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref,
      String teamId, String userId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro?'),
        content: Text('Remover "$name" do time?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(teamRepositoryProvider)
        .removeMember(teamId: teamId, userId: userId);
    res.fold(
      (f) =>
          messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger.showSnackBar(
          const SnackBar(content: Text('Membro removido.'))),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref,
      String teamId, String userId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do time?'),
        content: const Text('Tem certeza? Você perde acesso aos desafios.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sair')),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(teamRepositoryProvider)
        .removeMember(teamId: teamId, userId: userId);
    res.fold(
      (f) =>
          messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Você saiu do time.')));
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
