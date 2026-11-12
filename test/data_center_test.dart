import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/models/product.dart';
import 'package:zhidang/screens/data_center_page.dart';
import 'package:zhidang/screens/main_shell.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/comparison_store.dart';
import 'package:zhidang/services/storage_service.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      AppSettings.instance.load(),
      UnitStore.instance.load(locale: const Locale('zh')),
      SupplierStore.instance.load(),
      CategoryStore.instance.load(),
      ComparisonStore.instance.load(),
    ]);
  });

  tearDown(() async {
    await AppSettings.instance.setDataCenterNavMode(
      DataCenterNavMode.defaultForPlatform(),
    );
    await AppSettings.instance.setSettingsEntryMode(
      SettingsEntryMode.defaultForPlatform(),
    );
    await AppSettings.instance.setCompareNavMode(
      CompareNavMode.defaultForPlatform(),
    );
  });

  test('data center follows its nav mode', () async {
    await AppSettings.instance
        .setDataCenterNavMode(DataCenterNavMode.bottomNav);
    expect(
      AppSettings.instance.navDestinations,
      contains(ShellNavDestination.dataCenter),
    );
    expect(AppSettings.instance.showDataCenterHeaderIcon, isFalse);

    await AppSettings.instance
        .setDataCenterNavMode(DataCenterNavMode.headerIcon);
    expect(
      AppSettings.instance.navDestinations,
      isNot(contains(ShellNavDestination.dataCenter)),
    );
    expect(AppSettings.instance.showDataCenterHeaderIcon, isTrue);
  });

  testWidgets('data center lists the data management pages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DataCenterPage(embedded: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('数据中心'), findsOneWidget);
    expect(find.text('快捷工具'), findsOneWidget);
    expect(find.text('数据维护'), findsOneWidget);
    expect(find.text('管理供应商'), findsOneWidget);
    expect(find.text('管理商品大类'), findsOneWidget);
    expect(find.text('管理单位'), findsOneWidget);
    expect(find.text('数据管理'), findsOneWidget);
  });

  testWidgets('data center shows overview counts and tools', (tester) async {
    await StorageService().saveProducts([
      Product(
        name: '鸡蛋',
        units: const ['个'],
        offers: [
          Offer(brand: 'A', price: 10, unit: '个', quantity: 10),
          Offer(brand: 'B', price: 20, unit: '个', quantity: 10),
        ],
      ),
      Product(
        name: '牛奶',
        units: const ['盒'],
        offers: [Offer(brand: 'C', price: 12, unit: '盒', quantity: 1)],
      ),
    ]);

    await tester.pumpWidget(
      const MaterialApp(home: DataCenterPage(embedded: true)),
    );
    await tester.pumpAndSettle();

    String stat(String id) => tester
        .widget<Text>(find.byKey(ValueKey('stat-$id-value')))
        .data!;

    expect(stat('products'), '2');
    expect(stat('offers'), '3');
    expect(find.text('单位换算'), findsOneWidget);
    expect(find.text('快速换算'), findsOneWidget);
    expect(find.text('未固定数据，打开后可固定常用换算'), findsOneWidget);
  });

  testWidgets('data center tab is reachable from the shell', (tester) async {
    await AppSettings.instance
        .setDataCenterNavMode(DataCenterNavMode.bottomNav);
    await AppSettings.instance
        .setSettingsEntryMode(SettingsEntryMode.headerIcon);
    await AppSettings.instance.setCompareNavMode(CompareNavMode.disabled);

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dataset_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dataset_outlined));
    await tester.pumpAndSettle();

    expect(find.text('数据中心'), findsOneWidget);
    expect(find.text('管理单位'), findsOneWidget);
  });
}
