import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/main.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/comparison_store.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/utils/layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      AppSettings.instance.load(),
      SupplierStore.instance.load(),
      CategoryStore.instance.load(),
      UnitStore.instance.load(locale: AppSettings.instance.locale),
      ComparisonStore.instance.load(),
    ]);
  });

  testWidgets('home header survives a small-window round trip', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);

    tester.view.physicalSize = const Size(390, 700);
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);
  });

  test('stale Android window insets are clamped', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const stale = MediaQueryData(
      padding: EdgeInsets.only(top: 112, bottom: 150),
      viewPadding: EdgeInsets.only(top: 112, bottom: 150),
    );
    final fixed = sanitizeAndroidWindowInsets(stale);

    expect(fixed.padding.top, 48);
    expect(fixed.padding.bottom, 48);
    expect(fixed.viewPadding.top, 48);
    expect(fixed.viewPadding.bottom, 48);

    const normal = MediaQueryData(
      padding: EdgeInsets.only(top: 24, bottom: 32),
      viewPadding: EdgeInsets.only(top: 48, bottom: 32),
    );
    expect(sanitizeAndroidWindowInsets(normal), normal);
  });
}
