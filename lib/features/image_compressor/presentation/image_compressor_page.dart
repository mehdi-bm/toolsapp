import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/image_compression_history_repository.dart';
import '../domain/image_compression_history_entry.dart';
import '../domain/image_compression_job.dart';
import '../domain/image_quality.dart';
import '../domain/target_size_compressor.dart';

enum _CompressionMode { byQuality, byTargetSize }

const List<int> _kTargetSizePresetsKb = [500, 1024, 2048];

class ImageCompressorPage extends StatefulWidget {
  const ImageCompressorPage({super.key});

  @override
  State<ImageCompressorPage> createState() => _ImageCompressorPageState();
}

class _ImageCompressorPageState extends State<ImageCompressorPage> {
  final ImageCompressionHistoryRepository _historyRepo =
      getIt<ImageCompressionHistoryRepository>();
  final ImagePicker _picker = ImagePicker();

  List<ImageCompressionHistoryEntry> _history = const [];
  final List<ImageCompressionJob> _jobs = [];

  _CompressionMode _mode = _CompressionMode.byQuality;
  ImageQuality _quality = ImageQuality.medium;
  int _targetSizeKb = 500;
  final TextEditingController _customSizeController = TextEditingController();

  bool _running = false;

  @override
  void initState() {
    super.initState();
    _history = _historyRepo.getEntries();
  }

  @override
  void dispose() {
    _customSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isEmpty || !mounted) return;

