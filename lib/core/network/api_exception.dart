/// A user-facing (Persian) API failure. Never carries server internals.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

const ApiException kNetworkException = ApiException(
  'اتصال اینترنت را بررسی و دوباره تلاش کنید.',
);

const ApiException kInvalidResponseException = ApiException(
  'پاسخ سرور معتبر نیست؛ دوباره تلاش کنید.',
);

const ApiException kNotConfiguredException = ApiException(
  'این قابلیت در حال حاضر پیکربندی نشده است.',
);

ApiException mapStatusToException(int statusCode) {
  if (statusCode == 400) {
    return const ApiException('اطلاعات واردشده معتبر نیست؛ فیلدها را بررسی کنید.');
  }
  if (statusCode == 401 || statusCode == 403) {
    return const ApiException(
      'ارتباط امن برنامه با سرور تأیید نشد؛ نسخه برنامه را به‌روزرسانی کنید.',
    );
  }
  if (statusCode == 429) {
    return const ApiException('تعداد درخواست‌ها زیاد است؛ کمی بعد دوباره تلاش کنید.');
  }
  if (statusCode >= 500) {
    return const ApiException('مشکلی در سرور رخ داد؛ کمی بعد دوباره تلاش کنید.');
  }
  return kInvalidResponseException;
}
