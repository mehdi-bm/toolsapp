import 'package:flutter/material.dart';

/// Purely decorative scanning-frame overlay drawn on top of a camera preview.
class ScannerFrameOverlay extends StatelessWidget {
  const ScannerFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
