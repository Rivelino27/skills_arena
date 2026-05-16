import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/team_match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/team_provider.dart';
import '../../providers/user_provider.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

/// Premium teams hub. Shows three tabs:
///   * "Meus times"    — teams I'm a member of, with quick captain actions
///   * "Explorar"      — public list of all teams for browsing/joining
///   * "Desafios"      — incoming + outgoing match proposals
/// Non-premium users see all tabs but the "Criar time" FAB is gated.
class TeamsHubScreen extends ConsumerStatefulWidget {
  const TeamsHubScreen({super.key});

  @override
  ConsumerState<TeamsHubScreen> createState() => _TeamsHubScreenState();
}

class _TeamsHubScreenState extends ConsumerState<TeamsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Times'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.shield_rounded), text: 'Meus'),
            Tab(icon: Icon(Icons.explore_rounded), text: 'Explorar'),
            Tab(icon: Icon(Icons.sports_kabaddi_rounded), text: 'Desafios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _MyTeamsTab(),
          _AllTeamsTab(),
          _ChallengesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_team',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Criar time'),
        onPressed: () {
          if (!isPremium) {
            _showPremiumGate(context);
            return;
          }
          AppNavigator.pushWithNavBar(context, const CreateTeamScreen());
        },
      ),
    );
  }

  void _showPremiumGate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium_rounded,
            color: Colors.amber, size: 40),
        title: const Text('Premium necessário'),
        content: const Text(
          'Criar e gerenciar times é um recurso Premium. '
          'Faça upgrade para liberar.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar')),
        ],
      ),
    );
  }
}

// ─── Tab 1: Meus times ────────────────────────────────────────────────

class _MyTeamsTab extends ConsumerWidget {
  const _MyTeamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return myTeams.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          return const _EmptyState(
            icon: Icons.shield_rounded,
            title: 'Você ainda não está em nenhum time',
            hint:
                'Crie um time como capitão ou peça pra alguém te adicionar.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: teams.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _TeamTile(team: teams[i], myUid: myUid),
        );
      },
    );
  }
}

// ─── Tab 2: Explorar ──────────────────────────────────────────────────

class _AllTeamsTab extends ConsumerWidget {
  const _AllTeamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTeams = ref.watch(allTeamsProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return allTeams.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          return const _EmptyState(
            icon: Icons.explore_rounded,
            title: 'Nenhum time cadastrado ainda',
            hint: 'Seja o primeiro a criar um.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: teams.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _TeamTile(team: teams[i], myUid: myUid),
        );
      },
    );
  }
}

// ─── Tab 3: Desafios ──────────────────────────────────────────────────

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  String _fmt(DateTime dt) {
    final hh = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} $hh';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeams = ref.watch(myTeamsProvider).valueOrNull ?? const [];
    final myTeamIds = myTeams.map((t) => t.id).toSet();
    final matchesAsync = ref.watch(myTeamMatchesProvider);
    final cs = Theme.of(context).colorScheme;

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (matches) {
        if (matches.isEmpty) {
          return const _EmptyState(
            icon: Icons.sports_kabaddi_rounded,
            title: 'Nenhum desafio agendado',
            hint:
                'Vá em um time qualquer e use "Desafiar" para marcar um jogo.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final m = matches[i];
            final iAmTeam1 = myTeamIds.contains(m.team1Id);
            final opponent = iAmTeam1 ? m.team2Name : m.team1Name;
            final iAmTeam2Captain = myTeams.any((t) =>
                t.id == m.team2Id &&
                t.isCaptain(FirebaseAuth.instance.currentUser?.uid ?? ''));
            final canRespond = iAmTeam2Captain &&
                m.status == TeamMatchStatus.proposed;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(m.status, cs),
                child: Icon(_statusIcon(m.status),
                    color: Colors.white, size: 18),
              ),
              title: Text('vs $opponent',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  '${m.venueName} • ${_fmt(m.startAt)}\n${m.status.label}'),
              isThreeLine: true,
              trailing: canRespond
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          tooltip: 'Aceitar',
                          onPressed: () => ref
                              .read(teamRepositoryProvider)
                              .respondMatch(
                                  matchId: m.id,
                                  newStatus: TeamMatchStatus.accepted),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red),
                          tooltip: 'Recusar',
                          onPressed: () => ref
                              .read(teamRepositoryProvider)
                              .respondMatch(
                                  matchId: m.id,
                                  newStatus: TeamMatchStatus.declined),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Color _statusColor(TeamMatchStatus s, ColorScheme cs) {
    switch (s) {
      case TeamMatchStatus.proposed:
        return Colors.orange;
      case TeamMatchStatus.accepted:
        return Colors.green;
      case TeamMatchStatus.declined:
      case TeamMatchStatus.cancelled:
        return cs.error;
      case TeamMatchStatus.played:
        return cs.primary;
    }
  }

  IconData _statusIcon(TeamMatchStatus s) {
    switch (s) {
      case TeamMatchStatus.proposed:
        return Icons.hourglass_top_rounded;
      case TeamMatchStatus.accepted:
        return Icons.check_rounded;
      case TeamMatchStatus.declined:
        return Icons.close_rounded;
      case TeamMatchStatus.cancelled:
        return Icons.cancel_rounded;
      case TeamMatchStatus.played:
        return Icons.sports_score_rounded;
    }
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────

class _TeamTile extends StatelessWidget {
  final TeamModel team;
  final String myUid;
  const _TeamTile({required this.team, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iAmIn = team.hasMember(myUid);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: team.photoUrl != null
            ? NetworkImage(team.photoUrl!)
            : null,
        backgroundColor: cs.primaryContainer,
        child: team.photoUrl == null
            ? Text(
                team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                style: TextStyle(color: cs.onPrimaryContainer),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(team.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (iAmIn)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                team.isCaptain(myUid) ? 'Capitão' : 'Membro',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      subtitle: Text(
          '${team.sport} • ${team.members.length} membro${team.members.length == 1 ? '' : 's'}'),
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurfaceVariant),
      onTap: () => AppNavigator.pushWithNavBar(
          context, TeamDetailScreen(teamId: team.id)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(hint,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
