import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/navigation/custom_back_button.dart';
import 'conversation_screen.dart';

// ─── PADRÃO DE NAVEGAÇÃO ──────────────────────────────────────────────────────
// Aberta via AppNavigator.pushWithoutNavBar() → bottom nav bar OCULTA.
// Usa Navigator.of(context, rootNavigator: true).push(), colocando a tela
// acima do PersistentTabView — a barra de navegação desaparece.
//
// AppBar  : VISÍVEL com CustomBackButton que exibe popup ao voltar.
// Nav bar : OCULTA  (pushWithoutNavBar — navigator raiz)
//
// PopScope(canPop: false) intercepta o gesto/botão de sistema e mostra o popup.
// ─────────────────────────────────────────────────────────────────────────────

class NewConversationScreen extends ConsumerWidget {
  const NewConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitSheet(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: CustomBackButton(
            options: [
              BackMenuOption(
                icon: Icons.chat_bubble_rounded,
                label: 'Ir para Mensagens',
                subtitle: 'Fechar e ver suas conversas',
                onTap: () => Navigator.of(context).pop(),
              ),
              BackMenuOption(
                icon: Icons.explore_outlined,
                label: 'Ir para Explorar',
                subtitle: 'Fechar e abrir o mapa',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          title: const Text('Nova Conversa'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        body: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (users) {
            if (users.isEmpty) {
              return const Center(child: Text('Nenhum usuário encontrado.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) => _UserTile(
                user: users[i],
                onTap: () => _startChat(context, ref, users[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _startChat(
      BuildContext context, WidgetRef ref, UserModel user) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final conv = await ref.read(chatRepositoryProvider).getOrCreateConversation(
          otherUid: user.id,
          otherName: user.name ?? 'Usuário',
          otherPhoto: user.photoUrl,
        );

    if (!context.mounted) return;

    // Pop esta tela (root navigator) e abre o chat COM nav bar na aba Chat
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!context.mounted) return;

    AppNavigator.pushWithNavBar(
      context,
      ConversationScreen(chatId: conv.id, conv: conv, myUid: myUid),
    );
  }

  void _showExitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
              title: const Text('Voltar'),
              subtitle: const Text('Fechar nova conversa'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.chat_bubble_rounded, size: 18)),
              title: const Text('Ir para Mensagens'),
              subtitle: const Text('Ver lista de conversas'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        backgroundColor: cs.primaryContainer,
        child: user.photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: cs.onPrimaryContainer),
              )
            : null,
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(user.email,
          style: TextStyle(color: cs.onSurfaceVariant)),
      trailing: Icon(Icons.chat_bubble_outline_rounded, color: cs.primary),
      onTap: onTap,
    );
  }
}
