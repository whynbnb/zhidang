import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language preference: follow the system or pin a language.
enum LocaleMode {
  system,
  zh,
  en;

  static LocaleMode fromJson(Object? raw) {
    switch (raw?.toString()) {
      case 'zh':
        return LocaleMode.zh;
      case 'en':
        return LocaleMode.en;
      case 'system':
        return LocaleMode.system;
      default:
        // Older installs stored nothing or an unknown value; keep Chinese.
        return LocaleMode.zh;
    }
  }

  String toJson() => name;

  Locale? get fixedLocale => switch (this) {
        LocaleMode.system => null,
        LocaleMode.zh => const Locale('zh'),
        LocaleMode.en => const Locale('en'),
      };
}

/// How the compare feature is exposed in the main UI.
enum CompareNavMode {
  /// Products / Compare on the navigation bar (bottom or side).
  bottomNav,

  /// Header icon left of settings (when settings is also header).
  headerIcon,

  /// Only reachable from the Data Center quick tools.
  dataCenter,

  /// No compare entry points.
  disabled;

  static CompareNavMode fromJson(Object? raw) {
    switch (raw?.toString()) {
      case 'headerIcon':
        return CompareNavMode.headerIcon;
      case 'dataCenter':
        return CompareNavMode.dataCenter;
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

  bool get isOnNav => this == CompareNavMode.bottomNav;
  bool get isOnHeader => this == CompareNavMode.headerIcon;
}

/// Where the settings entry lives.
enum SettingsEntryMode {
  /// Settings tab on the navigation bar (desktop default).
  navBar,

  /// Settings icon in the page header (mobile default).
  headerIcon;

  static SettingsEntryMode fromJson(Object? raw) {
    switch (raw?.toString()) {
      case 'navBar':
        return SettingsEntryMode.navBar;
      case 'headerIcon':
        return SettingsEntryMode.headerIcon;
      default:
        return defaultForPlatform();
    }
  }

  String toJson() => name;

  static SettingsEntryMode defaultForPlatform() {
    if (LayoutCapability.isDesktopPlatform) {
      return SettingsEntryMode.navBar;
    }
    return SettingsEntryMode.headerIcon;
  }

  bool get isOnNav => this == SettingsEntryMode.navBar;
  bool get isOnHeader => this == SettingsEntryMode.headerIcon;
}

/// Where the data center entry lives.
enum DataCenterNavMode {
  /// Data tab on the navigation bar (bottom or side).
  bottomNav,

  /// Data center icon in the page header.
  headerIcon;

  static DataCenterNavMode fromJson(Object? raw) {
    switch (raw?.toString()) {
      case 'headerIcon':
        return DataCenterNavMode.headerIcon;
      case 'bottomNav':
        return DataCenterNavMode.bottomNav;
      default:
        return defaultForPlatform();
    }
  }

  String toJson() => name;

  static DataCenterNavMode defaultForPlatform() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return DataCenterNavMode.headerIcon;
    }
    return DataCenterNavMode.bottomNav;
  }

  bool get isOnNav => this == DataCenterNavMode.bottomNav;
  bool get isOnHeader => this == DataCenterNavMode.headerIcon;
}

/// Destinations that can appear on the shell navigation bar.
enum ShellNavDestination {
  products,
  dataCenter,
  compare,
  settings,
}

/// Desktop / large-window helpers for sidebar navigation.
class LayoutCapability {
  LayoutCapability._();

  static bool get isDesktopPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Desktop windows switch to a rail at this width.
  static const double sidebarBreakpoint = 840;

