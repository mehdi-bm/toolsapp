import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/widgets/info_page_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const List<(String, String)> _sections = [
    (
      '۱. کلیات',
      '$kAppName یک برنامهٔ کاملاً آفلاین است. هیچ داده‌ای از دستگاه شما به '
          'سرورهای خارجی ارسال نمی‌شود.',
    ),
    (
      '۲. دسترسی به دوربین',
      'دوربین فقط برای ابزارهای اسکن QR، اسکن بارکد، تشخیص رنگ و ذره‌بین '
          'استفاده می‌شود. هیچ تصویر یا ویدیویی ذخیره یا ارسال نمی‌شود؛ '
          'پردازش کاملاً روی دستگاه شما انجام می‌گیرد.',
    ),
    (
      '۳. دسترسی به میکروفون',
      'میکروفون فقط برای ابزار صداسنج و صرفاً برای محاسبهٔ سطح تقریبی صدا '
          'استفاده می‌شود. صدای شما ضبط یا ذخیره نمی‌شود.',
    ),
    (
      '۴. دسترسی به سنسورها',
      'سنسورهای شتاب‌سنج و مغناطیس‌سنج فقط برای ابزارهای قطب‌نما و تراز '
          'استفاده می‌شوند و داده‌ای از آن‌ها ذخیره یا ارسال نمی‌شود.',
    ),
    (
      '۵. ذخیره‌سازی محلی',
      'موردعلاقه‌ها، تنظیمات ظاهری، و آخرین ابزارهای استفاده‌شده فقط '
          'به‌صورت محلی روی دستگاه شما ذخیره می‌شوند و در صورت حذف برنامه، '
          'این اطلاعات هم پاک می‌شوند.',
    ),
    (
      '۶. عدم جمع‌آوری اطلاعات شخصی',
      '$kAppName هیچ اطلاعات شخصی، مکان، یا شناسهٔ تبلیغاتی جمع‌آوری '
          'نمی‌کند و از هیچ سرویس تحلیل (Analytics) استفاده نمی‌کند.',
    ),
    (
      '۷. تماس',
      'برای هرگونه پرسش دربارهٔ حریم خصوصی می‌توانید با ما در ارتباط '
          'باشید: $kContactEmail',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InfoPageScaffold(
      title: 'حریم خصوصی',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (title, body) in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
