import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/apk_export_service.dart';
import '../data/installed_apps_service.dart';
import '../domain/app_sort_option.dart';
import '../domain/installed_app.dart';

class AppSharingPage extends StatefulWidget {
  const AppSharingPage({super.key});

  @override
  State<AppSharingPage> createState() => _AppSharingPageState();
}

class _AppSharingPageState extends State<AppSharingPage> {
  final InstalledAppsService _appsService = InstalledAppsService();
  final ApkExportService _exportService = ApkExportService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Future<Uint8List?>> _iconFutures = {};

  bool _loading = true;
  String? _errorMessage;
  List<InstalledApp> _allApps = const [];
  String _query = '';
  AppSortOption _sortOption = AppSortOption.name;
  final Set<String> _selectedPackages = {};

  bool _preparing = false;
  int _preparedCount = 0;
  int _preparingTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final List<InstalledApp> apps = await _appsService.listApps();
      if (!mounted) return;
      setState(() {
        _allApps = apps;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'دریافت لیست برنامه‌ها ناموفق بود.';
      });
    }
  }

  List<InstalledApp> get _visibleApps {
    final String query = _query.trim().toLowerCase();
    final List<InstalledApp> filtered = query.isEmpty
        ? _allApps
        : _allApps
              .where(
                (app) =>
                    app.appName.toLowerCase().contains(query) ||
                    app.packageName.toLowerCase().contains(query),
              )
              .toList();
    return _sortOption.sort(filtered);
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  Future<void> _shareSelected() async {
    final List<InstalledApp> selected = _allApps
        .where((app) => _selectedPackages.contains(app.packageName))
        .toList();
    if (selected.isEmpty) return;
    await _shareApps(selected);
  }

  Future<void> _shareApps(List<InstalledApp> apps) async {
    setState(() {
      _preparing = true;
      _preparedCount = 0;
      _preparingTotal = apps.length;
    });

    final List<XFile> files = [];
    for (final InstalledApp app in apps) {
      try {
        final File file = await _exportService.prepareExportFile(app);
        files.add(XFile(file.path, name: _exportService.suggestedFileName(app)));
      } catch (_) {
        // Skip this one app rather than failing the whole batch.
      }
      if (mounted) setState(() => _preparedCount++);
    }

    if (mounted) setState(() => _preparing = false);
    if (files.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('آماده‌سازی فایل APK ممکن نشد.')),
      );
      return;
    }

    try {
      await SharePlus.instance.share(ShareParams(files: files));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اشتراک‌گذاری ممکن نشد.')));
    }
  }

  Future<void> _saveApp(InstalledApp app) async {
    try {
      final File file = await _exportService.prepareExportFile(app);
      final Uint8List bytes = await file.readAsBytes();
      final Uri? savedUri = await FilePicker.saveFile(
        fileName: _exportService.suggestedFileName(app),
        bytes: bytes,
        mimeType: 'application/vnd.android.package-archive',
      );
      if (!mounted) return;
      if (savedUri != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فایل ذخیره شد.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ذخیره فایل ممکن نشد.')));
    }
  }

  void _showAppDetails(InstalledApp app) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _AppDetailsSheet(
        app: app,
        iconFuture: _iconFutureFor(app.packageName),
        onSave: () {
          Navigator.of(context).pop();
          _saveApp(app);
        },
        onShare: () {
          Navigator.of(context).pop();
          _shareApps([app]);
        },
      ),
    );
  }

  Future<Uint8List?> _iconFutureFor(String packageName) {
    return _iconFutures.putIfAbsent(
      packageName,
      () => _appsService.getAppIcon(packageName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['app_sharing']!;

    return ToolScaffold(
      tool: tool,
      body: _preparing
          ? _buildPreparingView(context)
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView(context)
          : _buildListView(context),
    );
  }

  Widget _buildPreparingView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'در حال آماده‌سازی ${toPersianNumber(_preparedCount)} از '
              '${toPersianNumber(_preparingTotal)}...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadApps, child: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    final List<InstalledApp> apps = _visibleApps;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const Key('app_sharing_search_field'),
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'جستجوی برنامه...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'مرتب‌سازی:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<AppSortOption>(
                  segments: [
                    for (final AppSortOption option in AppSortOption.values)
                      ButtonSegment(
                        value: option,
                        label: Text(
                          option.label,
                          key: Key('app_sharing_sort_${option.name}'),
                        ),
                      ),
                  ],
                  selected: {_sortOption},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                  onSelectionChanged: (selection) =>
                      setState(() => _sortOption = selection.first),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: apps.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? 'برنامه‌ای پیدا نشد.'
                        : 'برنامه‌ای با این نام پیدا نشد.',
                  ),
                )
              : ListView.builder(
                  key: const Key('app_sharing_list'),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: apps.length,
                  itemBuilder: (context, index) =>
                      _buildAppTile(context, apps[index]),
                ),
        ),
        if (_selectedPackages.isNotEmpty) _buildSelectionBar(context),
      ],
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${toPersianNumber(_selectedPackages.length)} برنامه انتخاب شده',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              key: const Key('app_sharing_clear_selection'),
              onPressed: () => setState(_selectedPackages.clear),
              child: const Text('لغو'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const Key('app_sharing_share_selected'),
              onPressed: _shareSelected,
              icon: const Icon(Icons.share_rounded),
              label: const Text('اشتراک‌گذاری'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTile(BuildContext context, InstalledApp app) {
    final bool selected = _selectedPackages.contains(app.packageName);
    return ListTile(
      key: Key('app_sharing_tile_${app.packageName}'),
      leading: Checkbox(
        value: selected,
        onChanged: (_) => _toggleSelection(app.packageName),
      ),
      title: Text(
        app.appName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${formatFileSize(app.sizeBytes)} · ${app.versionName}'
        '${app.isSplitApk ? ' · چندبخشی' : ''}',
      ),
      trailing: _AppIcon(iconFuture: _iconFutureFor(app.packageName)),
      onTap: () => _toggleSelection(app.packageName),
      onLongPress: () => _showAppDetails(app),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.iconFuture});

  final Future<Uint8List?> iconFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: iconFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data == null) {
          return const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.android_rounded),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

class _AppDetailsSheet extends StatelessWidget {
  const _AppDetailsSheet({
    required this.app,
    required this.iconFuture,
    required this.onSave,
    required this.onShare,
  });

  final InstalledApp app;
  final Future<Uint8List?> iconFuture;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _AppIcon(iconFuture: iconFuture),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        app.packageName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(theme, 'نسخه', '${app.versionName} (${toPersianNumber(app.versionCode)})'),
            _detailRow(theme, 'حجم', formatFileSize(app.sizeBytes)),
            _detailRow(
              theme,
              'تاریخ نصب',
              _formatDate(app.firstInstallTime),
            ),
            _detailRow(
              theme,
              'آخرین به‌روزرسانی',
              _formatDate(app.lastUpdateTime),
            ),
            if (app.isSplitApk)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'این برنامه چندبخشی نصب شده و به‌صورت یک فایل ZIP اشتراک‌گذاری می‌شود.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  key: const Key('app_sharing_detail_save'),
                  onPressed: onSave,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('ذخیره'),
                ),
                OutlinedButton.icon(
                  key: const Key('app_sharing_detail_share'),
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('اشتراک‌گذاری'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final String y = toPersianNumber(date.year);
    final String m = toPersianNumber(date.month);
    final String d = toPersianNumber(date.day);
    return '$y/$m/$d';
  }
}
