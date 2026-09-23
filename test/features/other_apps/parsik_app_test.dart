import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/other_apps/domain/parsik_app.dart';

void main() {
  test('other Parsik apps have unique Bazaar destinations and local icons', () {
    expect(kOtherParsikApps, hasLength(19));

    final Set<String> packages = kOtherParsikApps
        .map((ParsikApp app) => app.packageName)
        .toSet();
    expect(packages, hasLength(kOtherParsikApps.length));
    expect(packages, isNot(contains('com.parsik.toolbax')));

    final ParsikApp habitino = kOtherParsikApps.first;
    expect(habitino.name, 'عادتینو');
    expect(
      habitino.bazaarAppUri.toString(),
      'bazaar://details?id=ir.parsikhesab.habitino',
    );
    expect(
      habitino.bazaarWebUri.toString(),
      'https://cafebazaar.ir/app/ir.parsikhesab.habitino',
    );
    expect(habitino.iconAsset, 'assets/apps/ir.parsikhesab.habitino.png');
  });
}
