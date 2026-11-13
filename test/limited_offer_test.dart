import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/screens/product_form_sheet.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/widgets/offer_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Offer offer({
    required String brand,
    required double price,
    bool limitedPrice = false,
  }) {
    return Offer(
      brand: brand,
      price: price,
      unit: 'g',
      quantity: 100,
      limitedPrice: limitedPrice,
    );
  }

  test('limited prices are excluded from the best offer', () {
    final regular = offer(brand: 'A', price: 20);
    final limited = offer(brand: '限时特价', price: 10, limitedPrice: true);
    final product = Product(
      name: '咖啡豆',
      units: const ['g'],
      offers: [regular, limited],
    );

    expect(product.bestOfferFor('g'), same(regular));
    expect(product.cheapestOfferFor('g'), same(limited));
    expect(product.cheapestOfferFor('g', includeLimited: false), same(regular));
    expect(product.offersFor('g'), hasLength(2));
  });

  test('only limited offers leave the best price empty', () {
    final limited = offer(brand: '限时特价', price: 10, limitedPrice: true);
    final product = Product(
      name: '咖啡豆',
      units: const ['g'],
      offers: [limited],
    );

    expect(product.bestOfferFor('g'), isNull);
    expect(product.cheapestOfferFor('g'), same(limited));
  });

  test('limited flag survives JSON and copyWith', () {
    final original = offer(brand: 'A', price: 10, limitedPrice: true);
    final restored = Offer.fromJson(original.toJson());

    expect(restored.limitedPrice, isTrue);
    expect(restored.copyWith(price: 12).limitedPrice, isTrue);
    expect(restored.copyWith(limitedPrice: false).limitedPrice, isFalse);
    expect(offer(brand: 'B', price: 5).limitedPrice, isFalse);
  });

  testWidgets('offer tile marks limited prices', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();

    final limited = offer(brand: '限时特价', price: 10, limitedPrice: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferTile(
            offer: limited,
            unit: 'g',
            isBest: false,
            rank: 1,
            onEdit: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('限时'), findsOneWidget);
  });

  testWidgets('offer editor exposes the limited price option', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await UnitStore.instance.load(locale: AppSettings.instance.locale);

    final limited = offer(brand: '限时特价', price: 10, limitedPrice: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOfferForm(
                context,
                offer: limited,
                units: const ['g'],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('限时价格'), findsOneWidget);
    expect(
      find.text('不易买到，仅在列表中作为比较，不参与最优价计算'),
      findsOneWidget,
    );
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });
}
