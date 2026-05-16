import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/player_card.dart';
import '../../../data/repositories/social_repository.dart';
import '../../providers/user_provider.dart';
import '../../widgets/fifa_card_widget.dart';

/// Premium player profile: shows the FIFA card, coin balance with
/// "claim" buttons (initial 5 + monthly 2), stat editor, and the
/// 4 playstyles unlocked by the current tier.
///
/// Non-premium users see a soft paywall card.
class PlayerCardScreen extends ConsumerWidget {
  const PlayerCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Card de Jogador')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Não autenticado.'));
          }
          if (!user.isPremium) {
            return _PaywallView(cs: cs);
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: FifaCardWidget(user: user, scale: 1.1),
              ),
              const SizedBox(height: 24),
              _CoinsSection(coins: user.coins),
              const SizedBox(height: 12),
              _ClaimButtons(
                canInitial: user.canClaimInitialPremiumGrant,
                canMonthly: user.canClaimMonthlyGrant(),
                nextMonthlyLabel: _nextMonthlyLabel(user.lastMonthlyGrantAt),
              ),
              const SizedBox(height: 24),
              _PlaystylesSection(tier: user.cardTier),
              const SizedBox(height: 24),
              _StatsEditor(
                stats: user.stats.isEmpty ? defaultStats() : user.stats,
                tier: user.cardTier,
              ),
            ],
          );
        },
      ),
    );
  }

  String? _nextMonthlyLabel(DateTime? last) {
    if (last == null) return null;
    final delta = DateTime.now().difference(last);
    if (delta >= const Duration(days: 30)) return null;
    final daysLeft = 30 - delta.inDays;
    return 'Próximo em $daysLeft dia${daysLeft == 1 ? '' : 's'}';
  }
}

// ─── Paywall ──────────────────────────────────────────────────────────

class _PaywallView extends StatelessWidget {
  final ColorScheme cs;
  const _PaywallView({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 64, color: Colors.amber.shade700),
                const SizedBox(height: 12),
                Text(
                  'Card de Jogador Premium',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tenha seu card FIFA com tier dourado/platina/diamante, '
                  'stats personalizáveis, 4 playstyles especiais e ganhe '
                  'moedas todo mês.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Coins ────────────────────────────────────────────────────────────

class _CoinsSection extends StatelessWidget {
  final int coins;
  const _CoinsSection({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.monetization_on_rounded,
                color: Colors.amber, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$coins',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                  ),
                  const Text('Moedas Skills Arena'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimButtons extends ConsumerStatefulWidget {
  final bool canInitial;
  final bool canMonthly;
  final String? nextMonthlyLabel;
  const _ClaimButtons({
    required this.canInitial,
    required this.canMonthly,
    required this.nextMonthlyLabel,
  });

  @override
  ConsumerState<_ClaimButtons> createState() => _ClaimButtonsState();
}

class _ClaimButtonsState extends ConsumerState<_ClaimButtons> {
  bool _claiming = false;

  Future<void> _claimInitial() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _claiming = true);
    try {
      final newBalance =
          await ref.read(socialRepositoryProvider).claimInitialPremiumGrant();
      messenger.showSnackBar(SnackBar(
          content: Text('+5 moedas! Saldo: $newBalance')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _claimMonthly() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _claiming = true);
    try {
      final newBalance =
          await ref.read(socialRepositoryProvider).claimMonthlyGrant();
      messenger.showSnackBar(SnackBar(
          content: Text('+2 moedas mensais! Saldo: $newBalance')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.canInitial)
          FilledButton.icon(
            onPressed: _claiming ? null : _claimInitial,
            icon: const Icon(Icons.card_giftcard_rounded),
            label: const Text('Reivindicar bônus inicial (+5 moedas)'),
          ),
        if (widget.canInitial) const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed:
              (_claiming || !widget.canMonthly) ? null : _claimMonthly,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(widget.canMonthly
              ? 'Reivindicar bônus mensal (+2 moedas)'
              : (widget.nextMonthlyLabel ?? 'Indisponível')),
        ),
      ],
    );
  }
}

// ─── Playstyles ───────────────────────────────────────────────────────

class _PlaystylesSection extends StatelessWidget {
  final CardTier tier;
  const _PlaystylesSection({required this.tier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLAYSTYLES',
            style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final key in PlaystyleKeys.all)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tier.accent,
                      child: Icon(playstyleIcon(key), color: Colors.white),
                    ),
                    title: Text(playstyleLabel(key),
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Boost em ${statLabel(playstyleStatKey(key))} • '
                        'Tier ${tier.label}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tier.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tier.label.toUpperCase(),
                        style: TextStyle(
                          color: tier.textOnTier,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stats editor ─────────────────────────────────────────────────────

class _StatsEditor extends ConsumerStatefulWidget {
  final Map<String, int> stats;
  final CardTier tier;
  const _StatsEditor({required this.stats, required this.tier});

  @override
  ConsumerState<_StatsEditor> createState() => _StatsEditorState();
}

class _StatsEditorState extends ConsumerState<_StatsEditor> {
  late Map<String, int> _stats;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stats = Map<String, int>.from(widget.stats);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).updateStats(_stats);
      messenger.showSnackBar(
          const SnackBar(content: Text('Stats atualizadas.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cap = widget.tier.statCap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('STATS',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            Text(
              'cap ${widget.tier.label} = $cap',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final key in StatKeys.all)
                  _StatSlider(
                    statKey: key,
                    value: (_stats[key] ?? 50).clamp(0, cap),
                    cap: cap,
                    onChanged: (v) =>
                        setState(() => _stats[key] = v),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: const Text('Salvar stats'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatSlider extends StatelessWidget {
  final String statKey;
  final int value;
  final int cap;
  final ValueChanged<int> onChanged;

  const _StatSlider({
    required this.statKey,
    required this.value,
    required this.cap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statIcon(statKey), color: cs.primary, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(statLabel(statKey),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: cap.toDouble(),
              divisions: cap,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
