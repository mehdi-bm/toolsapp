import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/routing/tool_navigation.dart';
import '../../../core/widgets/tool_card.dart';
import 'favorites_cubit.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('موردعلاقه‌ها')),
      body: BlocBuilder<FavoritesCubit, Set<String>>(
        builder: (context, favoriteIds) {
          if (favoriteIds.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'هنوز ابزاری به علاقه‌مندی‌ها اضافه نکرده‌اید.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<ToolItem> favoriteTools = favoriteIds
              .map((id) => kToolsById[id])
              .whereType<ToolItem>()
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: favoriteTools.length,
            itemBuilder: (context, index) {
              final ToolItem tool = favoriteTools[index];
              return ToolCard(
                tool: tool,
                isFavorite: true,
                onToggleFavorite: () =>
                    context.read<FavoritesCubit>().toggle(tool.id),
                onTap: () => openTool(context, tool),
              );
            },
          );
        },
      ),
    );
  }
}
