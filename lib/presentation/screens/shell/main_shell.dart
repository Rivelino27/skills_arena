import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

// ─── ARQUITETURA DE NAVEGAÇÃO ────────────────────────────────────────────────
// Baseada no padrão nav27: IndexedStack + Navigator por aba + PopScope manual.
//
// Responsabilidades:
//   1) IndexedStack com Navigator independente por aba (estado preservado)
//   2) PopScope(canPop: false) intercepta QUALQUER back do Android/gesto
//   3) _onPopInvokedWithResult: pop sub-tela → aba anterior → sair do app
//   4) Swipe horizontal na nav bar para trocar abas
//   5) GoRouter atualizado via context.go() para manter redirect de auth
//
// Por que não persistent_bottom_nav_bar_v2:
//   O pacote interceptava todo back event antes dos PopScope das telas filhas,
//   impedindo que _TestCustomBack (via pushWithoutNavBar) funcionasse com gesto.
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _routes = ['/home', '/explore', '/chat', '/profile'];

  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  int _indexFromLocation(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _removeConsecutiveDuplicates() {
    for (int i = _tabHistory.length - 1; i > 0; i--) {
      if (_tabHistory[i] == _tabHistory[i - 1]) {
        _tabHistory.removeAt(i);
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      if (_tabHistory.last != index) {
        // Remove entrada duplicada de abas não-home para evitar histórico cíclico
        if (_tabHistory.contains(index) && index != 0) {
          _tabHistory.remove(index);
        }
        _tabHistory.add(index);
        _removeConsecutiveDuplicates();
      }
      _currentIndex = index;
    });
    context.go(_routes[index]);
  }

  // Única entrada para back do Android, gesto de swipe e botão de sistema.
  // GoRouter's PopScope está acima do shell apenas quando há tela via
  // pushWithoutNavBar — nesse caso o PopScope DAQUELA tela dispara primeiro.
  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;

    final currentNavigator = _navKeys[_currentIndex].currentState;
    if (currentNavigator?.canPop() ?? false) {
      currentNavigator!.pop();
    } else if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _removeConsecutiveDuplicates();
        _currentIndex = _tabHistory.last;
      });
      context.go(_routes[_currentIndex]);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final targetIndex = _indexFromLocation(location);
    final cs = Theme.of(context).colorScheme;

    // Sync quando GoRouter força redirect (ex: login → /home)
    if (_currentIndex != targetIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex != targetIndex) {
          setState(() => _currentIndex = targetIndex);
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, _buildTabNavigator),
        ),
        bottomNavigationBar: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            _dragStartX = d.globalPosition.dx;
            _dragDeltaX = 0.0;
          },
          onHorizontalDragUpdate: (d) {
            _dragDeltaX = d.globalPosition.dx - _dragStartX;
          },
          onHorizontalDragEnd: (_) {
            if (_dragDeltaX.abs() > 50) {
              final newIndex = _dragDeltaX > 0
                  ? (_currentIndex > 0 ? _currentIndex - 1 : 3)
                  : (_currentIndex < 3 ? _currentIndex + 1 : 0);
              _onTabTapped(newIndex);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              backgroundColor: cs.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int index) {
    const screens = [
      HomeScreen(),
      ExploreScreen(),
      ChatScreen(),
      ProfileScreen(),
    ];
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => screens[index],
      ),
    );
  }
}
