import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'views/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0A0E14),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: FoodeezRiderApp()));
}

/// First UI from main is always SplashScreen — no intermediate screens.
class FoodeezRiderApp extends StatefulWidget {
  const FoodeezRiderApp({super.key});

  @override
  State<FoodeezRiderApp> createState() => _FoodeezRiderAppState();
}

class _FoodeezRiderAppState extends State<FoodeezRiderApp> {
  static const _bg = Color(0xFF0A0E14);

  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodeez Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _showSplash ? _bg : Colors.white,
        canvasColor: _showSplash ? _bg : Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF112D46),
          primary: const Color(0xFF112D46),
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      // Direct: SplashScreen is home from first frame
      home: _showSplash
          ? SplashScreen(
              onComplete: () {
                if (mounted) setState(() => _showSplash = false);
              },
            )
          : const AppShell(),
    );
  }
}
