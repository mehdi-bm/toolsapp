const List<String> _kCompassDirectionLabels = [
  'شمال',
  'شمال‌شرقی',
  'شرق',
  'جنوب‌شرقی',
  'جنوب',
  'جنوب‌غربی',
  'غرب',
  'شمال‌غربی',
];

String compassDirectionLabel(double heading) {
  final int index = (((heading % 360) + 22.5) / 45).floor() % 8;
  return _kCompassDirectionLabels[index];
}
