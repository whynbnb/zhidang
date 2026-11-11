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

  test('offer-level relations also drive unit prices', () {
    final product = Product(
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
}
