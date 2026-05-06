import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/user_model.dart';
import '../../providers/chat_provider.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() =>
      _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Usuários')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome, @usuário ou e-mail…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (users) {
                if (_query.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Digite um nome ou @usuário',
                            style: TextStyle(
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                final filtered = users.where((u) {
                  final nameMatch =
                      (u.name ?? '').toLowerCase().contains(_query);
                  final usernameMatch =
                      (u.username ?? '').toLowerCase().contains(_query);
                  final emailMatch = u.searchableByEmail &&
                      u.email.toLowerCase().contains(_query);
                  return nameMatch || usernameMatch || emailMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Nenhum usuário encontrado.',
                        style:
                            TextStyle(color: cs.onSurfaceVariant)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) => _UserTile(
                    user: filtered[i],
                    onTap: () => AppNavigator.pushWithNavBar(
                      context,
                      UserProfileScreen(userId: filtered[i].id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = user.name ?? 'Usuário';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        backgroundColor: cs.primaryContainer,
        child: user.photoUrl == null
            ? Text(initial,
                style: TextStyle(color: cs.onPrimaryContainer))
            : null,
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        user.username != null ? '@${user.username}' : user.email,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
