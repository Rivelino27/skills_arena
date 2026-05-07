import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  void _removeConsecutiveDuplicates() {
    for (int i = _tabHistory.length - 1; i > 0; i--) {
      if (_tabHistory[i] == _tabHistory[i - 1]) {
        _tabHistory.removeAt(i);
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        if (_tabHistory.last != index) {
          if (_tabHistory.contains(index) && index != 0) {
            _tabHistory.remove(index);
          }
          _tabHistory.add(index);
          _removeConsecutiveDuplicates();
        }
        _currentIndex = index;
      });
    }
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;

    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator?.canPop() ?? false) {
      currentNavigator?.pop();
    } else if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _removeConsecutiveDuplicates();
        _currentIndex = _tabHistory.last;
      });
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
