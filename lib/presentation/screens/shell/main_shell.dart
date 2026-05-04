import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _routes = ['/home', '/explore', '/chat', '/profile'];

  late final PersistentTabController _controller;

  int _indexFromLocation(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
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

    if (_controller.index != currentIndex) {
      _controller.jumpToTab(currentIndex);
    }

    return PersistentTabView(
      controller: _controller,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      onTabChanged: (index) => context.go(_routes[index]),
      backgroundColor: cs.surface,
      tabs: [
        PersistentTabConfig(
          screen: const HomeScreen(),
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
            top: BorderSide(
              color: cs.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