    final List<ImageCompressionJob> newJobs = [];
    for (final XFile file in files) {
      final int size = await File(file.path).length();
      newJobs.add(
        ImageCompressionJob(
          sourcePath: file.path,
          sourceName: file.name,
          sourceSizeBytes: size,
        ),
      );
    }
    if (!mounted || newJobs.isEmpty) return;
    setState(() => _jobs.addAll(newJobs));
  }

  void _removeJob(ImageCompressionJob job) {
    if (_running) return;
    setState(() => _jobs.remove(job));
  }

  void _clearJobs() {
    if (_running) return;
    setState(() => _jobs.clear());
  }

  Future<(int, int)> _readImageDimensions(String path) async {
    final Uint8List bytes = await File(path).readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final int width = frame.image.width;
    final int height = frame.image.height;
    frame.image.dispose();
    return (width, height);
  }

  Future<Uint8List?> _compressToTargetSize(String path, int targetBytes) async {
    (int, int) size = await _readImageDimensions(path);
    Uint8List? best;

    for (int round = 0; round < 4; round++) {
      final int quality = await findQualityForTargetSize(
        compressAt: (q) async {
          final Uint8List? bytes = await FlutterImageCompress.compressWithFile(
            path,
            minWidth: size.$1,
            minHeight: size.$2,
            quality: q,
          );
          if (bytes != null) best = bytes;
          return bytes?.length ?? (1 << 30);
        },
        targetBytes: targetBytes,
      );
      final Uint8List? result = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: size.$1,
        minHeight: size.$2,
        quality: quality,
      );
      if (result != null) {
        best = result;
        if (result.length <= targetBytes || round == 3) return result;
      }
      size = ((size.$1 * 0.8).round(), (size.$2 * 0.8).round());
    }
    return best;
  }

  Future<void> _compressJob(ImageCompressionJob job) async {
    setState(() {
      job.status = ImageCompressionStatus.running;
      job.errorMessage = null;
    });

    try {
      Uint8List? bytes;
      if (_mode == _CompressionMode.byQuality) {
        final (int, int) dims = await _readImageDimensions(job.sourcePath);
        bytes = await FlutterImageCompress.compressWithFile(
          job.sourcePath,
          minWidth: dims.$1,
          minHeight: dims.$2,
          quality: _quality.value,
        );
      } else {
        bytes = await _compressToTargetSize(job.sourcePath, _targetSizeKb * 1024);
      }
      if (bytes == null) {
        throw Exception('compression returned no data');
      }

      final String outputPath =
          '${Directory.systemTemp.path}/compressed_'
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outputPath).writeAsBytes(bytes);
      if (!mounted) return;

      setState(() {
        job.status = ImageCompressionStatus.success;
        job.outputPath = outputPath;
        job.outputSizeBytes = bytes!.length;
      });

      await _historyRepo.addEntry(
        ImageCompressionHistoryEntry(
          sourceName: job.sourceName,
          outputPath: outputPath,
          originalSize: job.sourceSizeBytes,
          compressedSize: bytes.length,
        ),
      );
      if (mounted) setState(() => _history = _historyRepo.getEntries());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        job.status = ImageCompressionStatus.failed;
        job.errorMessage = 'فشرده‌سازی این تصویر ناموفق بود.';
      });
    }
  }

  Future<void> _startBatch() async {
    if (_running || _jobs.isEmpty) return;
    setState(() => _running = true);
    for (final ImageCompressionJob job in _jobs) {
      if (job.status == ImageCompressionStatus.success) continue;
      await _compressJob(job);
    }
    if (mounted) setState(() => _running = false);
  }

  Future<void> _saveToGallery(String outputPath) async {
    try {
      await Gal.putImage(outputPath);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تصویر در گالری ذخیره شد.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ذخیره در گالری ممکن نشد.')));
    }
  }

  Future<void> _shareOutput(String outputPath) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(outputPath)]),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اشتراک‌گذاری ممکن نشد.')));
    }
  }

  Future<void> _clearHistory() async {
    await _historyRepo.clear();
    if (mounted) setState(() => _history = const []);
  }

  Future<void> _removeHistoryEntry(int index) async {
    await _historyRepo.removeAt(index);
    if (mounted) setState(() => _history = _historyRepo.getEntries());
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['image_compressor']!;

    return ToolScaffold(
      tool: tool,
      helperText: _jobs.isEmpty
          ? 'یک یا چند عکس انتخاب کنید تا حجم آن‌ها برای ارسال آسان‌تر کاهش پیدا کند.'
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _jobs.isEmpty ? _buildPickerView(context) : _buildJobsView(context),
      ),
    );
  }

  Widget _buildPickerView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: FilledButton.icon(
              key: const Key('image_compressor_pick_button'),
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('انتخاب عکس'),
            ),
          ),
        ),
        if (_history.isNotEmpty) _buildHistorySection(context),
      ],
    );
  }

  Widget _buildJobsView(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool allDone = _jobs.every(
      (j) =>
          j.status == ImageCompressionStatus.success ||
          j.status == ImageCompressionStatus.failed,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'روش فشرده‌سازی',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SegmentedButton<_CompressionMode>(
          segments: [
            ButtonSegment(
              value: _CompressionMode.byQuality,
              enabled: !_running,
              label: Text(
                'کیفیت دلخواه',
                key: const Key('image_compressor_mode_quality'),
              ),
            ),
            ButtonSegment(
              value: _CompressionMode.byTargetSize,
              enabled: !_running,
              label: Text(
                'حجم مشخص',
                key: const Key('image_compressor_mode_target_size'),
              ),
            ),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          onSelectionChanged: (selection) {
            if (_running) return;
            setState(() => _mode = selection.first);
          },
        ),
        const SizedBox(height: 20),
        if (_mode == _CompressionMode.byQuality)
          _buildQualitySelector(theme)
        else
          _buildTargetSizeSelector(theme),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'عکس‌ها (${toPersianNumber(_jobs.length)})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!_running)
              TextButton(
                key: const Key('image_compressor_clear_jobs'),
                onPressed: _clearJobs,
                child: const Text('پاک کردن همه'),
              ),
          ],
        ),
        for (int i = 0; i < _jobs.length; i++)
          _buildJobTile(context, i, _jobs[i]),
        const SizedBox(height: 12),
        if (allDone)
          FilledButton.icon(
            key: const Key('image_compressor_add_more_button'),
            onPressed: _pickImages,
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن عکس بیشتر'),
          )
        else
          FilledButton.icon(
            key: const Key('image_compressor_start_button'),
            onPressed: _running ? null : _startBatch,
            icon: const Icon(Icons.compress_rounded),
            label: Text(_running ? 'در حال فشرده‌سازی...' : 'شروع فشرده‌سازی'),
          ),
      ],
    );
  }

  Widget _buildQualitySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'کیفیت خروجی',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ImageQuality>(
          segments: [
            for (final ImageQuality quality in ImageQuality.values)
              ButtonSegment(
                value: quality,
                enabled: !_running,
                label: Text(
                  quality.label,
                  key: Key('image_compressor_quality_${quality.name}'),
                ),
              ),
          ],
          selected: {_quality},
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          onSelectionChanged: (selection) {
            if (_running) return;
            setState(() => _quality = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildTargetSizeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حجم تقریبی خروجی',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final int kb in _kTargetSizePresetsKb)
              ChoiceChip(
                key: Key('image_compressor_target_preset_$kb'),
                label: Text(kb >= 1024 ? '${kb ~/ 1024} مگابایت' : '$kb کیلوبایت'),
                selected: _targetSizeKb == kb,
                onSelected: _running
                    ? null
                    : (_) => setState(() {
                        _targetSizeKb = kb;
                        _customSizeController.clear();
                      }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('image_compressor_custom_target_size'),
          controller: _customSizeController,
          enabled: !_running,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'حجم دلخواه (کیلوبایت)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final int? kb = int.tryParse(value.trim());
            if (kb != null && kb > 0) setState(() => _targetSizeKb = kb);
          },
        ),
      ],
    );
  }

  Widget _buildJobTile(BuildContext context, int index, ImageCompressionJob job) {
    final ThemeData theme = Theme.of(context);

    return Card(
      key: Key('image_compressor_job_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(theme, job.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (job.status == ImageCompressionStatus.pending && !_running)
                  IconButton(
                    key: Key('image_compressor_remove_$index'),
                    onPressed: () => _removeJob(job),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_jobSubtitle(job), style: theme.textTheme.bodySmall),
            if (job.status == ImageCompressionStatus.success) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: Key('image_compressor_save_$index'),
                    onPressed: () => _saveToGallery(job.outputPath!),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('ذخیره'),
                  ),
                  OutlinedButton.icon(
                    key: Key('image_compressor_share_$index'),
                    onPressed: () => _shareOutput(job.outputPath!),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('اشتراک‌گذاری'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme, ImageCompressionStatus status) {
    switch (status) {
      case ImageCompressionStatus.pending:
        return Icon(Icons.schedule_rounded, color: theme.colorScheme.onSurfaceVariant);
      case ImageCompressionStatus.running:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ImageCompressionStatus.success:
        return Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary);
      case ImageCompressionStatus.failed:
        return Icon(Icons.error_rounded, color: theme.colorScheme.error);
    }
  }

  String _jobSubtitle(ImageCompressionJob job) {
    switch (job.status) {
      case ImageCompressionStatus.pending:
        return formatFileSize(job.sourceSizeBytes);
      case ImageCompressionStatus.running:
        return 'در حال فشرده‌سازی...';
      case ImageCompressionStatus.success:
        return 'از ${formatFileSize(job.sourceSizeBytes)} به '
            '${formatFileSize(job.outputSizeBytes ?? 0)}';
      case ImageCompressionStatus.failed:
        return job.errorMessage ?? 'فشرده‌سازی ناموفق بود.';
    }
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
              key: const Key('image_compressor_clear_history'),
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
    ImageCompressionHistoryEntry entry,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool exists = File(entry.outputPath).existsSync();
    return Card(
      key: Key('image_compressor_history_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.image_outlined,
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
                key: Key('image_compressor_history_share_$index'),
                onPressed: () => _shareOutput(entry.outputPath),
                icon: const Icon(Icons.share_rounded),
              ),
            IconButton(
              key: Key('image_compressor_history_delete_$index'),
              onPressed: () => _removeHistoryEntry(index),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
