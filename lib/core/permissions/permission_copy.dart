import 'package:flutter/material.dart';

/// Centralizes the Persian copy and icon shown by [PermissionGate] for each
/// permission the app requests, so every feature that needs the same
/// permission shows identical, consistently-worded messaging.
class PermissionCopy {
  const PermissionCopy({
    required this.icon,
    required this.deniedMessage,
    required this.permanentlyDeniedMessage,
  });

  final IconData icon;
  final String deniedMessage;
  final String permanentlyDeniedMessage;
}

const PermissionCopy kCameraPermissionCopy = PermissionCopy(
  icon: Icons.camera_alt_outlined,
  deniedMessage: 'برای استفاده از این ابزار، به دسترسی دوربین نیاز است.',
  permanentlyDeniedMessage:
      'دسترسی به دوربین رد شده است. برای استفاده از این ابزار، دسترسی را '
      'از تنظیمات برنامه فعال کنید.',
);

const PermissionCopy kMicrophonePermissionCopy = PermissionCopy(
  icon: Icons.mic_none_rounded,
  deniedMessage: 'برای استفاده از این ابزار، به دسترسی میکروفون نیاز است.',
  permanentlyDeniedMessage:
      'دسترسی به میکروفون رد شده است. برای استفاده از این ابزار، دسترسی '
      'را از تنظیمات برنامه فعال کنید.',
);
