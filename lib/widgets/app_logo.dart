import 'package:flutter/material.dart';

/// The Paradise Funeral Home logo.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
