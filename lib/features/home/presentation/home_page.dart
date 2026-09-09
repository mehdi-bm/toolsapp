import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/tool_catalog.dart';
import '../../../core/routing/tool_navigation.dart';
import '../../../core/utils/tool_search.dart';
import '../../../core/widgets/tool_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../advertising/presentation/ad_banner_cubit.dart';
import '../../advertising/presentation/ad_banner_widget.dart';
import '../../favorites/presentation/favorites_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'recent_tools_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ToolItem> searchResults = filterTools(_query);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<AdBannerCubit>().refresh(),
          child: ListView(
            key: const Key('home_scroll_view'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildHeader(theme),
              const SizedBox(height: 20),
              _buildSearchField(theme),
              const SizedBox(height: 20),
              if (_query.trim().isNotEmpty)
                _buildSearchResults(context, searchResults)
              else ...[
                _buildRecentSection(context, theme),
                for (final ToolCategory category in ToolCategory.values)
                  _buildCategorySection(context, theme, category),
                const AdBannerWidget(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        const AppLogo(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kAppName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                kAppTagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      key: const Key('tool_search_field'),
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'جستجوی ابزار...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'پاک کردن جستجو',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<ToolItem> results) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'ابزاری با این نام پیدا نشد.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return BlocBuilder<FavoritesCubit, Set<String>>(
      builder: (context, favoriteIds) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final ToolItem tool in results)
              ToolCard(
                tool: tool,
                isFavorite: favoriteIds.contains(tool.id),
                onToggleFavorite: () =>
                    context.read<FavoritesCubit>().toggle(tool.id),
                onTap: () => openTool(context, tool),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSection(BuildContext context, ThemeData theme) {
    final bool showRecent = context.select(
      (SettingsCubit cubit) => cubit.state.showRecent,
    );
    if (!showRecent) return const SizedBox.shrink();

    return BlocBuilder<RecentToolsCubit, List<String>>(
      builder: (context, recentIds) {
        if (recentIds.isEmpty) return const SizedBox.shrink();

        final List<ToolItem> recentTools = recentIds
            .map((id) => kToolsById[id])
            .whereType<ToolItem>()
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _ToolRow(
            title: 'آخرین ابزارهای استفاده‌شده',
            tools: recentTools,
            onOpen: (tool) => openTool(context, tool),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ThemeData theme,
    ToolCategory category,
  ) {
    final List<ToolItem> tools = kAllTools
        .where((tool) => tool.category == category)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _ToolRow(
        title: category.label,
        tools: tools,
        onOpen: (tool) => openTool(context, tool),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.title,
    required this.tools,
    required this.onOpen,
  });

  final String title;
  final List<ToolItem> tools;
  final void Function(ToolItem tool) onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110 + MediaQuery.textScalerOf(context).scale(58),
          child: BlocBuilder<FavoritesCubit, Set<String>>(
            builder: (context, favoriteIds) {
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tools.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final ToolItem tool = tools[index];
                  return ToolCard(
                    tool: tool,
                    isFavorite: favoriteIds.contains(tool.id),
                    onToggleFavorite: () =>
                        context.read<FavoritesCubit>().toggle(tool.id),
                    onTap: () => onOpen(tool),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
