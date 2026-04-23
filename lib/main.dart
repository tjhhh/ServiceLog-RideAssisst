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
import 'screens/add_service_screen.dart';
import 'providers/settings_provider.dart';

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
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideAssist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(settings.themeColorValue), // Dinamis dari settings
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

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ManageScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
    _NavItem(icon: Icons.motorcycle_outlined, activeIcon: Icons.motorcycle, label: 'Manage'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _CenterAddFAB(primaryColor: primary),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        primaryColor: primary,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Center Add FAB ──────────────────────────────────────────────────────────────
class _CenterAddFAB extends StatefulWidget {
  final Color primaryColor;
  const _CenterAddFAB({required this.primaryColor});

  @override
  State<_CenterAddFAB> createState() => _CenterAddFABState();
}

class _CenterAddFABState extends State<_CenterAddFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _shadow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.87).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _shadow = Tween<double>(begin: 20.0, end: 6.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    // Press down visually, then spring back while navigating
    _ctrl.forward().then((_) {
      if (mounted) _ctrl.reverse();
    });
    // Navigate immediately for snappy feel
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddServiceScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: (_) => _ctrl.forward(),
            onTapUp: (_) => _onTap(),
            onTapCancel: () => _ctrl.reverse(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary,
                    Color.lerp(primary, Colors.black, 0.18)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: _shadow.value,
                    spreadRadius: 0,
                    offset: Offset(0, _shadow.value * 0.4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: null, // handled by GestureDetector above
                  splashColor: Colors.white.withOpacity(0.25),
                  highlightColor: Colors.white.withOpacity(0.08),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 30),
                      Text(
                        'Servis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Custom Bottom Nav Bar ───────────────────────────────────────────────────────
class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final Color primaryColor;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Split items 2 left | 2 right (FAB occupies center slot)
    final leftItems = items.sublist(0, 2);
    final rightItems = items.sublist(2, 4);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              // Left nav items
              ...leftItems.asMap().entries.map((e) {
                final idx = e.key;         // 0 → Home, 1 → History
                final item = e.value;
                final isActive = currentIndex == idx;
                return _NavButton(
                  item: item,
                  isActive: isActive,
                  primaryColor: primaryColor,
                  onTap: () => onTap(idx),
                );
              }),

              // Center spacer for FAB
              const Expanded(child: SizedBox()),

              // Right nav items
              ...rightItems.asMap().entries.map((e) {
                final idx = e.key + 2;     // 2 → Manage, 3 → Settings
                final item = e.value;
                final isActive = currentIndex == idx;
                return _NavButton(
                  item: item,
                  isActive: isActive,
                  primaryColor: primaryColor,
                  onTap: () => onTap(idx),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color primaryColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: primaryColor.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  key: ValueKey(isActive),
                  color: isActive ? primaryColor : const Color(0xFF94A3B8),
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? primaryColor : const Color(0xFF94A3B8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
