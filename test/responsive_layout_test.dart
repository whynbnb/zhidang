import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/main.dart';
import 'package:zhidang/services/category_store.dart';
import 'package:zhidang/services/comparison_store.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/settings/app_settings.dart';
import 'package:zhidang/utils/layout.dart';

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
  });

  testWidgets('responsive scope uses constraints instead of stale media size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpAt(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 400,
                child: ResponsiveWidthScope(
                  child: Builder(
                    builder: (context) => Text(
                      AppLayout.isWide(context) ? 'wide' : 'narrow',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpAt(420);
    expect(find.text('narrow'), findsOneWidget);

    await pumpAt(900);
    expect(find.text('wide'), findsOneWidget);
  });

  testWidgets('home header survives a small-window round trip', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);

    tester.view.physicalSize = const Size(390, 700);
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);
  });
}
