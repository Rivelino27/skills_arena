import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

// ─── HISTÓRICO DE ABAS ───────────────────────────────────────────────────────
// O próprio pacote gerencia:
//   1) Pop de sub-telas da aba atual (via NavigatorConfig.navigatorKey)
//   2) Histórico de abas (PersistentTabController.historyLength)
//   3) Saída do app quando histórico está vazio e não há sub-telas
//
// Nossa responsabilidade: sincronizar o estado do GoRouter (URL)
// via onTabChanged para que o redirect de auth continue funcionando.
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  // child vem do ShellRoute do GoRouter — não é usado diretamente
  // pois o PersistentTabView gerencia a exibição das abas.
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _routes = ['/home', '/explore', '/chat', '/profile'];

  late final PersistentTabController _controller;

  // Navigator keys passados via NavigatorConfig — usados pelo pacote para
  // verificar e popar sub-telas ao pressionar voltar.
  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  int _indexFromLocation(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(
      initialIndex: 0,
      historyLength: 5,
      // Ao tocar na Home, limpa o histórico → próximo voltar sai do app
      clearHistoryOnInitialIndex: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);
    final cs = Theme.of(context).colorScheme;

    // Sincroniza o controller com a rota atual do GoRouter
    // (ex: redirect de auth para /home)
    if (_controller.index != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.jumpToTab(currentIndex);
      });
    }

    return PersistentTabView(
      controller: _controller,
      // O pacote gerencia o botão voltar:
      //   - pop sub-tela se houver
      //   - navegar aba anterior via historyLength
      //   - sair do app se não há mais histórico
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      // Mantém URL do GoRouter sincronizada quando o pacote troca de aba
      onTabChanged: (index) => context.go(_routes[index]),
      backgroundColor: cs.surface,
      tabs: [
        PersistentTabConfig(
          screen: const HomeScreen(),
          navigatorConfig: NavigatorConfig(navigatorKey: _navKeys[0]),
          item: ItemConfig(
            icon: const Icon(Icons.home_rounded),
            inactiveIcon: const Icon(Icons.home_outlined),
            title: 'Home',
            activeForegroundColor: cs.primary,
            inactiveForegroundColor: cs.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: const ExploreScreen(),
          navigatorConfig: NavigatorConfig(navigatorKey: _navKeys[1]),
          item: ItemConfig(
            icon: const Icon(Icons.explore_rounded),
            inactiveIcon: const Icon(Icons.explore_outlined),
            title: 'Explorar',
            activeForegroundColor: cs.primary,
            inactiveForegroundColor: cs.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: const ChatScreen(),
          navigatorConfig: NavigatorConfig(navigatorKey: _navKeys[2]),
          item: ItemConfig(
            icon: const Icon(Icons.chat_bubble_rounded),
            inactiveIcon: const Icon(Icons.chat_bubble_outline_rounded),
            title: 'Chat',
            activeForegroundColor: cs.primary,
            inactiveForegroundColor: cs.onSurfaceVariant,
          ),
        ),
        PersistentTabConfig(
          screen: const ProfileScreen(),
          navigatorConfig: NavigatorConfig(navigatorKey: _navKeys[3]),
          item: ItemConfig(
            icon: const Icon(Icons.person_rounded),
            inactiveIcon: const Icon(Icons.person_outline_rounded),
            title: 'Perfil',
            activeForegroundColor: cs.primary,
            inactiveForegroundColor: cs.onSurfaceVariant,
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style1BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
        ),
      ),
    );
  }
}
