class ParsikApp {
  const ParsikApp({required this.name, required this.packageName});

  final String name;
  final String packageName;

  String get iconAsset => 'assets/apps/$packageName.png';

  Uri get bazaarAppUri => Uri(
    scheme: 'bazaar',
    host: 'details',
    queryParameters: <String, String>{'id': packageName},
  );

  Uri get bazaarWebUri => Uri.https('cafebazaar.ir', '/app/$packageName');
}

const List<ParsikApp> kOtherParsikApps = <ParsikApp>[
  ParsikApp(name: 'عادتینو', packageName: 'ir.parsikhesab.habitino'),
  ParsikApp(
    name: 'حسابیار پارسیک | مدیریت دخل و خرج',
    packageName: 'ir.parsik.hesabyar',
  ),
  ParsikApp(name: 'پارسیک اسکن', packageName: 'com.parsscan.parsscan'),
  ParsikApp(name: 'کارا', packageName: 'com.kara.app.kara_todo'),
  ParsikApp(name: 'پارسیک پلیر', packageName: 'com.parsik.parsik_player'),
  ParsikApp(name: 'پارسیک اذان', packageName: 'ir.parsik.azan'),
  ParsikApp(name: 'پارسیک هواشناسی', packageName: 'com.weather.weather_plus'),
  ParsikApp(name: 'پارسیک کدخوان', packageName: 'ir.parsik.parsik_code_reader'),
  ParsikApp(
    name: '۵۰۴ پارس واژه',
    packageName: 'com.vocab.essential_words_504',
  ),
  ParsikApp(name: 'تبدیل به متن', packageName: 'com.convert.text'),
  ParsikApp(name: 'پارسیک هرا', packageName: 'ir.parsik.parsik_hera'),
  ParsikApp(name: 'خودرویار پارسیک', packageName: 'com.parsik.caryar'),
  ParsikApp(name: 'پارسیک Pomodoro', packageName: 'com.parsik.parsik_focus'),
  ParsikApp(name: 'پارسیک Pass', packageName: 'com.parsiksa.parsikpass'),
  ParsikApp(name: 'حساب پارسیک', packageName: 'ir.parsik.hesab_parsik'),
  ParsikApp(name: 'AnyCalc', packageName: 'com.liteapp.anycalc'),
  ParsikApp(name: 'مال‌من', packageName: 'ir.liteapp.malman'),
  ParsikApp(name: 'پارسیک فیت', packageName: 'com.parsikfit.parsik_fit'),
  ParsikApp(
    name: 'پارسیک دانلودر',
    packageName: 'com.parsikhesab.parsik_downloader',
  ),
];
