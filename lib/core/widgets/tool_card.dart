import 'package:flutter/material.dart';

import '../constants/tool_catalog.dart';
import '../theme/app_colors.dart';

class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  final ToolItem tool;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 142,
      child: Card(
        child: InkWell(
          key: Key('tool_card_${tool.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        tool.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      key: Key('favorite_toggle_${tool.id}'),
                      onPressed: onToggleFavorite,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: isFavorite
                          ? 'حذف از موردعلاقه‌ها'
                          : 'افزودن به موردعلاقه‌ها',
                      icon: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isFavorite
                            ? Colors.amber
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tool.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
