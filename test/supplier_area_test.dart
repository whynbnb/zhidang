import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/models/supplier.dart';
import 'package:zhidang/screens/product_form_sheet.dart';
import 'package:zhidang/screens/suppliers_page.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await UnitStore.instance.load(locale: AppSettings.instance.locale);
    await SupplierStore.instance.load();
  });

  test('supplier areas are per supplier and survive JSON', () async {
    final supplier = Supplier(
      name: '盒马',
      areas: const ['熟食区', '生鲜区', ' 熟食区 '],
    );
    expect(supplier.areas, ['熟食区', '生鲜区']);

    final restored = Supplier.fromJson(supplier.toJson());
    expect(restored.areas, ['熟食区', '生鲜区']);

    await SupplierStore.instance.add(
      name: '盒马',
      areas: const ['熟食区'],
    );
    await SupplierStore.instance.add(name: '京东');
    expect(SupplierStore.instance.areasForName('盒马'), ['熟食区']);
    expect(SupplierStore.instance.areasForName('京东'), isEmpty);
  });

  test('offer keeps its supplier area and displays both', () {
    final offer = Offer(
      brand: 'A',
      price: 10,
      unit: 'g',
      quantity: 100,
      shop: '盒马',
      shopArea: '熟食区',
    );
    final restored = Offer.fromJson(offer.toJson());

    expect(restored.shop, '盒马');
    expect(restored.shopArea, '熟食区');
    expect(restored.shopLabel, '盒马 · 熟食区');

    final plain = Offer(
      brand: 'B',
      price: 8,
      unit: 'g',
      quantity: 100,
      shop: '京东',
    );
    expect(plain.shopLabel, '京东');
  });

  testWidgets('supplier form edits areas of the supplier', (tester) async {
    SupplierDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                draft = await showSupplierForm(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '盒马');
    await tester.enterText(
      find.widgetWithText(TextField, '添加区域'),
      '熟食区',
    );
    await tester.tap(find.byTooltip('添加区域'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    expect(draft?.name, '盒马');
    expect(draft?.areas, ['熟食区']);
  });

  testWidgets('offer editor picks an area of the chosen supplier', (
    tester,
  ) async {
    await SupplierStore.instance.add(
      name: '盒马',
      areas: const ['熟食区', '生鲜区'],
    );

    OfferFormResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showOfferForm(context, units: const ['g']);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('盒马').last);
    await tester.pumpAndSettle();

    // The area picker appears once the supplier has areas.
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    final areaDropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(areaDropdown);
    await tester.pumpAndSettle();
    await tester.tap(areaDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('熟食区').last);
    await tester.pumpAndSettle();
    expect(find.text('熟食区'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '促销价');
    await tester.enterText(fields.at(1), '10');
    await tester.enterText(fields.at(2), '100');
    await tester.pump();
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    expect(result?.offer?.shop, '盒马');
    expect(result?.offer?.shopArea, '熟食区');
  });
}
