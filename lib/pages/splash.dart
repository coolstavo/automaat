import 'package:flutter/material.dart';
import '../theme/logo_widget.dart';
import '../theme/constants.dart';

/// Simpele splash met tagline en NEXT-knop.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 80,
            left: 24,
            child: Text(
              'RIDE IN LUXURY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 2,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: size.height * 0.35,
            child: TextButton(
              onPressed: () => _goToLogin(context),
              child: const Text('NEXT', style: nextTextStyle),
            ),
          ),
          const Positioned(
            left: 24,
            bottom: 30,
            child: MaatAutoLogo(width: 350),
          ),
        ],
      ),
    );
  }
}
