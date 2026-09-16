import 'package:flutter/material.dart';

enum ToolCategory {
  measurement('اندازه‌گیری'),
  cameraScanner('دوربین و اسکن'),
  device('ابزار دستگاه'),
  security('امنیت'),
  text('متن'),
  media('رسانه و فایل');

  const ToolCategory(this.label);

  final String label;
}

class ToolItem {
  const ToolItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final ToolCategory category;
  final String title;
  final String description;
  final IconData icon;
}

const List<ToolItem> kAllTools = [
  ToolItem(
    id: 'ruler',
    category: ToolCategory.measurement,
    title: 'خط‌کش',
    description: 'اندازه‌گیری سریع با صفحهٔ گوشی',
    icon: Icons.straighten_rounded,
  ),
  ToolItem(
    id: 'protractor',
    category: ToolCategory.measurement,
    title: 'نقاله',
    description: 'اندازه‌گیری زاویه با کشیدن انگشت',
    icon: Icons.architecture_rounded,
  ),
  ToolItem(
    id: 'level',
    category: ToolCategory.measurement,
    title: 'تراز',
    description: 'تراز کردن سطوح با سنسور حرکت',
    icon: Icons.linear_scale_rounded,
  ),
  ToolItem(
    id: 'qr_scanner',
    category: ToolCategory.cameraScanner,
    title: 'اسکن QR',
    description: 'اسکن سریع کدهای QR با دوربین',
    icon: Icons.qr_code_scanner_rounded,
  ),
  ToolItem(
    id: 'barcode_scanner',
    category: ToolCategory.cameraScanner,
    title: 'بارکد',
    description: 'خواندن بارکدهای متداول',
    icon: Icons.barcode_reader,
  ),
  ToolItem(
    id: 'color_detector',
    category: ToolCategory.cameraScanner,
    title: 'تشخیص رنگ',
    description: 'نمایش کد HEX و RGB رنگ‌ها',
    icon: Icons.colorize_rounded,
  ),
  ToolItem(
    id: 'magnifier',
    category: ToolCategory.cameraScanner,
    title: 'ذره‌بین',
    description: 'بزرگ‌نمایی با دوربین گوشی',
    icon: Icons.zoom_in_rounded,
  ),
  ToolItem(
    id: 'flashlight',
    category: ToolCategory.device,
    title: 'چراغ‌قوه',
    description: 'روشن و خاموش کردن فلاش گوشی',
    icon: Icons.flashlight_on_rounded,
  ),
  ToolItem(
    id: 'compass',
    category: ToolCategory.device,
    title: 'قطب‌نما',
    description: 'نمایش جهت با سنسور مغناطیسی',
    icon: Icons.explore_rounded,
  ),
  ToolItem(
    id: 'sound_meter',
    category: ToolCategory.device,
    title: 'صدا',
    description: 'اندازه‌گیری تقریبی سطح صدا',
    icon: Icons.graphic_eq_rounded,
  ),
  ToolItem(
    id: 'password_generator',
    category: ToolCategory.security,
    title: 'تولید رمز',
    description: 'ساخت رمز عبور تصادفی و امن',
    icon: Icons.password_rounded,
  ),
  ToolItem(
    id: 'random_generator',
    category: ToolCategory.security,
    title: 'کد تصادفی',
    description: 'تولید کد عددی یا حرفی‌عددی',
    icon: Icons.shuffle_rounded,
  ),
  ToolItem(
    id: 'qr_generator',
    category: ToolCategory.security,
    title: 'ساخت QR',
    description: 'ساخت QR از متن، لینک و...',
    icon: Icons.qr_code_rounded,
  ),
  ToolItem(
    id: 'char_counter',
    category: ToolCategory.text,
    title: 'شمارش حروف',
    description: 'شمارش زندهٔ حروف متن',
    icon: Icons.abc_rounded,
  ),
  ToolItem(
    id: 'speech_text_converter',
    category: ToolCategory.text,
    title: 'گفتار و متن',
    description: 'تبدیل متن به گفتار و گفتار به متن',
    icon: Icons.record_voice_over_rounded,
  ),
  ToolItem(
    id: 'text_case_converter',
    category: ToolCategory.text,
    title: 'تغییر حروف',
    description: 'تبدیل به حروف بزرگ یا کوچک',
    icon: Icons.sort_by_alpha_rounded,
  ),
  ToolItem(
    id: 'text_cleaner',
    category: ToolCategory.text,
    title: 'پاکسازی متن',
    description: 'حذف فاصله و خط خالی اضافی',
    icon: Icons.cleaning_services_rounded,
  ),
  ToolItem(
    id: 'video_compressor',
    category: ToolCategory.media,
    title: 'فشرده‌سازی ویدیو',
    description: 'کاهش حجم ویدیو با حفظ کیفیت قابل قبول',
    icon: Icons.video_settings_rounded,
  ),
  ToolItem(
    id: 'audio_converter',
    category: ToolCategory.media,
    title: 'تبدیل فرمت صدا',
    description: 'تبدیل فایل صوتی بین MP3، WAV، M4A و AAC',
    icon: Icons.audiotrack_rounded,
  ),
  ToolItem(
    id: 'image_compressor',
    category: ToolCategory.media,
    title: 'فشرده‌سازی عکس',
    description: 'کاهش حجم عکس برای ارسال آسان‌تر',
    icon: Icons.photo_size_select_large_rounded,
  ),
  ToolItem(
    id: 'speed_test',
    category: ToolCategory.device,
    title: 'تست سرعت اینترنت',
    description: 'اندازه‌گیری سرعت دانلود، آپلود و پینگ',
    icon: Icons.speed_rounded,
  ),
  ToolItem(
    id: 'app_sharing',
    category: ToolCategory.media,
    title: 'اشتراک برنامه‌ها',
    description: 'استخراج و ارسال فایل APK برنامه‌های نصب‌شده',
    icon: Icons.apps_rounded,
  ),
];

final Map<String, ToolItem> kToolsById = {
  for (final ToolItem tool in kAllTools) tool.id: tool,
};
