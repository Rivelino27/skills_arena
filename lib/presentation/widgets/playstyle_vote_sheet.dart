import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/player_card.dart';
import '../../data/repositories/social_repository.dart';
import '../providers/user_provider.dart';

/// Bottom sheet for voting on which playstyles a target user has.
/// The current user picks up to 4 toggles, hits "Salvar voto" — backend
/// stores `users/{targetUid}/playstyle_votes/{myUid}`. Aggregation +
/// threshold (≥3 voters AND ≥30%) decides which playstyles become
/// gold on the target's FIFA card.
class PlaystyleVoteSheet extends ConsumerStatefulWidget {
  final String targetUid;
  final String targetName;
  const PlaystyleVoteSheet({
    super.key,
    required this.targetUid,
    required this.targetName,
  });

  @override
  ConsumerState<PlaystyleVoteSheet> createState() =>
      _PlaystyleVoteSheetState();
}

class _PlaystyleVoteSheetState extends ConsumerState<PlaystyleVoteSheet> {
  Set<String> _selected = {};
  bool _hydrated = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final votesAsync = ref.watch(playstyleVotesProvider(widget.targetUid));

    // Pré-popular com voto atual (uma única vez quando carrega).
    votesAsync.whenData((v) {
      if (!_hydrated) {
        _selected = v.myVotes.toSet();
        _hydrated = true;
      }
    });

    final counts = votesAsync.valueOrNull?.counts ?? const {};
    final total = votesAsync.valueOrNull?.totalVoters ?? 0;
    final active = votesAsync.valueOrNull?.activeKeys ?? const {};

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Votar nas playstyles',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.targetName} • $total voto${total == 1 ? '' : 's'} no total',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final key in PlaystyleKeys.all)
            _PlaystyleVoteRow(
              keyValue: key,
              selected: _selected.contains(key),
              count: counts[key] ?? 0,
              total: total,
              isActive: active.contains(key),
              onTap: () => setState(() {
                if (_selected.contains(key)) {
                  _selected.remove(key);
                } else {
                  _selected.add(key);
                }
              }),
            ),
          const SizedBox(height: 12),
          Text(
            'Uma playstyle vira dourada no card quando recebe '
            '≥3 votos E ≥30% dos votos totais.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          final messenger =
                              ScaffoldMessenger.of(context);
                          setState(() => _saving = true);
                          try {
                            await ref
                                .read(socialRepositoryProvider)
                                .setPlaystyleVote(
                                    targetUid: widget.targetUid,
                                    playstyles: const []);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            messenger.showSnackBar(const SnackBar(
                                content:
                                    Text('Voto removido.')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(e.toString())));
                          } finally {
                            if (mounted) {
                              setState(() => _saving = false);
                            }
                          }
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          final messenger =
                              ScaffoldMessenger.of(context);
                          setState(() => _saving = true);
                          try {
                            await ref
                                .read(socialRepositoryProvider)
                                .setPlaystyleVote(
                                  targetUid: widget.targetUid,
                                  playstyles: _selected.toList(),
                                );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Voto salvo!')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(e.toString())));
                          } finally {
                            if (mounted) {
                              setState(() => _saving = false);
                            }
                          }
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_vote_rounded),
                  label: const Text('Salvar voto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaystyleVoteRow extends StatelessWidget {
  final String keyValue;
  final bool selected;
  final int count;
  final int total;
  final bool isActive;
  final VoidCallback onTap;

  const _PlaystyleVoteRow({
    required this.keyValue,
    required this.selected,
    required this.count,
    required this.total,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct =
        total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.amber.shade100
                    : cs.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Colors.amber.shade700
                      : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: Icon(
                playstyleIcon(keyValue),
                color: isActive
                    ? Colors.amber.shade900
                    : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        playstyleLabel(keyValue),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.workspace_premium_rounded,
                            size: 14, color: Colors.amber.shade700),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.amber.shade700
                                : cs.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count voto${count == 1 ? '' : 's'}'
                    '${total == 0 ? '' : ' • ${(pct * 100).toStringAsFixed(0)}%'}',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
