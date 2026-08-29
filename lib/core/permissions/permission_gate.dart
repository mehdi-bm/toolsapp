import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_copy.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.copy,
    required this.builder,
  });

  final Permission permission;
  final PermissionCopy copy;
  final WidgetBuilder builder;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  PermissionStatus _status = PermissionStatus.denied;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final PermissionStatus status = await _safeCall(
      () => widget.permission.status,
    );
    if (!mounted) return;
    setState(() {
      _status = status;
      _checking = false;
    });
  }

  Future<void> _requestPermission() async {
    final PermissionStatus status = await _safeCall(
      () => widget.permission.request(),
    );
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<PermissionStatus> _safeCall(
    Future<PermissionStatus> Function() action,
  ) async {
    try {
      return await action().timeout(const Duration(seconds: 5));
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status.isGranted) {
      return widget.builder(context);
    }

    final ThemeData theme = Theme.of(context);
    final bool permanentlyDenied = _status.isPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.copy.icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              permanentlyDenied
                  ? widget.copy.permanentlyDeniedMessage
                  : widget.copy.deniedMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('permission_action'),
              onPressed: permanentlyDenied
                  ? openAppSettings
                  : _requestPermission,
              child: Text(
                permanentlyDenied ? 'باز کردن تنظیمات' : 'درخواست دسترسی',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
