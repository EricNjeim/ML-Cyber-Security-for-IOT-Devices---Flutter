import 'package:flutter/material.dart';
import 'package:iotframework/core/util/constants.dart';
import 'package:iotframework/features/dashboard/presentation/screens/dashboard_screen_new.dart';
import 'package:iotframework/presentation/features/auth/screens/login_screen.dart';
import 'package:iotframework/presentation/features/auth/screens/splash_screen.dart';
import 'package:iotframework/features/devices/presentation/screens/devices_screen.dart';
import 'package:iotframework/features/network_map/presentation/screens/network_map_screen.dart';
import 'package:iotframework/features/security/presentation/screens/security_logs_screen.dart';

/// Application router for navigation
class AppRouter {
  static const String mainRoute = AppConstants.mainRoute;
  static const String loginRoute = AppConstants.loginRoute;
  static const String networkRoute = '/network';
  static const String splashRoute = AppConstants.splashRoute;
  static const String logsRoute = '/logs';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mainRoute:
        // Check if tab index is provided in the arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final tabIndex =
            args != null && args.containsKey('tab') ? args['tab'] as int : 0;
        return MaterialPageRoute(
            builder: (_) => MainScreen(initialTab: tabIndex));
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case networkRoute:
        return MaterialPageRoute(
            builder: (_) => const MainScreen(initialTab: 4));
      case logsRoute:
        return MaterialPageRoute(builder: (_) => const SecurityLogsScreen());
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToReplacement(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState!
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  static void goBack() {
    navigatorKey.currentState!.pop();
  }
}

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  final int initialTab;

  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SecurityLogsScreen(),
    const Center(child: Text('Analytics')),
    const DevicesScreen(),
    const NetworkMapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SecureIOT"),
        backgroundColor: Colors.greenAccent,
        automaticallyImplyLeading: false,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.network_check),
            label: 'Network',
          ),
        ],
      ),
    );
  }
}
