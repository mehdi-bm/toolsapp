import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/password_generator/domain/password_generator.dart';

void main() {
  final Random random = Random(42);

  test('returns an empty string when no character category is selected', () {
    final String password = generatePassword(
      length: 16,
      useUppercase: false,
      useLowercase: false,
      useNumbers: false,
      useSymbols: false,
      random: random,
    );

    expect(password, isEmpty);
  });

  test('returns an empty string for a non-positive length', () {
    final String password = generatePassword(
      length: 0,
      useUppercase: true,
      useLowercase: true,
      useNumbers: true,
      useSymbols: true,
      random: random,
    );

    expect(password, isEmpty);
  });

  test('produces a password of the requested length', () {
    final String password = generatePassword(
      length: 24,
      useUppercase: true,
      useLowercase: true,
      useNumbers: true,
      useSymbols: true,
      random: random,
    );

    expect(password.length, 24);
  });

  test('only uses digits when only the numbers category is selected', () {
    final String password = generatePassword(
      length: 40,
      useUppercase: false,
      useLowercase: false,
      useNumbers: true,
      useSymbols: false,
      random: random,
    );

    expect(password.split('').every((c) => kNumberChars.contains(c)), isTrue);
  });

  test('only uses letters from the selected case categories', () {
    final String password = generatePassword(
      length: 40,
      useUppercase: true,
      useLowercase: true,
      useNumbers: false,
      useSymbols: false,
      random: random,
    );

    final String allowed = kUppercaseChars + kLowercaseChars;
    expect(password.split('').every((c) => allowed.contains(c)), isTrue);
  });
}
