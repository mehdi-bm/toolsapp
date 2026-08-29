import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/tool_catalog.dart';
import '../../features/favorites/presentation/favorites_cubit.dart';

class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    super.key,
    required this.tool,
    required this.body,
    this.helperText,
    this.actions,
  });

  final ToolItem tool;
  final Widget body;
  final String? helperText;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tool.title),
        actions: [
          ...?actions,
          BlocBuilder<FavoritesCubit, Set<String>>(
            builder: (context, favoriteIds) {
              final bool isFavorite = favoriteIds.contains(tool.id);
              return IconButton(
                onPressed: () => context.read<FavoritesCubit>().toggle(
                  tool.id,
                ),
                tooltip: isFavorite
                    ? 'حذف از موردعلاقه‌ها'
                    : 'افزودن به موردعلاقه‌ها',
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite ? Colors.amber : null,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: body),
            if (helperText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  helperText!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
