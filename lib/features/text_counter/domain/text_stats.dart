class TextStats {
  const TextStats({
    required this.characters,
    required this.charactersNoSpaces,
    required this.words,
    required this.lines,
  });

  final int characters;
  final int charactersNoSpaces;
  final int words;
  final int lines;
}

TextStats computeTextStats(String text) {
  final int characters = text.length;
  final int charactersNoSpaces = text.replaceAll(RegExp(r'\s'), '').length;
  final String trimmed = text.trim();
  final int words = trimmed.isEmpty
      ? 0
      : trimmed.split(RegExp(r'\s+')).length;
  final int lines = text.isEmpty ? 0 : text.split('\n').length;

  return TextStats(
    characters: characters,
    charactersNoSpaces: charactersNoSpaces,
    words: words,
    lines: lines,
  );
}
