import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/screens/data_manage_page.dart';
import 'package:zhidang/services/backup_service.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/storage_service.dart';
import 'package:zhidang/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      AppSettings.instance.load(),
      CategoryStore.instance.load(),
    ]);
  });

  test('CSV export has product rows, offer measures and escaped fields', () async {
    final category = await CategoryStore.instance.add(
      name: '食品',
      units: const ['g', 'kg'],
    );
    await StorageService().saveProducts([
      Product(
        name: '鸡蛋',
        units: const ['g', 'kg'],
        categoryId: category.id,
        tags: const ['早餐'],
        note: '含 "引号", 逗号',
        offers: [
          Offer(
            brand: 'A',
            price: 10,
            measures: [
              OfferMeasure(unit: 'g', quantity: 500),
              OfferMeasure(unit: 'kg', quantity: 0.5),
            ],
            tags: const ['促销'],
            shop: '盒马',
            note: '第一行\n第二行',
            favorite: true,
            limitedPrice: true,
          ),
        ],
      ),
      Product(
        name: '牛奶',
        units: const ['L'],
        tags: const ['饮品'],
      ),
    ]);

    final csv = await BackupService.instance.buildCsv();
    final lines = csv.split('\r\n');

    expect(
      lines.first,
      '"商品","大类","商品标签","品牌/规格","总价","数量","单位","单价","报价标签","店铺","报价备注","收藏","限时","商品备注","更新时间"',
    );
    expect(lines, hasLength(4));
    expect(
      csv,
      contains(
        '"鸡蛋","食品","早餐","A","10","500","g","0.02","促销","盒马","第一行\n第二行","是","是","含 ""引号"", 逗号"',
      ),
    );
    expect(
      csv,
      contains(
        '"鸡蛋","食品","早餐","A","10","0.5","kg","20","促销","盒马"',
      ),
    );
    expect(
      csv,
      contains(
        '"牛奶","","饮品","","","","","","","","","","","",""',
      ),
    );
  });

  testWidgets('data management exposes CSV export', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DataManagePage()));
    await tester.pumpAndSettle();

    expect(find.text('导出 CSV'), findsOneWidget);
    expect(find.text('导出商品与报价明细，便于在表格中分析'), findsOneWidget);
  });
}
