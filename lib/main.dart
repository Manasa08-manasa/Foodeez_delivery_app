import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_models.dart';
import 'controllers/app_controller.dart';
import 'core/theme.dart';
import 'core/responsive.dart';
import 'views/widgets/dock_nav.dart';
import 'views/widgets/incoming_request_alert.dart';

import 'views/screens/splash_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/signup_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/trip_screen.dart';
import 'views/screens/trip_done_screen.dart';
import 'views/screens/earnings_screen.dart';
import 'views/screens/history_screen.dart';
import 'views/screens/ratings_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/help_screen.dart';

void main() {
  runApp(const ProviderScope(child: FoodeezRiderApp()));
}

class FoodeezRiderApp extends StatelessWidget {
  const FoodeezRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodeez Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent, primary: AppColors.accent),
        fontFamily: 'Plus Jakarta Sans',
        splashFactory: InkRipple.splashFactory,
      ),
      home: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _showSplash = true;

  void _onSplashComplete() {
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }
    return const AppShell();
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = {
    'login': LoginScreen(),
    'signup': SignupScreen(),
    'home': HomeScreen(),
    'trip': TripScreen(),
    'tripdone': TripDoneScreen(),
    'earnings': EarningsScreen(),
    'history': HistoryScreen(),
    'ratings': RatingsScreen(),
    'profile': ProfileScreen(),
    'help': HelpScreen(),
  };

  static const _preAccountScreens = {'login', 'signup'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final locked = app.accountStatus != AccountStatus.active && !_preAccountScreens.contains(app.screen);
    final screen = locked ? const ProfileScreen() : (_screens[app.screen] ?? const HomeScreen());
    final dockBottom = Responsive.isTablet(context) ? 24.0 : 15.0;
    final dockHorizontal = Responsive.isTablet(context) ? 48.0 : 14.0;

    return ResponsiveShell(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                layoutBuilder: (currentChild, previousChildren) {
                  final children = <Widget>[...previousChildren];
                  if (currentChild != null) {
                    children.add(currentChild);
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: children,
                  );
                },
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(key: ValueKey(app.screen), child: screen),
              ),
            ),
            if (app.showTabBar)
              Positioned(
                left: dockHorizontal,
                right: dockHorizontal,
                bottom: dockBottom,
                child: const DockNav(),
              ),
            if (app.alertOpen) const IncomingRequestAlert(),
          ],
        ),
      ),
    );
  }
}
