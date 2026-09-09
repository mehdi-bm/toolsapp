import '../constants/tool_catalog.dart';

List<ToolItem> filterTools(String query, {List<ToolItem> tools = kAllTools}) {
  final String trimmed = query.trim();
  if (trimmed.isEmpty) return const [];

  final String lowered = _normalize(trimmed);
  if (lowered.isEmpty) return const [];
  return tools
      .where(
        (tool) =>
            _normalize(tool.title).contains(lowered) ||
            _normalize(tool.id).contains(lowered),
      )
      .toList();
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('ي', 'ی')
    .replaceAll('ى', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll(RegExp(r'[_\s\u200c\u200d\u0640\u064b-\u065f]'), '');
