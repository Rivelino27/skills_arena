import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Skills Arena')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (user) {
          final name = user?.name ?? 'Usuário';
          final isPremium = user?.isPremium ?? false;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Olá, $name!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Bem-vindo ao Skills Arena',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              if (!isPremium) ...[
                Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: cs.onPrimaryContainer,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desbloqueie o Premium',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Acesse todos os recursos exclusivos',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onPrimaryContainer),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Recursos',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _FeatureCard(
                icon: Icons.sports_esports_rounded,
                title: 'Desafios',
                description: 'Participe de desafios e ganhe pontos',
                isPremiumFeature: false,
                locked: false,
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.leaderboard_rounded,
                title: 'Ranking Global',
                description: 'Veja sua posição entre todos os jogadores',
                isPremiumFeature: true,
                locked: !isPremium,
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.analytics_rounded,
                title: 'Análise Avançada',
                description: 'Estatísticas detalhadas do seu desempenho',
                isPremiumFeature: true,
                locked: !isPremium,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isPremiumFeature;
  final bool locked;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isPremiumFeature,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: locked ? cs.onSurfaceVariant : cs.primary,
          size: 28,
        ),
        title: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: locked ? cs.onSurfaceVariant : null,
              ),
            ),
            if (isPremiumFeature) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PREMIUM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: locked
                ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                : cs.onSurfaceVariant,
          ),
        ),
        trailing: locked
            ? Icon(Icons.lock_outline_rounded, color: cs.onSurfaceVariant)
            : null,
      ),
    );
  }
}
