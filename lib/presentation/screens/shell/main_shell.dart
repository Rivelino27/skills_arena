import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

// ─── POR QUE WidgetsBindingObserver e não PopScope ───────────────────────────
// GoRouter instala seu próprio BackButtonDispatcher. Quando a pilha GoRouter
// tem apenas um route (/app), o GoRouter retorna false sem chamar maybePop(),
// então PopScope.onPopInvokedWithResult nunca dispara.
// WidgetsBindingObserver.didPopRoute() é chamado ANTES do GoRouter processar
// o back event. Usamos isso para tratar toda a navegação de abas/sub-telas.
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Intercepta back do Android ANTES do GoRouter.
  // Retorna true = evento consumido (GoRouter não processa).
  // Retorna false = GoRouter processa (ex: tela com PopScope(canPop:false) acima).
  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;

    // Se há algo acima do shell no navigator raiz (ex: _TestCustomBack via
    // pushWithoutNavBar), deixa o GoRouter + PopScope daquela tela lidar.
    final rootNav = Navigator.maybeOf(context, rootNavigator: true);
    if (rootNav == null) return false;
    if (rootNav.canPop()) return false;

    // Sub-tela dentro da aba atual (via pushWithNavBar)
    final tabNav = _navKeys[_currentIndex].currentState;
    if (tabNav?.canPop() ?? false) {
      tabNav!.pop();
      return true;
    }

    // Aba anterior no histórico
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _removeConsecutiveDuplicates();
        _currentIndex = _tabHistory.last;
      });
      return true;
    }

    // Sem mais histórico → sair do app
    SystemNavigator.pop();
    return true;
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
        if (_tabHistory.contains(index) && index != 0) {
          _tabHistory.remove(index);
        }
        _tabHistory.add(index);
        _removeConsecutiveDuplicates();
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
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
