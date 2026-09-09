import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/tool_catalog.dart';
import '../../../core/permissions/permission_copy.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/widgets/tool_scaffold.dart';

enum _Mode { textToSpeech, speechToText }

class SpeechTextConverterPage extends StatefulWidget {
  const SpeechTextConverterPage({super.key});

  @override
  State<SpeechTextConverterPage> createState() =>
      _SpeechTextConverterPageState();
}

class _SpeechTextConverterPageState extends State<SpeechTextConverterPage> {
  _Mode _mode = _Mode.textToSpeech;

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['speech_text_converter']!;

    return ToolScaffold(
      tool: tool,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<_Mode>(
              key: const Key('speech_text_mode_selector'),
              segments: const [
                ButtonSegment(
                  value: _Mode.textToSpeech,
                  label: Text('متن به گفتار'),
                  icon: Icon(Icons.volume_up_rounded),
                ),
                ButtonSegment(
                  value: _Mode.speechToText,
                  label: Text('گفتار به متن'),
                  icon: Icon(Icons.mic_rounded),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
          ),
          Expanded(
            child: _mode == _Mode.textToSpeech
                ? const _TextToSpeechView()
                : const _SpeechToTextView(),
          ),
        ],
      ),
    );
  }
}

class _TextToSpeechView extends StatefulWidget {
  const _TextToSpeechView();

  @override
  State<_TextToSpeechView> createState() => _TextToSpeechViewState();
}

class _TextToSpeechViewState extends State<_TextToSpeechView>
    with WidgetsBindingObserver {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _controller = TextEditingController();
  bool _isSpeaking = false;
  bool _persianVoiceReady = false;
  bool _checkingVoice = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();
  }

  Future<void> _initTts() async {
    bool persianReady = false;
    try {
      // isLanguageInstalled checks whether the voice data is actually
      // downloaded and usable right now (isLanguageAvailable can say "yes"
      // even when the engine would still need to download data first,
      // which silently produces no audio). Only switch the engine's
      // language if Persian is really ready — forcing an unsupported
      // language can leave the engine unable to speak at all, in any
      // language, until reset.
      final dynamic installed = await _tts.isLanguageInstalled('fa-IR');
      persianReady = installed == true;
      if (persianReady) {
        await _tts.setLanguage('fa-IR');
      }
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {
      persianReady = false;
    }
    if (!mounted) return;
    setState(() {
      _persianVoiceReady = persianReady;
      _checkingVoice = false;
    });
  }

  Future<void> _speak() async {
    if (_checkingVoice) return;
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSpeaking = true);
    try {
      final dynamic result = await _tts.speak(text);
      if (result != 1 && mounted) setState(() => _isSpeaking = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('پخش صدا ممکن نشد.')));
    }
  }

  Future<void> _stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Nothing to clean up if the engine never started.
    }
    if (mounted) setState(() => _isSpeaking = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_checkingVoice && !_persianVoiceReady)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'صدای فارسی روی این دستگاه نصب نیست؛ متن با زبان پیش‌فرض '
                'گوشی خوانده می‌شود.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              key: const Key('tts_input_field'),
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'متنی که می‌خواهید خوانده شود را بنویسید...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('tts_toggle_action'),
            onPressed: _checkingVoice
                ? null
                : _isSpeaking
                ? _stop
                : _speak,
            icon: Icon(
              _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
            ),
            label: Text(_isSpeaking ? 'توقف' : 'پخش'),
          ),
        ],
      ),
    );
  }
}

class _SpeechToTextView extends StatelessWidget {
  const _SpeechToTextView();

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: Permission.microphone,
      copy: kMicrophonePermissionCopy,
      builder: (context) => const _SpeechToTextBody(),
    );
  }
}

class _SpeechToTextBody extends StatefulWidget {
  const _SpeechToTextBody();

  @override
  State<_SpeechToTextBody> createState() => _SpeechToTextBodyState();
}

class _SpeechToTextBodyState extends State<_SpeechToTextBody>
    with WidgetsBindingObserver {
  // Requested explicitly on every listen() call regardless of whether the
  // device's recognizer advertises it in locales() — that list is often
  // just the offline-pack subset and excludes languages the online/cloud
  // recognizer can still handle when asked directly.
  static const String _persianLocaleId = 'fa-IR';

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _checking = true;
  bool _isListening = false;
  bool _persianListed = false;
  String _transcript = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = false;
    bool persianListed = false;
    try {
      available = await _speech
          .initialize(
            // Keeps the Start/Stop button in sync with the engine's actual
            // state — listening sessions can end on their own (silence
            // timeout, OS cutoff) without the user tapping Stop.
            onStatus: (status) {
              if (!mounted) return;
              setState(
                () => _isListening = status == stt.SpeechToText.listeningStatus,
              );
            },
            onError: (_) {
              if (!mounted) return;
              setState(() {
                _isListening = false;
                _error =
                    'گفتار دریافت نشد. اتصال اینترنت و سرویس گفتار گوشی را بررسی و دوباره تلاش کنید.';
              });
            },
          )
          .timeout(const Duration(seconds: 5));
      if (available) {
        final List<stt.LocaleName> locales = await _speech.locales();
        persianListed = locales.any(
          (locale) => locale.localeId.toLowerCase().startsWith('fa'),
        );
      }
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    setState(() {
      _speechAvailable = available;
      _persianListed = persianListed;
      _checking = false;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopSafely();
      return;
    }
    setState(() {
      _isListening = true;
      _error = null;
    });
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (!mounted) return;
          setState(() => _transcript = result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(localeId: _persianLocaleId),
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _copy() async {
    if (_transcript.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _transcript));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
  }

  void _clear() => setState(() => _transcript = '');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopSafely();
  }

  Future<void> _stopSafely() async {
    try {
      await _speech.stop();
    } catch (_) {
      /* Recognizer already stopped. */
    }
    if (mounted) setState(() => _isListening = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSafely();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_speechAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'تشخیص گفتار روی این دستگاه در دسترس نیست.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _error ??
                'تشخیص گفتار ممکن است صدا را به سرویس گفتار گوشی ارسال کند و به اینترنت نیاز داشته باشد.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (!_persianListed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'زبان فارسی در فهرست زبان‌های تشخیص گفتار این دستگاه پیدا '
                'نشد؛ ممکن است تشخیص گفتار فارسی به‌درستی کار نکند.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  key: const Key('stt_transcript'),
                  _transcript.isEmpty
                      ? 'برای شروع، دکمهٔ میکروفون را بزنید...'
                      : _transcript,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('stt_toggle_action'),
                  onPressed: _toggleListening,
                  icon: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  ),
                  label: Text(_isListening ? 'توقف' : 'شروع'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _transcript.isEmpty ? null : _copy,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('کپی'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _transcript.isEmpty ? null : _clear,
            icon: const Icon(Icons.clear_rounded),
            label: const Text('پاک‌سازی'),
          ),
        ],
      ),
    );
  }
}
