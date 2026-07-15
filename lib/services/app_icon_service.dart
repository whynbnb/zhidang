import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppIconStyle {
  defaultIcon('default', null, 'assets/icons/icon_default.png'),
  classic('classic', 'classic', 'assets/icons/icon_classic.png');

  const AppIconStyle(this.id, this.platformName, this.previewAsset);

  final String id;
  /// Platform alternate icon name. null = primary/default.
  final String? platformName;
  final String previewAsset;

  static AppIconStyle fromId(String? id) {
    return AppIconStyle.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AppIconStyle.defaultIcon,
    );
  }
}

class AppIconService extends ChangeNotifier {
  AppIconService._();

  static final AppIconService instance = AppIconService._();

  static const _prefsKey = 'settings_app_icon';

  AppIconStyle _style = AppIconStyle.defaultIcon;
  bool _supported = false;
  bool _ready = false;

  AppIconStyle get style => _style;
  bool get supported => _supported;
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _style = AppIconStyle.fromId(prefs.getString(_prefsKey));

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        _supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
        if (_supported) {
          final current = await FlutterDynamicIconPlus.alternateIconName;
          if (current == null || current.isEmpty) {
            _style = AppIconStyle.defaultIcon;
          } else if (current == AppIconStyle.classic.platformName) {
            _style = AppIconStyle.classic;
          }
        }
      } catch (_) {
        _supported = false;
      }
    } else {
      _supported = false;
    }

    _ready = true;
    notifyListeners();
  }

  Future<bool> setStyle(AppIconStyle style) async {
    if (!_supported &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      // re-check
      try {
        _supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
      } catch (_) {
        _supported = false;
      }
    }

    if (!_supported) {
      // Still persist preference for UI; desktop/web cannot switch launcher icon.
      _style = style;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, style.id);
      return false;
    }

    try {
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: style.platformName,
      );
      _style = style;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, style.id);
      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
