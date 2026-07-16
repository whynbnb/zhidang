import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppIconStyle {
  defaultIcon('default', 'default', 'assets/icons/icon_default.png'),
  classic('classic', 'classic', 'assets/icons/icon_classic.png');

  const AppIconStyle(this.id, this.platformName, this.previewAsset);

  final String id;
  /// Platform alternate icon name.
  /// Android: activity-alias suffix (default / classic).
  /// iOS: CFBundleAlternateIcons key; default uses primary via null mapping.
  final String platformName;
  final String previewAsset;

  static AppIconStyle fromId(String? id) {
    return AppIconStyle.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AppIconStyle.defaultIcon,
    );
  }

  /// iOS primary icon is restored with null; Android always uses an alias name.
  String? get iosIconName =>
      this == AppIconStyle.defaultIcon ? null : platformName;
}

class AppIconService extends ChangeNotifier {
  AppIconService._();

  static final AppIconService instance = AppIconService._();

  static const _prefsKey = 'settings_app_icon';
  static const _androidChannel = MethodChannel('com.zhidang.zhidang/app_icon');

  AppIconStyle _style = AppIconStyle.defaultIcon;
  bool _supported = false;
  bool _ready = false;

  AppIconStyle get style => _style;
  bool get supported => _supported;
  bool get ready => _ready;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _style = AppIconStyle.fromId(prefs.getString(_prefsKey));

    if (_isAndroid) {
      try {
        _supported =
            await _androidChannel.invokeMethod<bool>('supportsAlternateIcons') ??
                false;
        if (_supported) {
          final current =
              await _androidChannel.invokeMethod<String>('getAlternateIconName');
          _style = AppIconStyle.fromId(current);
        }
      } catch (_) {
        _supported = false;
      }
    } else if (_isIOS) {
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
    if (!_supported) {
      if (_isAndroid) {
        try {
          _supported = await _androidChannel
                  .invokeMethod<bool>('supportsAlternateIcons') ??
              false;
        } catch (_) {
          _supported = false;
        }
      } else if (_isIOS) {
        try {
          _supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
        } catch (_) {
          _supported = false;
        }
      }
    }

    if (!_supported) {
      _style = style;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, style.id);
      return false;
    }

    try {
      if (_isAndroid) {
        await _androidChannel.invokeMethod<bool>(
          'setAlternateIconName',
          {'iconName': style.platformName},
        );
      } else if (_isIOS) {
        await FlutterDynamicIconPlus.setAlternateIconName(
          iconName: style.iosIconName,
        );
      } else {
        return false;
      }
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
