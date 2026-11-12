import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/screens/data_center_page.dart';
import 'package:zhidang/screens/main_shell.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await UnitStore.instance.load(locale: const Locale('zh'));
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
    expect(find.text('管理供应商'), findsOneWidget);
    expect(find.text('管理商品大类'), findsOneWidget);
    expect(find.text('管理单位'), findsOneWidget);
    expect(find.text('数据管理'), findsOneWidget);
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
