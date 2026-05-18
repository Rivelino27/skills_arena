import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../providers/chat_provider.dart';

/// Bottom sheet onde o capitão escolhe um usuário para convidar para
/// o time. Carrega usuários do `usersStreamProvider` (excluindo já-
/// membros e o próprio capitão), filtra por busca de texto e dispara
/// o convite via `TeamRepository.sendInvite`.
class InviteMemberSheet extends ConsumerStatefulWidget {
  final TeamModel team;
  const InviteMemberSheet({super.key, required this.team});

  @override
  ConsumerState<InviteMemberSheet> createState() =>
      _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _sendingTo;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send(UserModel u) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingTo = u.id);
    final res = await ref
        .read(teamRepositoryProvider)
        .sendInvite(teamId: widget.team.id, invitee: u);
    if (!mounted) return;
    setState(() => _sendingTo = null);
    res.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger.showSnackBar(SnackBar(
          content: Text('Convite enviado para ${u.name ?? "Jogador"}.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(usersStreamProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final memberIds = widget.team.memberIds.toSet();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text('Convidar para ${widget.team.name}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar usuário…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (users) {
                  var list = users
                      .where((u) =>
                          u.id != myUid && !memberIds.contains(u.id))
                      .toList();
                  if (_query.isNotEmpty) {
                    final q = _query.toLowerCase();
                    list = list.where((u) {
                      return (u.name ?? '').toLowerCase().contains(q) ||
                          (u.username ?? '').toLowerCase().contains(q) ||
                          (u.searchableByEmail &&
                              u.email.toLowerCase().contains(q));
                    }).toList();
                  }
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('Nenhum usuário disponível.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 64),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      final sending = _sendingTo == u.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u.photoUrl != null
                              ? NetworkImage(u.photoUrl!)
                              : null,
                          backgroundColor: cs.primaryContainer,
                          child: u.photoUrl == null
                              ? Text((u.name ?? '?').isNotEmpty
                                  ? (u.name ?? '?')[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(u.name ?? 'Usuário'),
                        subtitle: u.username != null
                            ? Text('@${u.username}')
                            : Text(u.email,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant)),
                        trailing: sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : FilledButton.tonal(
                                onPressed: _sendingTo != null
                                    ? null
                                    : () => _send(u),
                                child: const Text('Convidar'),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
