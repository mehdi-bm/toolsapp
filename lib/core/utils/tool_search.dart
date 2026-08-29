import '../constants/tool_catalog.dart';

List<ToolItem> filterTools(String query, {List<ToolItem> tools = kAllTools}) {
  final String trimmed = query.trim();
  if (trimmed.isEmpty) return const [];

  final String lowered = trimmed.toLowerCase();
  return tools
      .where((tool) => tool.title.toLowerCase().contains(lowered))
      .toList();
}
