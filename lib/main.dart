import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/manage_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check Session Expiration for "Remember Me"
  if (FirebaseAuth.instance.currentUser != null) {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      final loginStr = prefs.getString('login_timestamp');
      if (loginStr != null) {
        final loginDate = DateTime.parse(loginStr);
        final diff = DateTime.now().difference(loginDate);
        if (diff.inDays >= 30) {
          // Session expired after 30 days
          await FirebaseAuth.instance.signOut();
          await prefs.clear();
        }
      }
    } else {
      // If user did not check 'Remember Me', logout when app restarts
      await FirebaseAuth.instance.signOut();
    }
  }

  runApp(
    // ProviderScope diperlukan untuk Riverpod
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the auth state stream
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideAssist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052CC), // Warna biru dari desain UI
          surface: const Color(0xFFF8F9FB),
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Bisa diganti sesuai kebutuhan font nantinya
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainLayout();
          }
          return const LoginScreen();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, trace) =>
            Scaffold(body: Center(child: Text('Failed to load user: $e'))),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const ManageScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // To prevent shifting items and force show item text on > 3 items
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: 'HISTORY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.motorcycle_outlined),
            activeIcon: Icon(Icons.motorcycle),
            label: 'MANAGE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}
