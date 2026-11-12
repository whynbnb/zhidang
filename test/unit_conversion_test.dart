import 'package:flutter_test/flutter_test.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/utils/comparison_logic.dart';

void main() {
  test('product relations convert offer quantities and prices', () {
    final product = Product(
      name: '鸡蛋',
      units: const ['个', '斤', 'kg'],
      relations: [
        UnitRelation(fromUnit: '斤', toUnit: 'kg', factor: 0.5),
      ],
      offers: [
        Offer(
          brand: 'A',
          price: 20,
          measures: [
            OfferMeasure(unit: '个', quantity: 30),
            OfferMeasure(unit: 'kg', quantity: 2),
          ],
        ),
      ],
    );
    final offer = product.offers.single;

    expect(product.quantityForOffer(offer, '斤'), closeTo(4, 1e-9));
    expect(product.unitPriceForOffer(offer, '斤'), closeTo(5, 1e-9));
    expect(product.offersFor('斤'), [offer]);
    expect(product.bestOfferFor('斤'), offer);
    expect(product.offersFor('个'), [offer]);
  });

  test('built-in kilogram conversion applies without custom relations', () {
    final product = Product(
      name: '大米',
      units: const ['g', 'kg'],
      offers: [
        Offer(brand: 'A', price: 10, unit: 'g', quantity: 500),
      ],
    );
    final offer = product.offers.single;

    expect(product.quantityForOffer(offer, 'kg'), closeTo(0.5, 1e-9));
    expect(product.unitPriceForOffer(offer, 'kg'), closeTo(20, 1e-9));
  });

  test('offer-level relations also drive unit prices', () {    final product = Product(
      name: '纸巾',
      units: const ['包', '张'],
      offers: [
        Offer(
          brand: 'A',
          price: 10,
          unit: '包',
          quantity: 1,
          relations: [
            UnitRelation(fromUnit: '包', toUnit: '张', factor: 200),
          ],
        ),
      ],
    );
    final offer = product.offers.single;

    expect(product.quantityForOffer(offer, '张'), closeTo(200, 1e-9));
    expect(product.unitPriceForOffer(offer, '张'), closeTo(0.05, 1e-9));
  });

  test('cross-product comparison uses converted unit prices', () {
    final product = Product(
      name: '鸡蛋',
      units: const ['个', '斤', 'kg'],
      relations: [
        UnitRelation(fromUnit: '斤', toUnit: 'kg', factor: 0.5),
      ],
      offers: [
        Offer(
          brand: 'A',
          price: 20,
          measures: [
            OfferMeasure(unit: '个', quantity: 30),
            OfferMeasure(unit: 'kg', quantity: 2),
          ],
        ),
      ],
    );

    final rows = ComparisonLogic.rank([product], unit: '斤');
    expect(rows, hasLength(1));
    expect(rows.single.unitPrice, closeTo(5, 1e-9));
  });

  test('moving an offer converts it to the target product units', () {
    final source = Product(
      name: '鸡蛋',
      units: const ['g'],
      offers: [
        Offer(brand: 'A', price: 10, unit: 'g', quantity: 500),
      ],
    );
    final target = Product(name: '鸡蛋礼盒', units: const ['kg']);

    final moved = target.adaptOffer(source.offers.single);

    expect(moved, isNotNull);
    expect(moved!.brand, 'A');
    expect(moved.price, 10);
    expect(moved.measures, hasLength(1));
    expect(moved.measures.single.unit, 'kg');
    expect(moved.measures.single.quantity, closeTo(0.5, 1e-9));
    expect(target.offers, isEmpty);
  });

  test('moving rejects an offer with incompatible target units', () {
    final source = Product(
      name: '鸡蛋',
      units: const ['g'],
      offers: [
        Offer(brand: 'A', price: 10, unit: 'g', quantity: 500),
      ],
    );
    final target = Product(name: '鸡蛋礼盒', units: const ['个']);

    expect(target.adaptOffer(source.offers.single), isNull);
  });

  test('moving uses offer-level relations when converting units', () {
    final source = Product(
      name: '纸巾',
      units: const ['盒'],
      offers: [
        Offer(
          brand: 'A',
          price: 20,
          unit: '盒',
          quantity: 1,
          relations: [
            UnitRelation(fromUnit: '盒', toUnit: 'g', factor: 500),
          ],
        ),
      ],
    );
    final target = Product(name: '纸巾克重', units: const ['kg']);

    final moved = target.adaptOffer(source.offers.single);

    expect(moved, isNotNull);
    expect(moved!.measures.single.unit, 'kg');
    expect(moved.measures.single.quantity, closeTo(0.5, 1e-9));
  });

  test('moving deduplicates convertible measures', () {
    final source = Product(
      name: '鸡蛋',
      units: const ['g', 'kg'],
      offers: [
        Offer(
          brand: 'A',
          price: 10,
          measures: [
            OfferMeasure(unit: 'g', quantity: 500),
            OfferMeasure(unit: 'kg', quantity: 0.5),
          ],
        ),
      ],
    );
    final target = Product(name: '鸡蛋礼盒', units: const ['kg']);

    final moved = target.adaptOffer(source.offers.single);

    expect(moved, isNotNull);
    expect(moved!.measures, hasLength(1));
    expect(moved.measures.single.unit, 'kg');
    expect(moved.measures.single.quantity, closeTo(0.5, 1e-9));
  });

  test('moving keeps separate dimensions', () {
    final source = Product(
      name: '鸡蛋',
      units: const ['个', 'g'],
      offers: [
        Offer(
          brand: 'A',
          price: 10,
          measures: [
            OfferMeasure(unit: '个', quantity: 30),
            OfferMeasure(unit: 'g', quantity: 500),
          ],
        ),
      ],
    );
    final target = Product(name: '鸡蛋礼盒', units: const ['kg', '个']);

    final moved = target.adaptOffer(source.offers.single);

    expect(moved, isNotNull);
    expect(moved!.measures, hasLength(2));
    expect(moved.measures[0].unit, 'kg');
    expect(moved.measures[0].quantity, closeTo(0.5, 1e-9));
    expect(moved.measures[1].unit, '个');
    expect(moved.measures[1].quantity, 30);
  });

  test('moving can drop incompatible measures when allowed', () {
    final source = Product(
      name: '鸡蛋',
      units: const ['个', 'g'],
      offers: [
        Offer(
          brand: 'A',
          price: 10,
          measures: [
            OfferMeasure(unit: '个', quantity: 30),
            OfferMeasure(unit: 'g', quantity: 500),
          ],
        ),
      ],
    );
    final offer = source.offers.single;
    final target = Product(name: '牛奶', units: const ['kg']);

    final adaptation = target.adaptationFor(offer.measures);
    expect(adaptation, isNotNull);
    expect(adaptation!.measures.single.unit, 'kg');
    expect(adaptation.measures.single.quantity, closeTo(0.5, 1e-9));
    expect(adaptation.dropped.single.unit, '个');
    expect(adaptation.dropped.single.quantity, 30);
    expect(target.adaptOffer(offer), isNull);

    final moved = target.adaptOffer(offer, dropIncompatible: true);
    expect(moved, isNotNull);
    expect(moved!.measures.single.unit, 'kg');
    expect(moved.measures.single.quantity, closeTo(0.5, 1e-9));
  });
}
