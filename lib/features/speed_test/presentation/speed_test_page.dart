import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/connection_info_service.dart';
import '../data/speed_test_history_repository.dart';
import '../data/speed_test_service.dart';
import '../domain/connection_quality.dart';
import '../domain/connection_type.dart';
import '../domain/relative_time.dart';
import '../domain/speed_test_history_entry.dart';
import '../domain/speed_test_result.dart';

enum _Stage { idle, ping, download, upload, done, error }

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  final SpeedTestService _service = SpeedTestService();
  final ConnectionInfoService _connectionInfo = ConnectionInfoService();
  final SpeedTestHistoryRepository _historyRepo =
      getIt<SpeedTestHistoryRepository>();

  List<SpeedTestHistoryEntry> _history = const [];

  _Stage _stage = _Stage.idle;
  double _stageProgress = 0;
  SpeedTestResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _history = _historyRepo.getEntries();
  }

  Future<void> _runTest() async {
    setState(() {
      _stage = _Stage.ping;
      _stageProgress = 0;
      _result = null;
      _errorMessage = null;
    });

    try {
      final ConnectionType connectionType = await _connectionInfo
          .getConnectionType();
      if (connectionType == ConnectionType.none) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'اتصال اینترنت برقرار نیست.';
        });
        return;
      }
      final String? carrierName = await _connectionInfo.getCarrierName();

      final int pingMs = await _service.measurePingMs();
      if (!mounted) return;

      setState(() {
        _stage = _Stage.download;
        _stageProgress = 0;
      });
      final double downloadMbps = await _service.measureDownloadMbps(
        onProgress: (p) {
          if (mounted) setState(() => _stageProgress = p);
        },
      );
      if (!mounted) return;

      setState(() {
        _stage = _Stage.upload;
        _stageProgress = 0;
      });
      final double uploadMbps = await _service.measureUploadMbps(
        onProgress: (p) {
          if (mounted) setState(() => _stageProgress = p);
        },
      );
      if (!mounted) return;

      final SpeedTestResult result = SpeedTestResult(
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        pingMs: pingMs,
        connectionType: connectionType,
        carrierName: carrierName,
        testedAt: DateTime.now(),
      );

      await _historyRepo.addEntry(
        SpeedTestHistoryEntry(
          downloadMbps: result.downloadMbps,
          uploadMbps: result.uploadMbps,
          pingMs: result.pingMs,
          connectionType: result.connectionType,
          carrierName: result.carrierName,
          testedAt: result.testedAt,
        ),
      );
      if (!mounted) return;
      setState(() {
        _stage = _Stage.done;
        _result = result;
        _history = _historyRepo.getEntries();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'تست سرعت ناموفق بود؛ اتصال اینترنت را بررسی کنید.';
      });
    }
  }

  Future<void> _shareResult() async {
    final SpeedTestResult? result = _result;
    if (result == null) return;
    final String text =
        'نتیجه تست سرعت اینترنت:\n'
        'دانلود: ${toPersianNumber(result.downloadMbps, decimalDigits: 1)} Mbps\n'
        'آپلود: ${toPersianNumber(result.uploadMbps, decimalDigits: 1)} Mbps\n'
        'Ping: ${toPersianNumber(result.pingMs)} ms\n'
        'نوع اتصال: ${result.connectionType.label}\n'
        'کیفیت: ${result.quality.label}\n\n'
        'تست‌شده با جعبه‌ابزار پارسیک';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
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

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['speed_test']!;

    return ToolScaffold(
      tool: tool,
      helperText: _stage == _Stage.idle
          ? 'برای اندازه‌گیری سرعت اینترنت خود، روی «شروع تست» بزنید.'
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_stage) {
      case _Stage.idle:
        return _buildIdleView(context);
      case _Stage.ping:
      case _Stage.download:
      case _Stage.upload:
        return _buildRunningView(context);
      case _Stage.done:
        return _buildResultView(context, _result!);
      case _Stage.error:
        return _buildErrorView(context);
    }
  }

  Widget _buildIdleView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: FilledButton.icon(
              key: const Key('speed_test_start_button'),
              onPressed: _runTest,
              icon: const Icon(Icons.speed_rounded),
              label: const Text('شروع تست'),
            ),
          ),
        ),
        if (_history.isNotEmpty) _buildHistorySection(context),
      ],
    );
  }

  Widget _buildRunningView(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String label = switch (_stage) {
      _Stage.ping => 'در حال اندازه‌گیری Ping...',
      _Stage.download => 'در حال تست سرعت دانلود...',
      _Stage.upload => 'در حال تست سرعت آپلود...',
      _ => '',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            key: const Key('speed_test_stage_label'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _stage == _Stage.ping ? null : _stageProgress,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'خطایی رخ داد.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('speed_test_retry_button'),
            onPressed: _runTest,
            child: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, SpeedTestResult result) {
    final ThemeData theme = Theme.of(context);
    final Color qualityColor = switch (result.quality) {
      ConnectionQuality.weak => theme.colorScheme.error,
      ConnectionQuality.medium => Colors.amber.shade800,
      ConnectionQuality.excellent => theme.colorScheme.primary,
    };

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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: qualityColor),
                  const SizedBox(width: 6),
                  Text(
                    'کیفیت اتصال: ${result.quality.label}',
                    key: const Key('speed_test_quality_label'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: qualityColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      theme,
                      icon: Icons.download_rounded,
                      label: 'دانلود',
                      value:
                          '${toPersianNumber(result.downloadMbps, decimalDigits: 1)} Mbps',
                      key: 'speed_test_download_value',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      theme,
                      icon: Icons.upload_rounded,
                      label: 'آپلود',
                      value:
                          '${toPersianNumber(result.uploadMbps, decimalDigits: 1)} Mbps',
                      key: 'speed_test_upload_value',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      theme,
                      icon: Icons.network_ping_rounded,
                      label: 'Ping',
                      value: '${toPersianNumber(result.pingMs)} ms',
                      key: 'speed_test_ping_value',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.carrierName != null
                    ? '${result.connectionType.label} · ${result.carrierName}'
                    : result.connectionType.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
              key: const Key('speed_test_retest_button'),
              onPressed: _runTest,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تست دوباره'),
            ),
            OutlinedButton.icon(
              key: const Key('speed_test_share_button'),
              onPressed: _shareResult,
              icon: const Icon(Icons.share_rounded),
              label: const Text('اشتراک‌گذاری'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_history.isNotEmpty) _buildHistorySection(context),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required String key,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          key: Key(key),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
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
              'تاریخچه تست‌ها',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              key: const Key('speed_test_clear_history'),
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
    SpeedTestHistoryEntry entry,
  ) {
    final ThemeData theme = Theme.of(context);
    final ConnectionQuality quality = ConnectionQuality.fromDownloadMbps(
      entry.downloadMbps,
    );
    return Card(
      key: Key('speed_test_history_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          entry.connectionType == ConnectionType.wifi
              ? Icons.wifi_rounded
              : Icons.signal_cellular_alt_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          'دانلود ${toPersianNumber(entry.downloadMbps, decimalDigits: 1)} Mbps'
          ' · آپلود ${toPersianNumber(entry.uploadMbps, decimalDigits: 1)} Mbps'
          ' · Ping ${toPersianNumber(entry.pingMs)} ms',
        ),
        subtitle: Text(
          '${quality.label} · ${formatRelativeTime(entry.testedAt)}',
        ),
      ),
    );
  }
}
