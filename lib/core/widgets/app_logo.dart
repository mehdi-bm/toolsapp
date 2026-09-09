import 'package:flutter/material.dart';

/// The same brand asset used by the Android launcher.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.24),
    child: Image.asset(
      'assets/icon/icon.png',
      width: size,
      height: size,
      excludeFromSemantics: true,
    ),
  );
}
