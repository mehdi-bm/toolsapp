/// Persian/Arabic letters have no case mapping in Unicode, so
/// [String.toUpperCase]/[String.toLowerCase] already leave them untouched —
/// only Latin characters in mixed text are affected.
String toUpperCaseSafe(String text) => text.toUpperCase();

String toLowerCaseSafe(String text) => text.toLowerCase();

/// Capitalizes the first letter of each whitespace-separated word while
/// preserving the original spacing exactly (no whitespace is collapsed).
String toTitleCase(String text) {
  return text.replaceAllMapped(RegExp(r'\S+'), (Match match) {
    final String word = match.group(0)!;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  });
}
