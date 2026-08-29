class TextCleanerOptions {
  const TextCleanerOptions({
    this.collapseSpaces = true,
    this.removeEmptyLines = true,
    this.normalizeLineBreaks = true,
    this.trimEdges = true,
    this.normalizeArabicChars = true,
  });

  final bool collapseSpaces;
  final bool removeEmptyLines;
  final bool normalizeLineBreaks;
  final bool trimEdges;
  final bool normalizeArabicChars;
}

String cleanText(String input, TextCleanerOptions options) {
  String result = input;

  if (options.normalizeLineBreaks) {
    result = result.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
  if (options.normalizeArabicChars) {
    result = result.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
  }
  if (options.collapseSpaces) {
    // Only horizontal whitespace is collapsed so line structure survives.
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
  }
  if (options.removeEmptyLines) {
    result = result
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
  if (options.trimEdges) {
    result = result.trim();
  }

  return result;
}
