import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Toont het AutoMaat logo als SVG vanuit assets.
///
/// Hetzelfde logo wordt hergebruikt op alle schermen; alleen de breedte
/// kan per scherm verschillen.
class MaatAutoLogo extends StatelessWidget {
  /// Standaardbreedte voor het logo.
  static const double defaultWidth = 100;

  /// Breedte van het logo; als null wordt [defaultWidth] gebruikt.
  final double? width;

  const MaatAutoLogo({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_automaat.svg',
      width: width ?? defaultWidth,
      fit: BoxFit.contain,
    );
  }
}
