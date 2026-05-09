import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Toca na aba atual → volta para a raiz dela (mantém stack interno)
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        // ✅ CORREÇÃO PRINCIPAL: só adiciona se for diferente da última
        // Isso PRESERVA todo o histórico de visita entre abas (sem destruir nada)
        if (_tabHistory.isEmpty || _tabHistory.last != index) {
          _tabHistory.add(index);
        }
        _currentIndex = index;
      });
    }
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;

    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator?.canPop() ?? false) {
      // Pop normal dentro da aba atual (não destrói nada)
      currentNavigator?.pop();
    } else if (_tabHistory.length > 1) {
      // ✅ Volta para a aba anterior no histórico (sem destruir stacks internos)
      setState(() {
        _tabHistory.removeLast();
        _currentIndex = _tabHistory.last;
      });
    } else {
      SystemNavigator.pop(); // Sai do app só quando não tem mais histórico
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unreadChats = ref.watch(unreadConversationsCountProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, _buildNavigator),
        ),
        bottomNavigationBar: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            _dragStartX = details.globalPosition.dx;
            _dragDeltaX = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            _dragDeltaX = details.globalPosition.dx - _dragStartX;
          },
          onHorizontalDragEnd: (details) {
            if (_dragDeltaX.abs() > 50) {
              int newIndex;
              if (_dragDeltaX > 0) {
                newIndex = _currentIndex > 0 ? _currentIndex - 1 : 3;
              } else {
                newIndex = _currentIndex < 3 ? _currentIndex + 1 : 0;
              }
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
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: unreadChats > 0,
                    label: Text('$unreadChats'),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unreadChats > 0,
                    label: Text('$unreadChats'),
                    child: const Icon(Icons.chat_bubble_rounded),
                  ),
                  label: 'Chat',
                ),
                const NavigationDestination(
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

  Widget _buildNavigator(int index) {
    const screens = [
      HomeScreen(),
      ExploreScreen(),
      ChatScreen(),
      ProfileScreen(),
    ];
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => screens[index],
      ),
    );
  }
}