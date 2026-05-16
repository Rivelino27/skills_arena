import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/user_provider.dart';
import '../auth/login_screen.dart';
import '../teams/teams_hub_screen.dart';
import 'edit_address_screen.dart';
import 'global_ranking_screen.dart';
import 'nav_demo_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (user) {
          final displayName =
              user?.name ?? firebaseUser?.displayName ?? 'Usuário';
          final email = user?.email ?? firebaseUser?.email ?? '';
          final isPremium = user?.isPremium ?? false;
          final photoUrl = user?.photoUrl ?? firebaseUser?.photoURL;
          final username = user?.username;
          final searchableByEmail = user?.searchableByEmail ?? true;
          final initial =
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: cs.primaryContainer,
                  child: photoUrl == null
                      ? Text(
                          initial,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  displayName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (username != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '@$username',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.primary),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: _PremiumBadge(isPremium: isPremium),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${user?.followersCount ?? 0} seguidor'
                      '${(user?.followersCount ?? 0) == 1 ? '' : 'es'} • '
                      '${user?.following.length ?? 0} seguindo',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (!isPremium) ...[
                Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: cs.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Upgrade para Premium',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acesse recursos exclusivos, sem anúncios e com suporte prioritário.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onPrimaryContainer),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _showUpgradeDialog(context),
                          child: const Text('Ver planos'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // ── Conta ───────────────────────────────────────────────────
              Text(
                'CONTA',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('E-mail'),
                      subtitle: Text(email),
                    ),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: cs.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.leaderboard_rounded),
                      title: const Text('Ranking geral'),
                      subtitle: const Text(
                          'Top jogadores por seguidores na Skills Arena'),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                      onTap: () => AppNavigator.pushWithNavBar(
                          context, const GlobalRankingScreen()),
                    ),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: cs.outlineVariant),
                    ListTile(
                      leading: Icon(Icons.shield_rounded, color: cs.primary),
                      title: Row(
                        children: [
                          const Text('Times'),
                          const SizedBox(width: 6),
                          Icon(Icons.workspace_premium_rounded,
                              size: 14, color: Colors.amber.shade700),
                        ],
                      ),
                      subtitle: const Text(
                          'Crie um time, desafie outros e marque jogos'),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                      onTap: () => AppNavigator.pushWithNavBar(
                          context, const TeamsHubScreen()),
                    ),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: cs.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: const Text('Meu endereço'),
                      subtitle: Text(
                        user?.address ??
                            'Defina um endereço fixo para o mapa',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                      onTap: () => AppNavigator.pushWithNavBar(
                          context, const EditAddressScreen()),
                    ),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: cs.outlineVariant),
                    SwitchListTile(
                      secondary: const Icon(Icons.manage_search_rounded),
                      title: const Text('Buscável por e-mail'),
                      subtitle: const Text(
                          'Outros usuários podem te achar pelo e-mail'),
                      value: searchableByEmail,
                      onChanged: (v) => _toggleSearchableByEmail(
                          firebaseUser?.uid, v),
                    ),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: cs.outlineVariant),
                    ListTile(
                      leading:
                          Icon(Icons.logout_rounded, color: cs.error),
                      title: Text(
                        'Sair da conta',
                        style: TextStyle(color: cs.error),
                      ),
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Dev / Exemplos ──────────────────────────────────────────
              Text(
                'DESENVOLVEDOR',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route_rounded),
                  title: const Text('Telas de Exemplo'),
                  subtitle: const Text('Demonstração de padrões de navegação'),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                  onTap: () => AppNavigator.pushWithNavBar(
                      context, const NavDemoScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSearchableByEmail(String? uid, bool value) async {
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'searchableByEmail': value});
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium_rounded, size: 40),
        title: const Text('Planos Premium'),
        content: const Text(
          'Integração de pagamentos em breve!\n\n'
          'Você será notificado quando os planos Premium estiverem disponíveis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sair',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  final bool isPremium;
  const _PremiumBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = isPremium ? Colors.amber : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium
            ? Colors.amber.withValues(alpha: 0.15)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.person_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isPremium ? 'Premium' : 'Gratuito',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
