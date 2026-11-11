import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/services/quick_calc_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await QuickCalcStore.instance.clear();
  });

  tearDown(() async {
    await QuickCalcStore.instance.clear();
  });

  test('pinned rows survive a memory reset and reload', () async {
    final entry = QuickCalcStore.instance.commit(
      name: '鸡蛋',
      price: 123,
      quantity: 213,
      unit: '个',
    );
    await QuickCalcStore.instance.togglePin(entry.id);
    expect(QuickCalcStore.instance.entries.single.pinned, isTrue);

    QuickCalcStore.instance.clearMemory();
    expect(QuickCalcStore.instance.entries, isEmpty);

    await QuickCalcStore.instance.load();
    expect(QuickCalcStore.instance.entries, hasLength(1));
    final restored = QuickCalcStore.instance.entries.single;
    expect(restored.pinned, isTrue);
    expect(restored.name, '鸡蛋');
    expect(restored.price, 123);
    expect(restored.quantity, 213);
    expect(restored.unit, '个');
  });

  test('unpinned rows are not restored', () async {
    final entry = QuickCalcStore.instance.commit(
      name: '鸡蛋',
      price: 20,
      quantity: 15,
      unit: '个',
    );
    await QuickCalcStore.instance.togglePin(entry.id);
    await QuickCalcStore.instance.togglePin(entry.id);

    QuickCalcStore.instance.clearMemory();
    await QuickCalcStore.instance.load();
    expect(QuickCalcStore.instance.entries, isEmpty);
  });
}
