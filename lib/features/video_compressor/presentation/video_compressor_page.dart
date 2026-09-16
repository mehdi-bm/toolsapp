import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:light_compressor_v2/light_compressor_v2.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/compression_history_repository.dart';
import '../domain/compression_history_entry.dart';
import '../domain/compression_level.dart';
import '../domain/output_resolution.dart';

class VideoCompressorPage extends StatefulWidget {
  const VideoCompressorPage({super.key});

  @override
  State<VideoCompressorPage> createState() => _VideoCompressorPageState();
}

class _VideoCompressorPageState extends State<VideoCompressorPage> {
  final LightCompressor _compressor = LightCompressor();
  final ImagePicker _picker = ImagePicker();
  final CompressionHistoryRepository _historyRepo =
      getIt<CompressionHistoryRepository>();

  List<CompressionHistoryEntry> _history = const [];

  String? _sourcePath;
  String? _sourceName;
  int _sourceSizeBytes = 0;
  MediaInfo? _sourceInfo;

  CompressionLevel _level = CompressionLevel.medium;
  OutputResolution _resolution = OutputResolution.original;

  CompressionEstimate? _estimate;
  bool _estimating = false;
  int _estimateRequestId = 0;

  bool _compressing = false;
  double _progress = 0;
  StreamSubscription<double>? _progressSub;

