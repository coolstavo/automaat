import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/splash.dart';
import 'pages/login.dart';
import 'pages/register.dart';

/// Entry‑point van de AutoMaat app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutoMaatApp());
}

/// Root widget van de app; zet thema en routes op.
class AutoMaatApp extends StatelessWidget {
  const AutoMaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoMaat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}
