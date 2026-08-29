import 'package:flutter/material.dart';

import '../constants/tool_catalog.dart';

class ToolPlaceholderPage extends StatelessWidget {
  const ToolPlaceholderPage({super.key, required this.tool});

  final ToolItem tool;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tool.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tool.icon, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'این ابزار به‌زودی اضافه می‌شود.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
