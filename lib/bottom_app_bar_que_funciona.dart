/* 

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _isLoggedIn() async {
    String? logado = await _secureStorage.read(key: "logado");
    return logado == "true";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Esta linha remove a faixa
      title: 'Flutter Bottom Nav with Nested Navigation',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 19, 12, 37),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 23, 38, 112),
          elevation: 0,
          centerTitle: true,
        ),
        primaryColor: Colors.teal,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 61, 55, 151),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data!) {
            return const MyHomePage();
          } else {
            return const LoginPageSS();
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  double _dragStartX = 0.0;
  double _dragDeltaX = 0.0;

  final ValueNotifier<int> _counterNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirst = prefs.getBool('first_launch');
    if (isFirst == null || isFirst) {
      await _requestPermissions();
      await prefs.setBool('first_launch', false);
    }
  }

  Future<int> _getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      try {
        final int version = await MethodChannel('com.example.nav27/sdk_version').invokeMethod('getSdkVersion');
        return version;
      } catch (e) {
        print('Erro ao obter SDK version: $e');
        return 0;
      }
    }
    return 0;
  }

  Future<void> _requestPermissions() async {
    // Solicitar permissão de armazenamento com checagem de versão Android
    Permission storagePermission;
    if (Platform.isAndroid) {
      int sdkVersion = await _getAndroidSdkVersion();
      if (sdkVersion >= 30) {
        storagePermission = Permission.manageExternalStorage;
      } else {
        storagePermission = Permission.storage;
      }
    } else {
      storagePermission = Permission.storage; // Para iOS ou outros, adapte se necessário
    }

    var storageStatus = await storagePermission.request();
    if (storageStatus.isDenied) {
      // Mostrar diálogo explicando a necessidade
      if (await storagePermission.shouldShowRequestRationale) {
        // Explicar e pedir novamente
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissão de Armazenamento Necessária'),
              content: const Text('Este app precisa de acesso ao armazenamento para ler e salvar arquivos.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await storagePermission.request();
                  },
                  child: const Text('Permitir'),
                ),
              ],
            ),
          );
        }
      } else {
        // Redirecionar para configurações
        openAppSettings();
      }
    }

    // Solicitar permissão de localização
    var locationStatus = await Permission.location.request();
    if (locationStatus.isDenied) {
      // Similar: mostrar explicação
    }

    // Solicitar permissão de notificações
    var notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      // Similar: mostrar explicação
    }

    // Nota: Para Android 11+, use MANAGE_EXTERNAL_STORAGE para acesso completo.
    // Adicione <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/> no manifest.
    // Para exportar arquivos, use Storage Access Framework (SAF) se necessário.
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, (index) => _buildNavigator(index)),
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
            if (_dragDeltaX.abs() > 50) { // Limite de 50 pixels para detectar swipe
              int newIndex;
              if (_dragDeltaX > 0) {
                // Swipe para a direita: aba anterior ou circular para a última
                newIndex = _currentIndex > 0 ? _currentIndex - 1 : 3;
              } else {
                // Swipe para a esquerda: aba próxima ou circular para a primeira
                newIndex = _currentIndex < 3 ? _currentIndex + 1 : 0;
              }
              _onTabTapped(newIndex);
            }
          },
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.white,
            backgroundColor: Colors.black,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigator(int index) {
    Widget initialScreen;
    switch (index) {
      case 0:
        initialScreen = const HomeScreen();
        break;
      case 1:
        initialScreen = const SearchScreen();
        break;
      case 2:
        initialScreen = ProfileScreen(counterNotifier: _counterNotifier);
        break;
      case 3:
        initialScreen = SettingsScreen(counterNotifier: _counterNotifier);
        break;
      default:
        initialScreen = const HomeScreen();
    }
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => initialScreen),
    );
  }
} 



*/