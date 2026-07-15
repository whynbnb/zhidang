import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/main.dart';
import 'package:zhidang/services/supplier_store.dart';
import 'package:zhidang/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      AppSettings.instance.load(),
      SupplierStore.instance.load(),
    ]);
  });

  testWidgets('值当 app loads', (tester) async {
    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsWidgets);
  });
}
