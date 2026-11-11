import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/l10n/app_strings.dart';
import 'package:zhidang/screens/quick_calc_page.dart';
import 'package:zhidang/screens/unit_conversions_page.dart';
import 'package:zhidang/services/quick_calc_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/utils/quick_calc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    QuickCalcStore.instance.clear();
    await AppSettings.instance.load();
    await UnitStore.instance.load(locale: AppSettings.instance.locale);
    await UnitStore.instance.replaceRelations(const []);
  });

  tearDown(() async {
    QuickCalcStore.instance.clear();
    await UnitStore.instance.replaceRelations(const []);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      AppStrings.provide(
        locale: const Locale('zh'),
        child: const MaterialApp(home: QuickCalcPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> commitDraft(WidgetTester tester) async {
    await tester.tap(find.byTooltip('添加'));
    await tester.pumpAndSettle();
  }

  testWidgets('keeps one editor and locks rows after adding', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(tester);
    expect(find.byType(TextField), findsNWidgets(3));

    await tester.enterText(find.byType(TextField).at(1), '20');
    await tester.enterText(find.byType(TextField).at(2), '15');
    await tester.pump();
    expect(find.text('¥1.33 / 个'), findsOneWidget);
    await commitDraft(tester);

    // The committed row is a compact fixed row; only the draft is editable.
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('¥1.33 / 个'), findsOneWidget);
    expect(find.text('¥20 / 15 个'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '9.6');
    await tester.enterText(find.byType(TextField).at(2), '400');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('g').last);
    await tester.pumpAndSettle();
    expect(find.text('¥12 / 斤'), findsOneWidget);
    expect(find.text('¥24 / kg'), findsOneWidget);
    await commitDraft(tester);
    expect(find.text('¥12 / 斤'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.enterText(find.byType(TextField).at(2), '15');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('个').last);
    await tester.pumpAndSettle();
    await commitDraft(tester);

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('¥0.67 / 个'), findsOneWidget);
    expect(find.text('最低'), findsOneWidget);
    expect(find.text('+100%'), findsOneWidget);
    expect(find.byTooltip('删除这组数据'), findsNWidgets(3));
    expect(find.text('单位：个'), findsOneWidget);
    expect(find.text('重量'), findsOneWidget);
  });

  testWidgets('keeps committed rows and the draft during the session', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).at(1), '20');
    await tester.enterText(find.byType(TextField).at(2), '15');
    await tester.pump();
    await commitDraft(tester);

    await tester.enterText(find.byType(TextField).at(1), '9.6');
    await tester.enterText(find.byType(TextField).at(2), '400');
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpPage(tester);

    expect(find.text('¥1.33 / 个'), findsOneWidget);
    expect(find.text('¥20 / 15 个'), findsOneWidget);
    expect(find.text('9.6'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
  });

  testWidgets('row hint is hidden in the title until long press', (
    tester,
  ) async {
    await pumpPage(tester);
    final hint = AppStrings.of(
      tester.element(find.byType(QuickCalcPage)),
    ).quickCalcHint;
    expect(find.text(hint), findsNothing);

    await tester.longPress(find.text('快速换算'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('unit options include jin despite not being a stored unit', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    final options = quickCalcUnitOptions(isZh: true);
    expect(options, contains('斤'));
    expect(find.text('斤').last, findsOneWidget);
  });

  testWidgets('fits on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byTooltip('添加'), findsOneWidget);
  });

  testWidgets('title bar opens the global conversion library', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.byTooltip('单位换算'), findsOneWidget);

    await tester.tap(find.byTooltip('单位换算'));
    await tester.pumpAndSettle();
    expect(find.byType(UnitConversionsPage), findsOneWidget);
  });

  testWidgets('global relations drive the draft preview', (tester) async {
    await UnitStore.instance.addRelation(
      fromUnit: '斤',
      toUnit: 'kg',
      factor: 0.4,
    );
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).at(1), '30');
    await tester.enterText(find.byType(TextField).at(2), '1');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('斤').last);
    await tester.pumpAndSettle();

    expect(find.text('¥30 / 斤'), findsOneWidget);
    expect(find.text('¥75 / kg'), findsOneWidget);
  });

  testWidgets('weight group header fits on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.enterText(find.byType(TextField).at(2), '5');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('斤').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('添加'));
    await tester.pumpAndSettle();
    await commitDraft(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('quick-calc-primary-weight')),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('quick-calc-primary-weight')))
          .right,
      greaterThan(280),
    );
  });

  testWidgets('group header switches the primary display unit', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.enterText(find.byType(TextField).at(2), '5');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('斤').last);
    await tester.pumpAndSettle();
    await commitDraft(tester);

    final selector = find.byKey(const ValueKey('quick-calc-primary-weight'));
    expect(selector, findsOneWidget);
    expect(tester.getRect(selector).right, greaterThan(760));
    final dividerRect = tester.getRect(find.byType(Divider).first);
    expect(tester.getRect(selector).left - dividerRect.right, lessThan(20));
    expect(
      find.descendant(of: selector, matching: find.text('斤')),
      findsOneWidget,
    );

    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('kg').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: selector, matching: find.text('kg')),
      findsOneWidget,
    );
    expect(QuickCalcStore.instance.primaryUnits['weight'], 'kg');
  });
}
