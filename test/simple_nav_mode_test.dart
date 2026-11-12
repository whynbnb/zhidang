import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/screens/navigation_settings_page.dart';
import 'package:zhidang/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
  });

  tearDown(() async {
    await AppSettings.instance.setSimpleNavMode(false);
    await AppSettings.instance.setDataCenterNavMode(
      DataCenterNavMode.defaultForPlatform(),
    );
    await AppSettings.instance.setCompareNavMode(
      CompareNavMode.defaultForPlatform(),
    );
    await AppSettings.instance.setSettingsEntryMode(
      SettingsEntryMode.defaultForPlatform(),
    );
  });

  test('simple mode applies its preset and locks entries', () async {
    await AppSettings.instance.setSimpleNavMode(true);

    expect(AppSettings.instance.simpleNavMode, isTrue);
    expect(
      AppSettings.instance.dataCenterNavMode,
      DataCenterNavMode.headerIcon,
    );
    expect(AppSettings.instance.compareNavMode, CompareNavMode.dataCenter);
    expect(
      AppSettings.instance.settingsEntryMode,
      SettingsEntryMode.headerIcon,
    );
    expect(AppSettings.instance.navDestinations, isEmpty);

    await AppSettings.instance.setCompareNavMode(CompareNavMode.bottomNav);
    await AppSettings.instance.setDataCenterNavMode(
      DataCenterNavMode.bottomNav,
    );
    await AppSettings.instance.setSettingsEntryMode(
      SettingsEntryMode.navBar,
    );
    expect(AppSettings.instance.compareNavMode, CompareNavMode.dataCenter);
    expect(
      AppSettings.instance.dataCenterNavMode,
      DataCenterNavMode.headerIcon,
    );
    expect(
      AppSettings.instance.settingsEntryMode,
      SettingsEntryMode.headerIcon,
    );

    await AppSettings.instance.load();
    expect(AppSettings.instance.simpleNavMode, isTrue);
    expect(AppSettings.instance.compareNavMode, CompareNavMode.dataCenter);

    await AppSettings.instance.setSimpleNavMode(false);
    await AppSettings.instance.setCompareNavMode(CompareNavMode.bottomNav);
    expect(AppSettings.instance.compareNavMode, CompareNavMode.bottomNav);
  });

  testWidgets('simple mode is shown first and locks the options', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: NavigationSettingsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('简洁模式'), findsOneWidget);
    expect(find.textContaining('下方选项将锁定'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.simpleNavMode, isTrue);
    expect(find.textContaining('简洁模式下不可调整'), findsOneWidget);
    expect(AppSettings.instance.compareNavMode, CompareNavMode.dataCenter);
  });
}
