import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the compare feature is exposed in the main UI.
enum CompareNavMode {
  /// Bottom tab bar (current desktop/default style).
  bottomNav,

  /// Header icon left of settings (Android default).
  headerIcon,

  /// No entry points; compare feature hidden.
  disabled;

  static CompareNavMode fromJson(Object? raw) {
    switch (raw?.toString()) {
      case 'headerIcon':
        return CompareNavMode.headerIcon;
      case 'disabled':
        return CompareNavMode.disabled;
      case 'bottomNav':
        return CompareNavMode.bottomNav;
      default:
        return defaultForPlatform();
    }
  }

  String toJson() => name;

  static CompareNavMode defaultForPlatform() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return CompareNavMode.headerIcon;
    }
    return CompareNavMode.bottomNav;
  }
}

class ThemeColorOption {
  const ThemeColorOption({
    required this.id,
    required this.color,
    required this.labelZh,
    required this.labelEn,
  });

  final String id;
  final Color color;
  final String labelZh;
  final String labelEn;

  String label(bool isZh) => isZh ? labelZh : labelEn;
}

const themeColorOptions = <ThemeColorOption>[
  ThemeColorOption(
    id: 'teal',
    color: Color(0xFF0F766E),
    labelZh: '青绿',
    labelEn: 'Teal',
  ),
  ThemeColorOption(
    id: 'blue',
    color: Color(0xFF2563EB),
    labelZh: '蓝色',
    labelEn: 'Blue',
  ),
  ThemeColorOption(
    id: 'indigo',
    color: Color(0xFF4F46E5),
    labelZh: '靛蓝',
    labelEn: 'Indigo',
  ),
  ThemeColorOption(
    id: 'purple',
    color: Color(0xFF7C3AED),
    labelZh: '紫色',
    labelEn: 'Purple',
  ),
  ThemeColorOption(
    id: 'pink',
    color: Color(0xFFDB2777),
    labelZh: '粉色',
    labelEn: 'Pink',
  ),
  ThemeColorOption(
    id: 'red',
    color: Color(0xFFDC2626),
    labelZh: '红色',
    labelEn: 'Red',
  ),
  ThemeColorOption(
    id: 'orange',
    color: Color(0xFFEA580C),
    labelZh: '橙色',
    labelEn: 'Orange',
  ),
  ThemeColorOption(
    id: 'amber',
    color: Color(0xFFD97706),
    labelZh: '琥珀',
    labelEn: 'Amber',
  ),
  ThemeColorOption(
    id: 'green',
    color: Color(0xFF16A34A),
    labelZh: '绿色',
    labelEn: 'Green',
  ),
  ThemeColorOption(
    id: 'cyan',
    color: Color(0xFF0891B2),
    labelZh: '青色',
    labelEn: 'Cyan',
  ),
];

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const _localeKey = 'settings_locale';
  static const _themeModeKey = 'settings_theme_mode';
  static const _colorKey = 'settings_theme_color';
  static const _compareNavKey = 'settings_compare_nav_mode';

  Locale _locale = const Locale('zh');
  ThemeMode _themeMode = ThemeMode.system;
  String _colorId = 'teal';
  CompareNavMode _compareNavMode = CompareNavMode.defaultForPlatform();
  bool _ready = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  String get colorId => _colorId;
  CompareNavMode get compareNavMode => _compareNavMode;
  bool get ready => _ready;
  bool get isZh => _locale.languageCode == 'zh';

  ThemeColorOption get colorOption => themeColorOptions.firstWhere(
        (e) => e.id == _colorId,
        orElse: () => themeColorOptions.first,
      );

  Color get seedColor => colorOption.color;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    final themeModeName = prefs.getString(_themeModeKey);
    final colorId = prefs.getString(_colorKey);
    final compareNavRaw = prefs.getString(_compareNavKey);

    if (localeCode == 'en' || localeCode == 'zh') {
      _locale = Locale(localeCode!);
    }
    if (themeModeName != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeModeName,
        orElse: () => ThemeMode.system,
      );
    }
    if (colorId != null && themeColorOptions.any((e) => e.id == colorId)) {
      _colorId = colorId;
    }
    if (compareNavRaw != null) {
      _compareNavMode = CompareNavMode.fromJson(compareNavRaw);
    } else {
      _compareNavMode = CompareNavMode.defaultForPlatform();
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setColorId(String id) async {
    if (_colorId == id) return;
    if (!themeColorOptions.any((e) => e.id == id)) return;
    _colorId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, id);
  }

  Future<void> setCompareNavMode(CompareNavMode mode) async {
    if (_compareNavMode == mode) return;
    _compareNavMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_compareNavKey, mode.toJson());
  }
}
