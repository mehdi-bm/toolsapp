import 'package:flutter/material.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../domain/text_stats.dart';

class TextCounterPage extends StatefulWidget {
  const TextCounterPage({super.key, required this.tool});

  final ToolItem tool;

  @override
  State<TextCounterPage> createState() => _TextCounterPageState();
}

class _TextCounterPageState extends State<TextCounterPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      tool: widget.tool,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 220,
              child: TextField(
                key: const Key('text_counter_input'),
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'متن خود را اینجا بنویسید یا جای‌گذاری کنید...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatsGrid(stats: computeTextStats(_controller.text)),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final TextStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const Key('text_counter_stats'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: 24 + MediaQuery.textScalerOf(context).scale(104),
      children: [
        _StatTile(label: 'حروف', value: stats.characters),
        _StatTile(label: 'حروف بدون فاصله', value: stats.charactersNoSpaces),
        _StatTile(label: 'کلمات', value: stats.words),
        _StatTile(label: 'خطوط', value: stats.lines),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            toPersianNumber(value),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
