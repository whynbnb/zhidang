import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/models/custom_unit.dart';
import 'package:zhidang/models/quantity_preset.dart';
import 'package:zhidang/screens/units_page.dart';
import 'package:zhidang/services/unit_store.dart';
import 'package:zhidang/utils/quantity_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UnitStore.instance.load(locale: const Locale('zh'));
  });

  test('unit presets persist, filter disabled entries and reset', () async {
    final added = await UnitStore.instance.add(
      name: '罐',
      presets: const [
        QuantityPreset(value: 1, label: '1罐'),
        QuantityPreset(value: 2, label: '2罐', enabled: false),
      ],
    );
    expect(added.presets, hasLength(2));
    expect(
      quantityPresetsFor('罐').map((preset) => preset.label),
      ['1罐'],
    );

    final restored = CustomUnit.fromJson(added.toJson());
    expect(restored.presets, hasLength(2));
    expect(restored.presets![0].enabled, isTrue);
    expect(restored.presets![1].enabled, isFalse);

    await UnitStore.instance.update(
      restored.copyWith(presets: const []),
    );
    expect(UnitStore.instance.findByName('罐')!.presets, isEmpty);
    expect(quantityPresetsFor('罐'), isEmpty);

    await UnitStore.instance.update(
      UnitStore.instance.findByName('罐')!.copyWith(resetPresets: true),
    );
    expect(UnitStore.instance.findByName('罐')!.presets, isNull);
    expect(quantityPresetsFor('罐'), isNotEmpty);
  });

  testWidgets('unit editor toggles and adds quick presets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnitsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('kg').first);
    await tester.pumpAndSettle();
    expect(find.text('快速数量预设'), findsOneWidget);

    final firstToggle = find.byKey(const ValueKey('unit-preset-toggle-0'));
    await tester.ensureVisible(firstToggle);
    await tester.pumpAndSettle();
    await tester.tap(firstToggle);
    await tester.pumpAndSettle();

    final input = find.byKey(const ValueKey('unit-preset-input'));
    await tester.ensureVisible(input);
    await tester.pumpAndSettle();
    await tester.enterText(input, '3');
    await tester.tap(find.byKey(const ValueKey('unit-preset-add')));
    await tester.pumpAndSettle();
    expect(find.text('3kg'), findsOneWidget);

    final save = find.text('保存');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final kg = UnitStore.instance.findByName('kg')!;
    expect(kg.presets, isNotNull);
    expect(kg.presets!.first.enabled, isFalse);
    expect(
      kg.presets!.any((preset) => preset.value == 3 && preset.label == '3kg'),
      isTrue,
    );
  });

  testWidgets('unit editor clears and restores quick presets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnitsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('kg').first);
    await tester.pumpAndSettle();

    final clear = find.text('清空');
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('还没有快速数量，可添加或恢复默认'), findsOneWidget);

    final restore = find.text('恢复默认');
    await tester.ensureVisible(restore);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pumpAndSettle();
    expect(find.text('100g'), findsOneWidget);
  });
}
