import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_models.dart';
import 'controllers/app_controller.dart';
import 'core/theme.dart';
import 'views/widgets/dock_nav.dart';
import 'views/widgets/incoming_request_alert.dart';

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
  // ProviderScope makes every Riverpod provider (see lib/controllers/) available
  // to the widget tree below it — this replaces the old `ChangeNotifierProvider`
  // from the `provider` package used in the previous architecture.
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
      home: const AppShell(),
    );
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
    // Until an admin activates the account, every screen except Profile
    // (where document verification lives) and the pre-account login/signup
    // screens is locked — this holds regardless of how `app.screen` got
    // set, so there's no separate path that could leak Home/Trips/etc through.
    final locked = app.accountStatus != AccountStatus.active && !_preAccountScreens.contains(app.screen);
    final screen = locked ? const ProfileScreen() : (_screens[app.screen] ?? const HomeScreen());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              // Default layoutBuilder centers children with loose constraints,
              // which shrinks+centers a screen shorter than the viewport instead
              // of filling it — force every screen to fill the full available area.
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
            const Positioned(left: 14, right: 14, bottom: 15, child: DockNav()),
          if (app.alertOpen) const IncomingRequestAlert(),
        ],
      ),
    );
  }
}
