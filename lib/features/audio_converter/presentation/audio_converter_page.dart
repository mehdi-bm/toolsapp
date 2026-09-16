import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_audio_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_audio_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_audio_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_audio_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/audio_conversion_history_repository.dart';
import '../domain/audio_bitrate.dart';
import '../domain/audio_conversion_history_entry.dart';
import '../domain/audio_conversion_job.dart';
import '../domain/audio_format.dart';

class AudioConverterPage extends StatefulWidget {
  const AudioConverterPage({super.key});

  @override
  State<AudioConverterPage> createState() => _AudioConverterPageState();
}

class _AudioConverterPageState extends State<AudioConverterPage> {
  final AudioConversionHistoryRepository _historyRepo =
      getIt<AudioConversionHistoryRepository>();

  List<AudioConversionHistoryEntry> _history = const [];
  final List<AudioConversionJob> _jobs = [];

  AudioFormat _format = AudioFormat.mp3;
  AudioBitrate _bitrate = AudioBitrate.k192;

  bool _running = false;
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _history = _historyRepo.getEntries();
  }

  @override
  void dispose() {
    // Same reasoning as the video compressor: FFmpegKit runs process-wide,
    // so leaving mid-batch without cancelling would keep encoding in the
    // background with nothing left to observe its completion.
    if (_running) {
      FFmpegKit.cancel();
    }
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.audio,
    );
    if (files.isEmpty || !mounted) return;

    final List<AudioConversionJob> newJobs = [];
    for (final PlatformFile file in files) {
      final String? path = file.path;
      if (path == null) continue;
      final int size = await file.length() ?? 0;
      newJobs.add(
        AudioConversionJob(
          sourcePath: path,
          sourceName: file.name,
          sourceSizeBytes: size,
        ),
      );
    }
    if (!mounted || newJobs.isEmpty) return;
    setState(() => _jobs.addAll(newJobs));
  }

  void _removeJob(AudioConversionJob job) {
    if (_running) return;
    setState(() => _jobs.remove(job));
  }

  void _clearJobs() {
    if (_running) return;
    setState(() => _jobs.clear());
  }

  void _onFormatChanged(AudioFormat format) {
    if (_running || format == _format) return;
    setState(() => _format = format);
  }

  void _onBitrateChanged(AudioBitrate bitrate) {
    if (_running || bitrate == _bitrate) return;
    setState(() => _bitrate = bitrate);
  }

  Future<void> _startBatch() async {
    if (_running || _jobs.isEmpty) return;
    setState(() {
      _running = true;
      _cancelRequested = false;
    });

    for (final AudioConversionJob job in _jobs) {
      if (job.status == AudioConversionStatus.success) continue;
      if (_cancelRequested) {
        setState(() => job.status = AudioConversionStatus.cancelled);
        continue;
      }
      await _convertJob(job);
    }

    if (mounted) setState(() => _running = false);
  }

  Future<void> _convertJob(AudioConversionJob job) async {
    setState(() {
      job.status = AudioConversionStatus.running;
      job.progress = 0;
      job.errorMessage = null;
    });

    double totalDurationMs = 0;
    try {
      final infoSession = await FFprobeKit.getMediaInformation(
        job.sourcePath,
      );
      final String? durationStr = infoSession
          .getMediaInformation()
          ?.getDuration();
      final double? durationSec = durationStr != null
          ? double.tryParse(durationStr)
          : null;
      if (durationSec != null) totalDurationMs = durationSec * 1000;
    } catch (_) {
      // Progress just stays indeterminate for this file.
    }

    final String outputPath =
        '${Directory.systemTemp.path}/converted_'
        '${DateTime.now().millisecondsSinceEpoch}.${_format.fileExtension}';
    final List<String> args = [
      '-y',
      '-i',
      job.sourcePath,
      ..._format.encodeArgs(_bitrate),
      outputPath,
    ];

    final Completer<void> completer = Completer<void>();
    final FFmpegSession session = await FFmpegKit.executeWithArgumentsAsync(
      args,
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
      null,
      (statistics) {
        if (totalDurationMs <= 0 || !mounted) return;
        final double pct = (statistics.getTime() / totalDurationMs * 100)
            .clamp(0, 100);
        setState(() => job.progress = pct);
      },
    );
    await completer.future;
    if (!mounted) return;

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      final int outputSize = await File(outputPath).length();
      if (!mounted) return;
      setState(() {
        job.status = AudioConversionStatus.success;
        job.outputPath = outputPath;
        job.outputSizeBytes = outputSize;
        job.progress = 100;
      });
      await _historyRepo.addEntry(
        AudioConversionHistoryEntry(
          sourceName: job.sourceName,
          outputPath: outputPath,
          originalSize: job.sourceSizeBytes,
          convertedSize: outputSize,
        ),
      );
      if (mounted) setState(() => _history = _historyRepo.getEntries());
    } else if (ReturnCode.isCancel(returnCode)) {
      setState(() => job.status = AudioConversionStatus.cancelled);
    } else {
      setState(() {
        job.status = AudioConversionStatus.failed;
        job.errorMessage = 'تبدیل این فایل ناموفق بود.';
      });
    }
  }

  Future<void> _cancelBatch() async {
    _cancelRequested = true;
    await FFmpegKit.cancel();
  }

  String _outputFileName(AudioConversionJob job) {
    final String base = job.sourceName.contains('.')
        ? job.sourceName.substring(0, job.sourceName.lastIndexOf('.'))
        : job.sourceName;
    return '$base.${_format.fileExtension}';
  }

  Future<void> _saveFile(String outputPath, String suggestedName) async {
    try {
      final Uint8List bytes = await File(outputPath).readAsBytes();
      final Uri? savedUri = await FilePicker.saveFile(
        fileName: suggestedName,
        bytes: bytes,
        mimeType: 'audio/*',
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

  Future<void> _shareOutput(String path) async {
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
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
    final ToolItem tool = kToolsById['audio_converter']!;

    return ToolScaffold(
      tool: tool,
      helperText: _jobs.isEmpty
          ? 'یک یا چند فایل صوتی انتخاب کنید تا بین فرمت‌های MP3، WAV، M4A و AAC تبدیل شوند.'
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
              key: const Key('audio_converter_pick_button'),
              onPressed: _pickFiles,
              icon: const Icon(Icons.library_music_rounded),
              label: const Text('انتخاب فایل صوتی'),
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
          j.status == AudioConversionStatus.success ||
          j.status == AudioConversionStatus.failed ||
          j.status == AudioConversionStatus.cancelled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'فرمت خروجی',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AudioFormat>(
          segments: [
            for (final AudioFormat format in AudioFormat.values)
              ButtonSegment(
                value: format,
                enabled: !_running,
                label: Text(
                  format.label,
                  key: Key('audio_converter_format_${format.name}'),
                ),
              ),
          ],
          selected: {_format},
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          onSelectionChanged: (selection) => _onFormatChanged(selection.first),
        ),
        if (_format.supportsBitrate) ...[
          const SizedBox(height: 20),
          Text(
            'بیت‌ریت خروجی',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AudioBitrate>(
            segments: [
              for (final AudioBitrate bitrate in AudioBitrate.values)
                ButtonSegment(
                  value: bitrate,
                  enabled: !_running,
                  label: Text(
                    bitrate.label,
                    key: Key('audio_converter_bitrate_${bitrate.name}'),
                  ),
                ),
            ],
            selected: {_bitrate},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            onSelectionChanged: (selection) =>
                _onBitrateChanged(selection.first),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'فایل‌ها (${toPersianNumber(_jobs.length)})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!_running)
              TextButton(
                key: const Key('audio_converter_clear_jobs'),
                onPressed: _clearJobs,
                child: const Text('پاک کردن همه'),
              ),
          ],
        ),
        for (int i = 0; i < _jobs.length; i++)
          _buildJobTile(context, i, _jobs[i]),
        const SizedBox(height: 12),
        if (_running)
          OutlinedButton(
            key: const Key('audio_converter_cancel_button'),
            onPressed: _cancelBatch,
            child: const Text('لغو'),
          )
        else if (allDone)
          FilledButton.icon(
            key: const Key('audio_converter_add_more_button'),
            onPressed: _pickFiles,
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن فایل بیشتر'),
          )
        else
          FilledButton.icon(
            key: const Key('audio_converter_start_button'),
            onPressed: _startBatch,
            icon: const Icon(Icons.sync_alt_rounded),
            label: const Text('شروع تبدیل'),
          ),
      ],
    );
  }

  Widget _buildJobTile(BuildContext context, int index, AudioConversionJob job) {
    final ThemeData theme = Theme.of(context);

    return Card(
      key: Key('audio_converter_job_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(job.status), color: _statusColor(theme, job.status)),
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
                if (job.status == AudioConversionStatus.pending && !_running)
                  IconButton(
                    key: Key('audio_converter_remove_$index'),
                    onPressed: () => _removeJob(job),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_jobSubtitle(job), style: theme.textTheme.bodySmall),
            if (job.status == AudioConversionStatus.running) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  key: Key('audio_converter_progress_$index'),
                  value: job.progress > 0 ? job.progress / 100 : null,
                  minHeight: 6,
                ),
              ),
            ],
            if (job.status == AudioConversionStatus.success) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: Key('audio_converter_save_$index'),
                    onPressed: () =>
                        _saveFile(job.outputPath!, _outputFileName(job)),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('ذخیره'),
                  ),
                  OutlinedButton.icon(
                    key: Key('audio_converter_share_$index'),
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

  String _jobSubtitle(AudioConversionJob job) {
    switch (job.status) {
      case AudioConversionStatus.pending:
        return formatFileSize(job.sourceSizeBytes);
      case AudioConversionStatus.running:
        return '${toPersianNumber(job.progress, decimalDigits: 0)}٪';
      case AudioConversionStatus.success:
        return 'از ${formatFileSize(job.sourceSizeBytes)} به '
            '${formatFileSize(job.outputSizeBytes ?? 0)}';
      case AudioConversionStatus.failed:
        return job.errorMessage ?? 'تبدیل ناموفق بود.';
      case AudioConversionStatus.cancelled:
        return 'لغو شد.';
    }
  }

  IconData _statusIcon(AudioConversionStatus status) => switch (status) {
    AudioConversionStatus.pending => Icons.schedule_rounded,
    AudioConversionStatus.running => Icons.sync_rounded,
    AudioConversionStatus.success => Icons.check_circle_rounded,
    AudioConversionStatus.failed => Icons.error_rounded,
    AudioConversionStatus.cancelled => Icons.block_rounded,
  };

  Color _statusColor(ThemeData theme, AudioConversionStatus status) =>
      switch (status) {
        AudioConversionStatus.success => theme.colorScheme.primary,
        AudioConversionStatus.failed => theme.colorScheme.error,
        AudioConversionStatus.cancelled => theme.colorScheme.outline,
        _ => theme.colorScheme.onSurfaceVariant,
      };

  Widget _buildHistorySection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تبدیل‌های اخیر',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              key: const Key('audio_converter_clear_history'),
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
    AudioConversionHistoryEntry entry,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool exists = File(entry.outputPath).existsSync();
    return Card(
      key: Key('audio_converter_history_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.audiotrack_rounded,
          color: exists ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(
          entry.sourceName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          exists
              ? 'از ${formatFileSize(entry.originalSize)} به ${formatFileSize(entry.convertedSize)}'
              : 'این فایل دیگر در دسترس نیست',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exists)
              IconButton(
                key: Key('audio_converter_history_share_$index'),
                onPressed: () => _shareOutput(entry.outputPath),
                icon: const Icon(Icons.share_rounded),
              ),
            IconButton(
              key: Key('audio_converter_history_delete_$index'),
              onPressed: () => _removeHistoryEntry(index),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
