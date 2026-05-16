import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/team_repository.dart';
import 'team_detail_screen.dart';

/// Premium-only screen for creating a team. The caller (TeamsHubScreen)
/// already gates non-premium users via a paywall dialog, so this just
/// trusts that the user is allowed in.
class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _nameCtrl = TextEditingController();
  String _sport = kSportsList.first;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final res = await ref
        .read(teamRepositoryProvider)
        .createTeam(name: name, sport: _sport);
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (team) {
        messenger.showSnackBar(
          SnackBar(content: Text('Time "${team.name}" criado!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => TeamDetailScreen(teamId: team.id)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar time')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do time',
                hintText: 'Ex: Bola na Trave FC',
                prefixIcon: Icon(Icons.shield_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _sport,
              decoration: const InputDecoration(
                labelText: 'Esporte',
                prefixIcon: Icon(Icons.sports_rounded),
                border: OutlineInputBorder(),
              ),
              items: kSportsList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _sport = v ?? _sport),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed:
                  (_saving || _nameCtrl.text.trim().isEmpty) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_rounded),
              label: const Text('Criar time'),
            ),
          ],
        ),
      ),
    );
  }
}
