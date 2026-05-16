import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/user_model.dart';
import '../../providers/user_provider.dart';
import 'user_profile_screen.dart';

/// Global ranking of users across the whole app — separate from the
/// per-venue ranking on the venue detail page. Ordered by followers
/// count (desc), with secondary tie-breakers on rating and name.
class GlobalRankingScreen extends ConsumerWidget {
  const GlobalRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(topUsersByFollowersProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking geral')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (users) {
          final ranked = [...users]..sort((a, b) {
              final c = b.followersCount.compareTo(a.followersCount);
              if (c != 0) return c;
              final ra = (a.rating ?? 0.0);
              final rb = (b.rating ?? 0.0);
              final c2 = rb.compareTo(ra);
              if (c2 != 0) return c2;
              return (a.name ?? '').compareTo(b.name ?? '');
            });

          if (ranked.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_rounded,
                      size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Ainda sem ranking.',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Os jogadores mais seguidos da Skills Arena.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              if (ranked.isNotEmpty) _Podium(top: ranked.take(3).toList()),
              const SizedBox(height: 8),
              for (var i = 3; i < ranked.length; i++)
                _RankRow(user: ranked[i], position: i + 1),
            ],
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<UserModel> top;
  const _Podium({required this.top});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Visual order: 2nd, 1st, 3rd so #1 is center-tallest.
    final order = <(int, UserModel)>[];
    if (top.length >= 2) order.add((2, top[1]));
    order.add((1, top[0]));
    if (top.length >= 3) order.add((3, top[2]));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (rank, u) in order)
            _PodiumColumn(
              rank: rank,
              user: u,
              color: rank == 1
                  ? Colors.amber
                  : rank == 2
                      ? Colors.grey.shade400
                      : Colors.brown.shade300,
              height: rank == 1 ? 80.0 : rank == 2 ? 60.0 : 44.0,
              cs: cs,
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final UserModel user;
  final Color color;
  final double height;
  final ColorScheme cs;
  const _PodiumColumn({
    required this.rank,
    required this.user,
    required this.color,
    required this.height,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name ?? 'Usuário';
    return Expanded(
      child: GestureDetector(
        onTap: () => AppNavigator.pushWithNavBar(
            context, UserProfileScreen(userId: user.id)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: rank == 1 ? 32 : 26,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: user.photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: rank == 1 ? 22 : 18),
                        )
                      : null,
                ),
                if (rank == 1)
                  Positioned(
                    top: -14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(Icons.emoji_events_rounded,
                          color: color, size: 26),
                    ),
                  ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      rank == 1 ? FontWeight.bold : FontWeight.w600,
                )),
            Text('${user.followersCount} seguidores',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.75),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final UserModel user;
  final int position;
  const _RankRow({required this.user, required this.position});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = user.name ?? 'Usuário';
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Text(
          '#$position',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            backgroundColor: cs.primaryContainer,
            child: user.photoUrl == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (user.isPremium)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.workspace_premium_rounded,
                  size: 16, color: Colors.amber),
            ),
        ],
      ),
      subtitle: Text(
          '${user.followersCount} seguidores · ${user.following.length} seguindo'),
      onTap: () => AppNavigator.pushWithNavBar(
          context, UserProfileScreen(userId: user.id)),
    );
  }
}