  /// Responsive rule:
  /// - desktop / web: rail when the window is wide enough;
  /// - tablets: rail in landscape only;
  /// - phones: always bottom bar.
  static bool useSidebar(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (isDesktopPlatform) {
      return size.width >= sidebarBreakpoint;
    }
    final isTablet = size.shortestSide >= 600;
    final isLandscape = size.width > size.height;
    return isTablet && isLandscape;
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
  static const _settingsEntryKey = 'settings_entry_mode';
  static const _dataCenterNavKey = 'settings_data_center_nav_mode';
  static const _compactModeKey = 'settings_compact_mode';
  static const _simpleNavModeKey = 'settings_simple_nav_mode';

  LocaleMode _localeMode = LocaleMode.zh;
  ThemeMode _themeMode = ThemeMode.system;
  String _colorId = 'teal';
  CompareNavMode _compareNavMode = CompareNavMode.defaultForPlatform();
  SettingsEntryMode _settingsEntryMode = SettingsEntryMode.defaultForPlatform();
  DataCenterNavMode _dataCenterNavMode =
      DataCenterNavMode.defaultForPlatform();
  bool _compactMode = false;
  bool _simpleNavMode = false;
  bool _ready = false;

  LocaleMode get localeMode => _localeMode;

  /// Resolved app locale; follows the system when [localeMode] is system.
  Locale get locale {
    final fixed = _localeMode.fixedLocale;
    if (fixed != null) return fixed;
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    return system.languageCode == 'en'
        ? const Locale('en')
        : const Locale('zh');
  }

  /// Null = let Flutter follow the system locale.
  Locale? get materialLocale => _localeMode.fixedLocale;

  ThemeMode get themeMode => _themeMode;
  String get colorId => _colorId;
  CompareNavMode get compareNavMode => _compareNavMode;
  SettingsEntryMode get settingsEntryMode => _settingsEntryMode;
  DataCenterNavMode get dataCenterNavMode => _dataCenterNavMode;
  /// Dense product rows instead of large cards.
  bool get compactMode => _compactMode;

  /// One-switch layout: header icons for Data Center/Settings and Compare in
  /// Data Center. Individual entry options are locked while enabled.
  bool get simpleNavMode => _simpleNavMode;
  bool get ready => _ready;
  bool get isZh => locale.languageCode == 'zh';

  /// Ordered destinations for the shell navigation bar (empty if hidden).
  List<ShellNavDestination> get navDestinations {
    final dataOnNav = _dataCenterNavMode.isOnNav;
    final compareOnNav = _compareNavMode.isOnNav;
    final settingsOnNav = _settingsEntryMode.isOnNav;
    if (!dataOnNav && !compareOnNav && !settingsOnNav) return const [];
    return [
      ShellNavDestination.products,
      if (dataOnNav) ShellNavDestination.dataCenter,
      if (compareOnNav) ShellNavDestination.compare,
      if (settingsOnNav) ShellNavDestination.settings,
    ];
  }

  bool get showsNavigationBar => navDestinations.isNotEmpty;

  bool get showCompareHeaderIcon => _compareNavMode.isOnHeader;
  bool get showSettingsHeaderIcon => _settingsEntryMode.isOnHeader;
  bool get showDataCenterHeaderIcon => _dataCenterNavMode.isOnHeader;

  /// Whether shell should render a side rail instead of bottom bar.
  bool useSidebarNav(BuildContext context) {
    if (!showsNavigationBar) return false;
    return LayoutCapability.useSidebar(context);
  }

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
    final settingsEntryRaw = prefs.getString(_settingsEntryKey);
    final dataCenterNavRaw = prefs.getString(_dataCenterNavKey);
    final compactRaw = prefs.getBool(_compactModeKey);
    final simpleNavRaw = prefs.getBool(_simpleNavModeKey);

    _localeMode = LocaleMode.fromJson(localeCode);
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
    if (settingsEntryRaw != null) {
      _settingsEntryMode = SettingsEntryMode.fromJson(settingsEntryRaw);
    } else {
      _settingsEntryMode = SettingsEntryMode.defaultForPlatform();
    }
    if (dataCenterNavRaw != null) {
      _dataCenterNavMode = DataCenterNavMode.fromJson(dataCenterNavRaw);
    } else {
      _dataCenterNavMode = DataCenterNavMode.defaultForPlatform();
    }
    _simpleNavMode = simpleNavRaw ?? false;
    if (_simpleNavMode) {
      _applySimpleNavPreset();
    }
    _compactMode = compactRaw ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocaleMode(LocaleMode mode) async {
    if (_localeMode == mode) return;
    _localeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, mode.toJson());
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
    if (_simpleNavMode || _compareNavMode == mode) return;
    _compareNavMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_compareNavKey, mode.toJson());
  }

  Future<void> setSettingsEntryMode(SettingsEntryMode mode) async {
    if (_simpleNavMode || _settingsEntryMode == mode) return;
    _settingsEntryMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsEntryKey, mode.toJson());
  }

  Future<void> setDataCenterNavMode(DataCenterNavMode mode) async {
    if (_simpleNavMode || _dataCenterNavMode == mode) return;
    _dataCenterNavMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataCenterNavKey, mode.toJson());
  }

  Future<void> setCompactMode(bool enabled) async {
    if (_compactMode == enabled) return;
    _compactMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactModeKey, enabled);
  }

  Future<void> setSimpleNavMode(bool enabled) async {
    if (_simpleNavMode == enabled) return;
    _simpleNavMode = enabled;
    if (enabled) _applySimpleNavPreset();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simpleNavModeKey, enabled);
    if (enabled) {
      await prefs.setString(_dataCenterNavKey, _dataCenterNavMode.toJson());
      await prefs.setString(_compareNavKey, _compareNavMode.toJson());
      await prefs.setString(_settingsEntryKey, _settingsEntryMode.toJson());
    }
  }

  void _applySimpleNavPreset() {
    _dataCenterNavMode = DataCenterNavMode.headerIcon;
    _compareNavMode = CompareNavMode.dataCenter;
    _settingsEntryMode = SettingsEntryMode.headerIcon;
  }
}
