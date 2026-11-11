import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/screens/units_page.dart';
import 'package:zhidang/services/unit_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UnitStore.instance.load(locale: const Locale('zh'));
  });

  test('reorders units and sorts display lists', () async {
    await UnitStore.instance.add(name: '斤');
    final names = UnitStore.instance.names;
    expect(names.last, '斤');

    await UnitStore.instance.reorder(names.length - 1, 0);
    expect(UnitStore.instance.names.first, '斤');

    await UnitStore.instance.reorder(0, 2);
    expect(UnitStore.instance.names[2], '斤');

    expect(
      UnitStore.instance.sortUnits(['片', '斤', 'g', 'kg']),
      ['g', 'kg', '斤', '片'],
    );
    expect(
      UnitStore.instance.sortUnits(['abc', '斤', 'g']),
      ['g', '斤', 'abc'],
    );
  });

  testWidgets('units page offers drag handles outside search', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnitsPage()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_handle), findsWidgets);

    await tester.enterText(find.byType(TextField), 'g');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_handle), findsNothing);
  });
}
