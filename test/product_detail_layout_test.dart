import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/main.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/comparison_store.dart';
import 'package:zhidang/services/storage_service.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/widgets/offer_tile.dart';

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
    await StorageService().saveProducts([
      Product(
        name: '鸡蛋',
        units: ['个', 'kg'],
        offers: [
          Offer(
            brand: 'A',
            price: 20,
            unit: '个',
            quantity: 30,
            favorite: true,
          ),
          Offer(brand: 'B', price: 15, unit: '个', quantity: 20),
          Offer(brand: 'C', price: 12, unit: 'kg', quantity: 1),
        ],
      ),
    ]);
  });

  Future<void> pumpDetail(
    WidgetTester tester,
    Size size, {
    required bool compact,
  }) async {
    await AppSettings.instance.setCompactMode(compact);
    addTearDown(() => AppSettings.instance.setCompactMode(false));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();
    final offers = find.byType(OfferTile);
    if (offers.evaluate().isEmpty) {
      await tester.tap(find.text('鸡蛋').first);
      await tester.pumpAndSettle();
    }

    expect(offers, findsWidgets);
    expect(tester.takeException(), isNull);
  }

  testWidgets('detail header fits on a phone', (tester) async {
    await pumpDetail(tester, const Size(320, 640), compact: false);
    expect(find.text('商品比价 - 鸡蛋'), findsOneWidget);
    expect(find.text('3 个品牌'), findsOneWidget);
    expect(find.byTooltip('只看收藏'), findsOneWidget);
  });

  testWidgets('favorites filter is hidden when nothing is favorited', (
    tester,
  ) async {
    await StorageService().saveProducts([
      Product(
        name: '鸡蛋',
        units: ['个'],
        offers: [Offer(brand: 'A', price: 20, unit: '个', quantity: 30)],
      ),
    ]);
    await pumpDetail(tester, const Size(320, 640), compact: false);
    expect(find.byTooltip('只看收藏'), findsNothing);
    expect(find.text('1 个品牌'), findsOneWidget);
    expect(find.text('度量维度：个'), findsOneWidget);
  });

  testWidgets('detail header fits on a phone in compact mode', (tester) async {
    await pumpDetail(tester, const Size(320, 640), compact: true);
  });

  testWidgets('detail header fits on a wide window', (tester) async {
    await pumpDetail(tester, const Size(1280, 800), compact: false);
  });

  testWidgets('detail header fits on a wide window in compact mode', (
    tester,
  ) async {
    await pumpDetail(tester, const Size(1280, 800), compact: true);
  });

  testWidgets('editing opens a full page instead of a sheet', (tester) async {
    await pumpDetail(tester, const Size(390, 844), compact: false);

    await tester.tap(find.byTooltip('编辑商品'));
    await tester.pumpAndSettle();
    expect(find.text('编辑商品'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();
    expect(find.text('编辑报价'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('edit form hints appear on long press', (tester) async {
    await pumpDetail(tester, const Size(390, 844), compact: false);
    await tester.tap(find.byTooltip('编辑商品'));
    await tester.pumpAndSettle();

    expect(find.text('可选；加入后继承大类单位'), findsNothing);
    await tester.longPress(find.text('所属大类'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('可选；加入后继承大类单位'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.ensureVisible(find.text('标签'));
    await tester.pumpAndSettle();
    expect(find.text('最多 5 个；输入添加，点击标签可移除'), findsNothing);
    await tester.longPress(find.text('标签'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('最多 5 个；输入添加，点击标签可移除'), findsOneWidget);
  });

  testWidgets('offer form shows per-unit price', (tester) async {
    await pumpDetail(tester, const Size(320, 640), compact: false);
    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('¥0.67 / 个'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '30');
    await tester.pump();
    expect(find.text('¥1 / 个'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('counter options live under advanced options', (tester) async {
    await pumpDetail(tester, const Size(390, 844), compact: false);
    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();

    expect(find.text('计数器'), findsNothing);
    await tester.ensureVisible(find.text('高级选项'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('高级选项'));
    await tester.pumpAndSettle();

    expect(find.text('计数器'), findsOneWidget);
    expect(find.text('时间记录'), findsOneWidget);
  });

  testWidgets('edit page saves from the app bar', (tester) async {
    await pumpDetail(tester, const Size(390, 844), compact: false);
    await tester.tap(find.byTooltip('编辑商品'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '鸡蛋2');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('商品比价 - 鸡蛋2'), findsOneWidget);
  });

  testWidgets('unsaved edits ask before leaving', (tester) async {
    await pumpDetail(tester, const Size(390, 844), compact: false);
    await tester.tap(find.byTooltip('编辑商品'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '鸡蛋2');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);

    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('编辑商品'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.text('商品比价 - 鸡蛋'), findsOneWidget);
  });

  testWidgets('offer edit only prompts after changes', (tester) async {
    await pumpDetail(tester, const Size(390, 844), compact: false);

    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsNothing);
    expect(find.text('商品比价 - 鸡蛋'), findsOneWidget);

    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'A2');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('放弃修改？'), findsOneWidget);
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
  });

  testWidgets('compact product card uses short badges', (tester) async {
    await AppSettings.instance.setCompactMode(true);
    addTearDown(() => AppSettings.instance.setCompactMode(false));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();

    expect(find.text('2 维度'), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(find.textContaining('单位：'), findsNothing);
  });

  testWidgets('detail header fits on a phone in English', (tester) async {
    await AppSettings.instance.setLocaleMode(LocaleMode.en);
    addTearDown(() => AppSettings.instance.setLocaleMode(LocaleMode.zh));
    await pumpDetail(tester, const Size(320, 640), compact: false);
  });
}
