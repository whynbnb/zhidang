import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/l10n/app_strings.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/screens/quick_calc_page.dart';
import 'package:zhidang/screens/unit_conversions_page.dart';
import 'package:zhidang/services/quick_calc_store.dart';
import 'package:zhidang/services/storage_service.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/utils/quick_calc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await QuickCalcStore.instance.clear();
    QuickCalcStore.instance.draft.unit = '';
    await AppSettings.instance.load();
    await UnitStore.instance.load(locale: AppSettings.instance.locale);
    await UnitStore.instance.replaceRelations(const []);
  });

  tearDown(() async {
    await QuickCalcStore.instance.clear();
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

  Future<void> openAddSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('添加换算'));
    await tester.pumpAndSettle();
  }

  Future<void> commitDraft(WidgetTester tester) async {
    await tester.tap(find.byTooltip('添加'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseUnit(WidgetTester tester, String unit) async {
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    dropdown.onChanged?.call(unit);
    await tester.pumpAndSettle();
  }

  testWidgets('keeps one editor and locks rows after adding', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(tester);
    await openAddSheet(tester);
    expect(find.byType(TextField), findsNWidgets(3));

    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '15');
    await tester.pump();
    expect(find.text('¥1.33 / 个'), findsOneWidget);
    await commitDraft(tester);

    // The add sheet closes after saving and the row is fixed on the page.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('¥1.33 / 个'), findsOneWidget);
    expect(find.text('¥20 / 15 个'), findsOneWidget);

    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '9.6');
    await tester.enterText(find.byType(TextField).at(1), '400');
    await chooseUnit(tester, 'g');
    expect(find.text('¥12 / 斤'), findsOneWidget);
    expect(find.text('¥24 / kg'), findsOneWidget);
    await commitDraft(tester);
    expect(find.text('¥12 / 斤'), findsOneWidget);

    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '10');
    await tester.enterText(find.byType(TextField).at(1), '15');
    await chooseUnit(tester, '个');
    await commitDraft(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('¥0.67 / 个'), findsOneWidget);
    expect(find.text('最低'), findsOneWidget);
    expect(find.text('+100%'), findsOneWidget);
    expect(find.byTooltip('删除这组数据'), findsNWidgets(3));
    expect(find.text('单位：个'), findsOneWidget);
    expect(find.text('重量'), findsOneWidget);
    // Hand-typed rows carry no saved-offer badge.
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
  });

  testWidgets('keeps committed rows and the draft during the session', (
    tester,
  ) async {
    await pumpPage(tester);
    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '15');
    await tester.pump();
    await commitDraft(tester);

    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '9.6');
    await tester.enterText(find.byType(TextField).at(1), '400');
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpPage(tester);
    await openAddSheet(tester);

    expect(find.text('¥1.33 / 个'), findsOneWidget);
    expect(find.text('¥20 / 15 个'), findsOneWidget);
    expect(find.text('9.6'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
  });

  testWidgets('add sheet has no helper text and autofocuses price', (
    tester,
  ) async {
    await pumpPage(tester);
    await openAddSheet(tester);
    expect(find.text('填写总价和数量后显示单价'), findsNothing);
    expect(
      find.text('填好后点右侧 ✓ 保留；点图钉固定后，下次打开仍保留'),
      findsNothing,
    );

    final priceNode =
        tester.widget<TextField>(find.byType(TextField).at(0)).focusNode!;
    expect(priceNode.hasFocus, isTrue);

    await tester.enterText(find.byType(TextField).at(0), '10');
    await tester.enterText(find.byType(TextField).at(1), '4');
    await tester.pump();
    expect(find.text('¥2.5 / 个'), findsOneWidget);

    await commitDraft(tester);
    expect(find.text('¥10 / 4 个'), findsOneWidget);
  });

  testWidgets('keyboard done commits the draft', (tester) async {
    await pumpPage(tester);
    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '8');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('¥4 / 个'), findsOneWidget);
    expect(find.text('¥8 / 2 个'), findsOneWidget);
  });

  testWidgets('combo mode multiplies recorded items toward a target', (
    tester,
  ) async {
    QuickCalcStore.instance.commit(
      name: '鸡蛋',
      price: 10,
      quantity: 1,
      unit: '个',
    );
    QuickCalcStore.instance.commit(
      name: '牛奶',
      price: 20,
      quantity: 1,
      unit: '个',
    );
    await pumpPage(tester);

    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '目标金额（元）'),
      '50',
    );
    await tester.pump();

    final addButtons = find.byTooltip('增加一份');
    expect(addButtons, findsNWidgets(2));
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('¥20'), findsOneWidget);
    expect(find.text('小计 ¥20'), findsOneWidget);

    await tester.tap(addButtons.last);
    await tester.pumpAndSettle();
    expect(find.text('¥40'), findsOneWidget);
    expect(find.text('还差 ¥10'), findsOneWidget);

    await tester.tap(addButtons.last);
    await tester.pumpAndSettle();
    expect(find.text('¥60'), findsOneWidget);
    expect(find.text('超出 ¥10'), findsOneWidget);

    await tester.tap(find.byTooltip('减少一份').first);
    await tester.pumpAndSettle();
    expect(find.text('×1'), findsOneWidget);
    expect(find.text('¥50'), findsOneWidget);
    expect(find.text('已凑够'), findsOneWidget);
  });

  testWidgets('saved offer picker fits and filters on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await StorageService().saveProducts([
      Product(
        name: '有机散养土鸡蛋礼盒装',
        units: const ['个'],
        offers: [
          Offer(
            brand: '某某农场精选',
            price: 123.5,
            unit: '个',
            quantity: 30,
            shop: '盒马鲜生',
            shopArea: '生鲜区',
          ),
        ],
      ),
    ]);

    await pumpPage(tester);
    await openAddSheet(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('从商品报价添加'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('选择商品报价'), findsOneWidget);
    expect(find.text('有机散养土鸡蛋礼盒装'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '盒马');
    await tester.pumpAndSettle();
    expect(find.text('某某农场精选'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '不存在');
    await tester.pumpAndSettle();
    expect(find.text('还没有已保存的商品报价'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds offers that were already saved with products', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await StorageService().saveProducts([
      Product(
        name: '鸡蛋',
        units: const ['个'],
        offers: [
          Offer(
            brand: '正大',
            price: 20,
            unit: '个',
            quantity: 15,
            shop: '盒马',
            shopArea: '生鲜区',
          ),
          Offer(brand: '德青源', price: 30, unit: '个', quantity: 20),
        ],
      ),
    ]);

    await pumpPage(tester);
    await openAddSheet(tester);
    await tester.tap(find.text('从商品报价添加'));
    await tester.pumpAndSettle();

    expect(find.text('选择商品报价'), findsOneWidget);
    expect(find.text('鸡蛋'), findsOneWidget);
    expect(find.text('正大'), findsOneWidget);
    expect(find.text('¥20 / 15个 · 盒马 · 生鲜区'), findsOneWidget);

    await tester.tap(find.text('正大'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加 1 项'));
    await tester.pumpAndSettle();

    expect(find.text('鸡蛋 · 正大'), findsOneWidget);
    expect(find.text('¥20 / 15 个'), findsOneWidget);
    expect(find.text('已添加 1 项商品报价'), findsOneWidget);
    // Copied rows carry a small source icon instead of a text badge.
    expect(find.text('已有报价'), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byTooltip('来自已保存的商品报价'), findsOneWidget);
  });

  testWidgets('saved offers start selected in the bundle tab', (tester) async {
    await StorageService().saveProducts([
      Product(
        name: '牛奶',
        units: const ['盒'],
        offers: [Offer(brand: '光明', price: 25, unit: '盒', quantity: 10)],
      ),
    ]);

    await pumpPage(tester);
    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();
    await openAddSheet(tester);
    await tester.tap(find.text('从商品报价添加'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('光明'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加 1 项'));
    await tester.pumpAndSettle();

    expect(find.text('牛奶 · 光明'), findsOneWidget);
    expect(find.text('×1'), findsOneWidget);
    expect(find.text('小计 ¥25'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('combo header keeps its height when a portion is added', (
    tester,
  ) async {
    QuickCalcStore.instance.commit(
      name: '牛奶',
      price: 25,
      quantity: 10,
      unit: '盒',
    );
    await pumpPage(tester);
    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('quick-calc-combo-header'));
    final before = tester.getSize(header);
    final clear = find.byKey(const ValueKey('quick-calc-combo-clear'));
    expect(tester.widget<AnimatedOpacity>(clear).opacity, 0);

    await tester.tap(find.byTooltip('增加一份'));
    await tester.pumpAndSettle();

    expect(tester.getSize(header), before);
    expect(tester.widget<AnimatedOpacity>(clear).opacity, 1);
    expect(find.text('×1'), findsOneWidget);
  });

  testWidgets('combo tab reuses the add sheet and starts at one', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('添加换算'), findsOneWidget);

    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.enterText(find.byType(TextField).at(2), '1');
    await tester.pump();
    await commitDraft(tester);

    expect(find.text('×1'), findsOneWidget);
    expect(find.text('小计 ¥12'), findsOneWidget);
    expect(find.text('¥12'), findsOneWidget);

    await tester.tap(find.text('换算'));
    await tester.pumpAndSettle();
    expect(find.text('¥12 / 1 个'), findsOneWidget);

    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();
    expect(find.text('×1'), findsOneWidget);

    await tester.tap(find.byTooltip('减少一份'));
    await tester.pumpAndSettle();
    expect(find.text('×0'), findsOneWidget);
    expect(find.text('小计 ¥12'), findsNothing);
    expect(find.text('¥0'), findsOneWidget);
  });

  testWidgets('combo mode fits on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    QuickCalcStore.instance.commit(
      name: '很长很长的商品名称用于测试',
      price: 123.45,
      quantity: 6,
      unit: '个',
    );
    await pumpPage(tester);
    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('增加一份'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, '目标金额（元）'),
      '100',
    );
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('增加一份'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('增加一份'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('超出 ¥23.45'), findsOneWidget);
  });

  testWidgets('long press edits the combo count directly', (tester) async {
    QuickCalcStore.instance.commit(
      name: '鸡蛋',
      price: 10,
      quantity: 1,
      unit: '个',
    );
    await pumpPage(tester);
    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('×0'));
    await tester.pumpAndSettle();
    expect(find.text('修改数量'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '份数'),
      '7',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('×7'), findsOneWidget);
    expect(find.text('小计 ¥70'), findsOneWidget);

    await tester.longPress(find.text('×7'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '份数'),
      '0',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('×0'), findsOneWidget);
    expect(find.text('¥0'), findsOneWidget);
  });

  testWidgets('combo mode points back to convert when empty', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('凑单'));
    await tester.pumpAndSettle();

    expect(find.text('还没有可凑单的商品'), findsOneWidget);
    await tester.tap(find.text('去换算'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('添加换算'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
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
    await openAddSheet(tester);
    final button = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<String>).first,
        matching: find.byType(DropdownButton<String>),
      ),
    );
    final options = quickCalcUnitOptions(isZh: true);
    expect(options, contains('斤'));
    expect(
      button.items!.map((item) => item.value),
      contains('斤'),
    );
  });

  testWidgets('fits on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('添加换算'), findsOneWidget);

    await openAddSheet(tester);
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
    await openAddSheet(tester);

    await tester.enterText(find.byType(TextField).at(0), '30');
    await tester.enterText(find.byType(TextField).at(1), '1');
    await chooseUnit(tester, '斤');

    expect(find.text('¥30 / 斤'), findsOneWidget);
    expect(find.text('¥75 / kg'), findsOneWidget);
  });

  testWidgets('weight group header fits on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(tester);
    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await chooseUnit(tester, '斤');
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
    await openAddSheet(tester);

    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await chooseUnit(tester, '斤');
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

  testWidgets('rows can be pinned and unpinned', (tester) async {
    await pumpPage(tester);
    await openAddSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await chooseUnit(tester, '斤');
    await commitDraft(tester);

    expect(find.byTooltip('固定，下次打开仍保留'), findsOneWidget);
    await tester.tap(find.byTooltip('固定，下次打开仍保留'));
    await tester.pumpAndSettle();

    expect(QuickCalcStore.instance.entries.single.pinned, isTrue);
    expect(find.byIcon(Icons.push_pin), findsOneWidget);

    await tester.tap(find.byTooltip('取消固定'));
    await tester.pumpAndSettle();
    expect(QuickCalcStore.instance.entries.single.pinned, isFalse);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
  });

  test('pinned saved offers keep their source flag across a restart', () async {
    final store = QuickCalcStore.instance;
    final entry = store.commit(
      name: '抽纸',
      price: 10,
      quantity: 500,
      unit: '包',
      fromSaved: true,
    );
    await store.togglePin(entry.id);

    store.clearMemory();
    await store.load();

    expect(store.entries.single.fromSaved, isTrue);
    expect(store.entries.single.name, '抽纸');
  });
}
