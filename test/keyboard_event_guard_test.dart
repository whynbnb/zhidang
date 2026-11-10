import 'package:flutter_test/flutter_test.dart';
import 'package:zhidang/services/keyboard_event_guard.dart';

void main() {
  group('isInconsistentModifierKeyDown', () {
    test('drops a repeated shift key-down without the shift flag', () {
      expect(
        isInconsistentModifierKeyDown(<String, Object?>{
          'keymap': 'macos',
          'type': 'keydown',
          'keyCode': 56,
          'modifiers': 0x20000000,
          'repeat': true,
        }),
        isTrue,
      );
    });

    test('keeps a shift key-down that carries the shift flag', () {
      expect(
        isInconsistentModifierKeyDown(<String, Object?>{
          'keymap': 'macos',
          'type': 'keydown',
          'keyCode': 56,
          'modifiers': 0x20000,
        }),
        isFalse,
      );
    });

    test('keeps non-modifier keys', () {
      expect(
        isInconsistentModifierKeyDown(<String, Object?>{
          'keymap': 'macos',
          'type': 'keydown',
          'keyCode': 0,
          'modifiers': 0,
        }),
        isFalse,
      );
    });

    test('keeps key-up events', () {
      expect(
        isInconsistentModifierKeyDown(<String, Object?>{
          'keymap': 'macos',
          'type': 'keyup',
          'keyCode': 56,
          'modifiers': 0,
        }),
        isFalse,
      );
    });

    test('ignores other platforms', () {
      expect(
        isInconsistentModifierKeyDown(<String, Object?>{
          'keymap': 'windows',
          'type': 'keydown',
          'keyCode': 56,
          'modifiers': 0,
        }),
        isFalse,
      );
    });

    test('ignores malformed messages', () {
      expect(isInconsistentModifierKeyDown(null), isFalse);
      expect(isInconsistentModifierKeyDown('nope'), isFalse);
      expect(
        isInconsistentModifierKeyDown(<String, Object?>{
          'keymap': 'macos',
          'type': 'keydown',
          'keyCode': '56',
          'modifiers': 0,
        }),
        isFalse,
      );
    });
  });
}
