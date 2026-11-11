import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/main.dart';
import 'package:zhidang/screens/quick_calc_page.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/comparison_store.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';

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

  testWidgets('compare header exposes a quick convert button', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('比价').first);
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);

    final quick = find.byTooltip('快速换算');
    expect(quick, findsOneWidget);

    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(find.byType(QuickCalcPage), findsOneWidget);

    // Both pushed pages return cleanly with their back buttons.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(QuickCalcPage), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byTooltip('比价'), findsOneWidget);
  });

  testWidgets('compare tab inside the nav bar has no back button', (
    tester,
  ) async {
    await AppSettings.instance.setCompareNavMode(CompareNavMode.bottomNav);
    addTearDown(
      () => AppSettings.instance.setCompareNavMode(CompareNavMode.headerIcon),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('比价'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.byTooltip('快速换算'), findsOneWidget);
  });
}
