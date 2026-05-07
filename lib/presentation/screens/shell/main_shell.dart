import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tab_nav_provider.dart';
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
  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  void _onTabTapped(int index) {
    final current = ref.read(tabNavProvider).currentIndex;
    if (index == current) {
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    ref.read(tabNavProvider.notifier).selectTab(index);
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;

    final current = ref.read(tabNavProvider).currentIndex;
    final currentNavigator = _navKeys[current].currentState;
    if (currentNavigator?.canPop() ?? false) {
      currentNavigator?.pop();
      return;
    }

    final stepped = ref.read(tabNavProvider.notifier).stepBack();
    if (stepped) return;

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentIndex = ref.watch(tabNavProvider).currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
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
                  ? (currentIndex > 0 ? currentIndex - 1 : 3)
                  : (currentIndex < 3 ? currentIndex + 1 : 0);
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
              selectedIndex: currentIndex,
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
