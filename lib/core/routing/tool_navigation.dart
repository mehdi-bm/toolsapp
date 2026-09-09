import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/barcode_scanner/presentation/barcode_scanner_page.dart';
import '../../features/color_detector/presentation/color_detector_page.dart';
import '../../features/compass/presentation/compass_page.dart';
import '../../features/flashlight/presentation/flashlight_page.dart';
import '../../features/home/presentation/recent_tools_cubit.dart';
import '../../features/level/presentation/level_page.dart';
import '../../features/magnifier/presentation/magnifier_page.dart';
import '../../features/password_generator/presentation/password_generator_page.dart';
import '../../features/protractor/presentation/protractor_page.dart';
import '../../features/qr_generator/presentation/qr_generator_page.dart';
import '../../features/qr_scanner/presentation/qr_scanner_page.dart';
import '../../features/random_generator/presentation/random_generator_page.dart';
import '../../features/ruler/presentation/ruler_page.dart';
import '../../features/sound_meter/presentation/sound_meter_page.dart';
import '../../features/speech_text_converter/presentation/speech_text_converter_page.dart';
import '../../features/text_case_converter/presentation/text_case_converter_page.dart';
import '../../features/text_cleaner/presentation/text_cleaner_page.dart';
import '../../features/text_counter/presentation/text_counter_page.dart';
import '../constants/tool_catalog.dart';
import '../widgets/tool_placeholder_page.dart';

void openTool(BuildContext context, ToolItem tool) {
  FocusManager.instance.primaryFocus?.unfocus();
  context.read<RecentToolsCubit>().recordUsed(tool.id);
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => _buildToolPage(tool)));
}

Widget _buildToolPage(ToolItem tool) {
  switch (tool.id) {
    case 'ruler':
      return const RulerPage();
    case 'protractor':
      return const ProtractorPage();
    case 'level':
      return const LevelPage();
    case 'qr_scanner':
      return const QrScannerPage();
    case 'barcode_scanner':
      return const BarcodeScannerPage();
    case 'color_detector':
      return const ColorDetectorPage();
    case 'magnifier':
      return const MagnifierPage();
    case 'flashlight':
      return const FlashlightPage();
    case 'compass':
      return const CompassPage();
    case 'sound_meter':
      return const SoundMeterPage();
    case 'password_generator':
      return const PasswordGeneratorPage();
    case 'random_generator':
      return const RandomGeneratorPage();
    case 'qr_generator':
      return const QrGeneratorPage();
    case 'char_counter':
      return TextCounterPage(tool: tool);
    case 'speech_text_converter':
      return const SpeechTextConverterPage();
    case 'text_case_converter':
      return const TextCaseConverterPage();
    case 'text_cleaner':
      return const TextCleanerPage();
    default:
      return ToolPlaceholderPage(tool: tool);
  }
}
