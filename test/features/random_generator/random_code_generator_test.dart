import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/random_generator/domain/random_code_generator.dart';

void main() {
  final Random random = Random(7);

  test('returns an empty string for a non-positive length', () {
    expect(
      generateRandomCode(length: 0, alphanumeric: false, random: random),
      isEmpty,
    );
  });

  test('numeric mode only produces digits of the requested length', () {
    final String code = generateRandomCode(
      length: 30,
      alphanumeric: false,
      random: random,
    );

    expect(code.length, 30);
    expect(code.split('').every((c) => kNumericChars.contains(c)), isTrue);
  });

  test('alphanumeric mode only produces characters from its pool', () {
    final String code = generateRandomCode(
      length: 30,
      alphanumeric: true,
      random: random,
    );

    expect(code.length, 30);
    expect(
      code.split('').every((c) => kAlphanumericChars.contains(c)),
      isTrue,
    );
  });
}
