import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/l10n/app_strings.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/screens/product_form_sheet.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/widgets/tag_chips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      AppSettings.instance.load(),
      CategoryStore.instance.load(),
      UnitStore.instance.load(locale: AppSettings.instance.locale),
    ]);
  });

  testWidgets('tag picker adds a suggested tag with one tap', (tester) async {
    var selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: AppStrings.provide(
          locale: const Locale('zh'),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TagPicker(
                  selected: selected,
                  suggestions: const ['促销', '会员价', '促销'],
                  onChanged: (next) => setState(() => selected = next),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('当前大类已有标签（点击添加）'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ActionChip, '促销'));
    await tester.pumpAndSettle();

    expect(selected, {'促销'});
    expect(find.widgetWithText(InputChip, '促销'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '促销'), findsNothing);
    expect(find.byType(ActionChip), findsOneWidget);
  });

  testWidgets('product form suggests tags used in its category', (
    tester,
  ) async {
    final category = await CategoryStore.instance.add(
      name: '食品',
      units: const ['个'],
    );
    final other = Product(
      name: '牛奶',
      units: const ['个'],
      categoryId: category.id,
      tags: const ['冷藏', '促销'],
    );
    final outside = Product(
      name: '纸巾',
      units: const ['个'],
      tags: const ['日用品'],
    );
    final editing = Product(
      name: '鸡蛋',
      units: const ['个'],
      categoryId: category.id,
      tags: const ['早餐'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showProductForm(
                context,
                product: editing,
                allProducts: [editing, other, outside],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('标签'));
    await tester.pumpAndSettle();

    expect(find.text('当前大类已有标签（点击添加）'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '冷藏'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '促销'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '日用品'), findsNothing);
    expect(find.widgetWithText(ActionChip, '早餐'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, '冷藏'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '冷藏'), findsOneWidget);
  });

  testWidgets('offer form suggests tags used by the product offers', (
    tester,
  ) async {
    final existing = Offer(
      brand: 'A',
      price: 20,
      unit: '个',
      quantity: 10,
      tags: const ['临期', '促销'],
    );
    final current = Offer(
      brand: 'B',
      price: 18,
      unit: '个',
      quantity: 10,
      tags: const ['会员'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showOfferForm(
                context,
                offer: current,
                units: const ['个'],
                productOffers: [existing, current],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('标签'));
    await tester.pumpAndSettle();

    expect(find.text('此商品报价已有标签（点击添加）'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '临期'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '促销'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '会员'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, '临期'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '临期'), findsOneWidget);
  });
}