  OnSuccess? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _history = _historyRepo.getEntries();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    // LightCompressor is a process-wide singleton: leaving this page mid
    // compression without cancelling would leave the native encode running
    // in the background, and its progress events would keep arriving on the
    // shared onProgressUpdated stream — bleeding into (and corrupting) the
    // next compression started from a fresh instance of this page.
    if (_compressing) {
      _compressor.cancelCompression();
    }
    super.dispose();
  }

  (int, int)? get _targetDimensions {
    final MediaInfo? info = _sourceInfo;
    final int? w = info?.displayWidth;
    final int? h = info?.displayHeight;
    if (w == null || h == null) return null;
    return _resolution.resolve(w, h);
  }

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final int sizeBytes = await File(file.path).length();
    if (!mounted) return;
    setState(() {
      _sourcePath = file.path;
      _sourceName = file.name;
      _sourceSizeBytes = sizeBytes;
      _sourceInfo = null;
      _estimate = null;
      _result = null;
      _errorMessage = null;
    });

    try {
      final MediaInfo info = await _compressor.getMediaInfo(file.path);
      if (!mounted) return;
      setState(() => _sourceInfo = info);
    } catch (_) {
      // Non-fatal: duration/resolution just won't be shown; compression
      // still proceeds (falls back to keeping the original resolution).
    }
    await _refreshEstimate();
  }

  Future<void> _refreshEstimate() async {
    final String? path = _sourcePath;
    if (path == null) return;
    final int requestId = ++_estimateRequestId;
    setState(() => _estimating = true);
    try {
      final (int, int)? target = _targetDimensions;
      final CompressionEstimate estimate = await _compressor
          .getCompressionEstimate(
            path,
            videoQuality: _level.videoQuality,
            keepOriginalResolution: target == null,
            videoWidth: target?.$1,
            videoHeight: target?.$2,
          );
      if (!mounted || requestId != _estimateRequestId) return;
      setState(() {
        _estimate = estimate;
        _estimating = false;
      });
    } catch (_) {
      if (!mounted || requestId != _estimateRequestId) return;
      setState(() {
        _estimate = null;
        _estimating = false;
      });
    }
  }

  void _onLevelChanged(CompressionLevel level) {
    if (level == _level) return;
    setState(() => _level = level);
    _refreshEstimate();
  }

  void _onResolutionChanged(OutputResolution resolution) {
    if (resolution == _resolution) return;
    setState(() => _resolution = resolution);
    _refreshEstimate();
  }

  Future<void> _startCompression() async {
    final String? path = _sourcePath;
    if (path == null || _compressing) return;

    setState(() {
      _compressing = true;
      _progress = 0;
      _errorMessage = null;
      _result = null;
    });
    _progressSub = _compressor.onProgressUpdated.listen((double percent) {
      if (mounted) setState(() => _progress = percent);
    });

    try {
      final (int, int)? target = _targetDimensions;
      final Result result = await _compressor.compressVideo(
        path: path,
        videoQuality: _level.videoQuality,
        android: AndroidConfig(isSharedStorage: false),
        ios: IOSConfig(saveInGallery: false),
        video: Video(
          videoName: 'compressed_${DateTime.now().millisecondsSinceEpoch}',
          keepOriginalResolution: target == null,
          videoWidth: target?.$1,
          videoHeight: target?.$2,
        ),
      );
      if (!mounted) return;
      if (result is OnSuccess) {
        setState(() => _result = result);
        final CompressionHistoryEntry entry = CompressionHistoryEntry(
          sourceName: _sourceName ?? 'ویدیو',
          outputPath: result.destinationPath,
          originalSize: result.originalSize,
          compressedSize: result.compressedSize,
        );
        await _historyRepo.addEntry(entry);
        if (mounted) setState(() => _history = _historyRepo.getEntries());
      } else if (result is OnFailure) {
        setState(() => _errorMessage = result.message);
      }
      // OnCancelled: leave both _result and _errorMessage null — the
      // pre-compression view (with the still-selected video) reappears.
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e is LightCompressorException
            ? e.message
            : 'فشرده‌سازی ویدیو ناموفق بود.',
      );
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
      if (mounted) setState(() => _compressing = false);
    }
  }

  Future<void> _cancelCompression() => _compressor.cancelCompression();

  Future<void> _saveToGallery() async {
    final OnSuccess? result = _result;
    if (result == null) return;
    try {
      await Gal.putVideo(result.destinationPath);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ویدیو در گالری ذخیره شد.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره در گالری ممکن نشد.')),
      );
    }
  }

  Future<void> _shareResult() async {
    final OnSuccess? result = _result;
    if (result == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(result.destinationPath)]),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اشتراک‌گذاری ممکن نشد.')));
    }
  }

  void _reset() {
    setState(() {
      _sourcePath = null;
      _sourceName = null;
      _sourceInfo = null;
      _estimate = null;
      _result = null;
      _errorMessage = null;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['video_compressor']!;

    return ToolScaffold(
      tool: tool,
      helperText: _sourcePath == null
          ? 'ویدیوی خود را از گالری انتخاب کنید تا با حفظ کیفیت قابل قبول حجم آن کاهش پیدا کند.'
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_result != null) return _buildResultView(context, _result!);
    if (_compressing) return _buildProgressView(context);
    if (_sourcePath == null) return _buildPickerView(context);
    return _buildConfigView(context);
  }

  Widget _buildPickerView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: FilledButton.icon(
              key: const Key('video_compressor_pick_button'),
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library_rounded),
              label: const Text('انتخاب ویدیو از گالری'),
            ),
          ),
        ),
        if (_history.isNotEmpty) _buildHistorySection(context),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'فشرده‌سازی‌های اخیر',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              key: const Key('video_compressor_clear_history'),
              onPressed: _clearHistory,
              child: const Text('پاک کردن لیست'),
            ),
          ],
        ),
        for (int i = 0; i < _history.length; i++)
          _buildHistoryTile(context, i, _history[i]),
      ],
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    int index,
    CompressionHistoryEntry entry,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool exists = File(entry.outputPath).existsSync();
    return Card(
      key: Key('video_compressor_history_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.movie_outlined,
          color: exists ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(
          entry.sourceName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          exists
              ? 'از ${formatFileSize(entry.originalSize)} به ${formatFileSize(entry.compressedSize)}'
              : 'این فایل دیگر در دسترس نیست',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exists)
              IconButton(
                key: Key('video_compressor_history_share_$index'),
                onPressed: () => _shareHistoryEntry(entry),
                icon: const Icon(Icons.share_rounded),
              ),
            IconButton(
              key: Key('video_compressor_history_delete_$index'),
              onPressed: () => _removeHistoryEntry(index),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearHistory() async {
    await _historyRepo.clear();
    if (mounted) setState(() => _history = const []);
  }

  Future<void> _removeHistoryEntry(int index) async {
    await _historyRepo.removeAt(index);
    if (mounted) setState(() => _history = _historyRepo.getEntries());
  }

  Future<void> _shareHistoryEntry(CompressionHistoryEntry entry) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(entry.outputPath)]),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اشتراک‌گذاری ممکن نشد.')));
    }
  }

  Widget _buildConfigView(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MediaInfo? info = _sourceInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.movie_outlined,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sourceName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _sourceSummary(info),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('video_compressor_reset_button'),
                  onPressed: _reset,
                  child: const Text('تغییر'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'میزان فشرده‌سازی',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<CompressionLevel>(
          segments: [
            for (final CompressionLevel level in CompressionLevel.values)
              ButtonSegment(
                value: level,
                label: Text(
                  level.label,
                  key: Key('video_compressor_level_${level.name}'),
                ),
              ),
          ],
          selected: {_level},
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          onSelectionChanged: (selection) => _onLevelChanged(selection.first),
        ),
        const SizedBox(height: 20),
        Text(
          'کیفیت یا رزولوشن خروجی',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<OutputResolution>(
          segments: [
            for (final OutputResolution resolution in OutputResolution.values)
              ButtonSegment(
                value: resolution,
                label: Text(
                  resolution.label,
                  key: Key('video_compressor_resolution_${resolution.name}'),
                ),
              ),
          ],
          selected: {_resolution},
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          onSelectionChanged: (selection) =>
              _onResolutionChanged(selection.first),
        ),
        const SizedBox(height: 20),
        _buildEstimateCard(context),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('video_compressor_start_button'),
          onPressed: _startCompression,
          icon: const Icon(Icons.compress_rounded),
          label: const Text('شروع فشرده‌سازی'),
        ),
      ],
    );
  }

  String _sourceSummary(MediaInfo? info) {
    final String size = formatFileSize(_sourceSizeBytes);
    if (info?.duration == null) return size;
    return '$size · ${_formatDuration(info!.duration!)}';
  }

  Widget _buildEstimateCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CompressionEstimate? estimate = _estimate;

    return Container(
      key: const Key('video_compressor_estimate'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _estimating
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('در حال محاسبهٔ حجم تقریبی...'),
                ],
              ),
            )
          : estimate == null
          ? const Text('حجم تقریبی خروجی پس از انتخاب گزینه‌ها نمایش داده می‌شود.')
          : Text(
              'حجم تقریبی خروجی: ${formatFileSize(estimate.estimatedSizeBytes)} '
              '(کاهش حدود ${toPersianNumber(estimate.estimatedRatio, decimalDigits: 0)}٪)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildProgressView(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'در حال فشرده‌سازی...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const Key('video_compressor_progress_bar'),
              value: _progress / 100,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text('${toPersianNumber(_progress, decimalDigits: 0)}٪'),
          const SizedBox(height: 20),
          OutlinedButton(
            key: const Key('video_compressor_cancel_button'),
            onPressed: _cancelCompression,
            child: const Text('لغو'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, OnSuccess result) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'فشرده‌سازی با موفقیت انجام شد',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('حجم اصلی: ${formatFileSize(result.originalSize)}'),
              Text('حجم جدید: ${formatFileSize(result.compressedSize)}'),
              Text(
                'میزان کاهش: ${toPersianNumber(result.ratio, decimalDigits: 0)}٪',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('video_compressor_save_button'),
              onPressed: _saveToGallery,
              icon: const Icon(Icons.download_rounded),
              label: const Text('ذخیره در گالری'),
            ),
            OutlinedButton.icon(
              key: const Key('video_compressor_share_button'),
              onPressed: _shareResult,
              icon: const Icon(Icons.share_rounded),
              label: const Text('اشتراک‌گذاری'),
            ),
            TextButton(
              key: const Key('video_compressor_reset_button'),
              onPressed: _reset,
              child: const Text('فشرده‌سازی ویدیوی دیگر'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final String seconds = (duration.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );
    return '${toPersianNumber(minutes)}:${_toPersianDigits(seconds)}';
  }

  String _toPersianDigits(String input) {
    const String latin = '0123456789';
    const String persian = '۰۱۲۳۴۵۶۷۸۹';
    return input
        .split('')
        .map((c) {
          final int i = latin.indexOf(c);
          return i == -1 ? c : persian[i];
        })
        .join();
  }
}
