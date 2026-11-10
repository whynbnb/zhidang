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
