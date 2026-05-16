import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sports_venue_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/sports_provider.dart';
import '../../providers/team_provider.dart';

/// Bottom sheet that lets a team member propose a match against
/// another team at a venue, on a chosen date/time. Three steps:
///   1. Pick the opponent team (excluding any team I'm already in)
///   2. Pick the venue (filtered by the team's sport)
///   3. Pick the start time (defaults to next round hour, today+1)
class ProposeMatchSheet extends ConsumerStatefulWidget {
  final TeamModel myTeam;
  const ProposeMatchSheet({super.key, required this.myTeam});

  @override
  ConsumerState<ProposeMatchSheet> createState() =>
      _ProposeMatchSheetState();
}

class _ProposeMatchSheetState extends ConsumerState<ProposeMatchSheet> {
  TeamModel? _opponent;
  SportsVenueModel? _venue;
  late DateTime _startAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startAt =
        DateTime(now.year, now.month, now.day + 1, (now.hour + 1) % 24);
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (pickedTime == null) return;
    setState(() {
      _startAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_opponent == null || _venue == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final res = await ref.read(teamRepositoryProvider).proposeMatch(
          myTeamId: widget.myTeam.id,
          opponentTeamId: _opponent!.id,
          venueId: _venue!.id,
          venueName: _venue!.name,
          startAt: _startAt,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Desafio enviado!')),
        );
      },
    );
  }

  String _fmtDateTime() {
    final hh = '${_startAt.hour.toString().padLeft(2, '0')}:'
        '${_startAt.minute.toString().padLeft(2, '0')}';
    return '${_startAt.day.toString().padLeft(2, '0')}/'
        '${_startAt.month.toString().padLeft(2, '0')}/'
        '${_startAt.year} $hh';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allTeams = ref.watch(allTeamsProvider).valueOrNull ?? const [];
    // Exclude any team I'm already in (can't challenge myself) and
    // teams of a different sport (mixing rules).
    final candidates = allTeams
        .where((t) =>
            t.id != widget.myTeam.id && t.sport == widget.myTeam.sport)
        .toList();
    final venues = ref.watch(venuesStreamProvider).valueOrNull ?? const [];
    final venueCandidates =
        venues.where((v) => v.sport == widget.myTeam.sport).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
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
          const SizedBox(height: 16),
          Text('Propor desafio',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Time: ${widget.myTeam.name} · ${widget.myTeam.sport}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // ── Opponent picker ──
          DropdownButtonFormField<TeamModel>(
            initialValue: _opponent,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Time adversário',
              prefixIcon: Icon(Icons.shield_rounded),
              border: OutlineInputBorder(),
            ),
            items: candidates
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _opponent = v),
          ),
          if (candidates.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Nenhum outro time de ${widget.myTeam.sport} disponível.',
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          // ── Venue picker ──
          DropdownButtonFormField<SportsVenueModel>(
            initialValue: _venue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Quadra',
              prefixIcon: Icon(Icons.place_rounded),
              border: OutlineInputBorder(),
            ),
            items: venueCandidates
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _venue = v),
          ),
          if (venueCandidates.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Nenhuma quadra cadastrada para ${widget.myTeam.sport}.',
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Data e hora'),
            subtitle: Text(_fmtDateTime()),
            trailing: const Icon(Icons.edit_rounded),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (_opponent == null ||
                    _venue == null ||
                    _saving)
                ? null
                : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: const Text('Enviar desafio'),
          ),
        ],
      ),
    );
  }
}
