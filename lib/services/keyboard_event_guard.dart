import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Guards the framework against malformed macOS key events.
///
/// macOS (or an input method / keyboard remapper on top of it) can deliver a
/// repeated key-down for a modifier key while leaving the matching modifier
/// flag out of the event, for example:
///
///     Shift Left, repeat: true, modifiers: 0x20000000
///
/// `RawKeyboard` trusts the modifier flags, so it removes the just-inserted
/// modifier from its pressed-key table and trips the debug assertion
/// "Attempted to send a key down event when no keys are in keysPressed".
///
/// Such an event cannot be repaired reliably (the real modifier state is
/// unknown), so drop the key-down instead of feeding an inconsistent state to
/// the framework. Key-up events are left untouched, and normal key events that
/// carry the correct flags still synchronize the modifier state.
void installKeyboardEventGuard() {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  SystemChannels.keyEvent.setMessageHandler(_handleKeyEvent);
}

Future<Object?> _handleKeyEvent(Object? message) {
  if (isInconsistentModifierKeyDown(message)) {
    assert(() {
      if (!_reportedInconsistentEvent) {
        _reportedInconsistentEvent = true;
        debugPrint(
          '[keyboard] Ignored inconsistent macOS modifier key-down event.',
        );
      }
      return true;
    }());
    return SynchronousFuture<Object?>(<String, Object?>{'handled': true});
  }
  // ignore: deprecated_member_use
  return ServicesBinding.instance.keyEventManager.handleRawKeyMessage(message);
}

bool _reportedInconsistentEvent = false;

const int _flagShift = 0x20000;
const int _flagControl = 0x40000;
const int _flagOption = 0x80000;
const int _flagCommand = 0x100000;

/// The modifier flag an event must carry when [keyCode] is the key itself.
///
/// Values are macOS virtual key codes (`kVK_*`) for the left/right variants of
/// the four modifier keys.
int _modifierFlagForKeyCode(int keyCode) {
  switch (keyCode) {
    case 56: // kVK_Shift
    case 60: // kVK_RightShift
      return _flagShift;
    case 59: // kVK_Control
    case 62: // kVK_RightControl
      return _flagControl;
    case 58: // kVK_Option
    case 61: // kVK_RightOption
      return _flagOption;
    case 55: // kVK_Command
    case 54: // kVK_RightCommand
      return _flagCommand;
    default:
      return 0;
  }
}

/// Whether [message] is a macOS modifier key-down that does not carry its own
/// modifier flag, which would put `RawKeyboard` into an invalid state.
@visibleForTesting
bool isInconsistentModifierKeyDown(Object? message) {
  if (message is! Map) {
    return false;
  }
  if (message['keymap'] != 'macos' || message['type'] != 'keydown') {
    return false;
  }
  final Object? keyCode = message['keyCode'];
  final Object? modifiers = message['modifiers'];
  if (keyCode is! int || modifiers is! int) {
    return false;
  }
  final int flag = _modifierFlagForKeyCode(keyCode);
  return flag != 0 && (modifiers & flag) == 0;
}
