import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the compare feature is exposed in the main UI.
enum CompareNavMode {
  /// Products / Compare on the navigation bar (bottom or side).
  bottomNav,

  /// Header icon left of settings (when settings is also header).
  headerIcon,

  /// No compare entry points.
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

/// Destinations that can appear on the shell navigation bar.
enum ShellNavDestination {
  products,
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

  /// Tablet or larger by shortest side (Material guideline ~600).
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  /// Whether sidebar navigation can apply on this surface.
  static bool supportsSidebarSurface(BuildContext context) {
    if (isDesktopPlatform) return true;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    return isTabletOrLarger(context) && isLandscape;
  }

  /// Show the sidebar toggle in settings (desktop, or tablet).
  static bool showSidebarSetting(BuildContext context) {
    return isDesktopPlatform || isTabletOrLarger(context);
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
  static const _sidebarNavKey = 'settings_sidebar_nav';
  static const _compactModeKey = 'settings_compact_mode';

  Locale _locale = const Locale('zh');
  ThemeMode _themeMode = ThemeMode.system;
  String _colorId = 'teal';
  CompareNavMode _compareNavMode = CompareNavMode.defaultForPlatform();
  SettingsEntryMode _settingsEntryMode = SettingsEntryMode.defaultForPlatform();
  bool _sidebarNavEnabled = LayoutCapability.isDesktopPlatform;
  bool _compactMode = false;
  bool _ready = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  String get colorId => _colorId;
  CompareNavMode get compareNavMode => _compareNavMode;
  SettingsEntryMode get settingsEntryMode => _settingsEntryMode;
  /// Prefer sidebar over bottom bar when nav is visible (desktop / tablet landscape).
  bool get sidebarNavEnabled => _sidebarNavEnabled;
  /// Dense product rows instead of large cards.
  bool get compactMode => _compactMode;
  bool get ready => _ready;
  bool get isZh => _locale.languageCode == 'zh';

  /// Ordered destinations for the shell navigation bar (empty if hidden).
  List<ShellNavDestination> get navDestinations {
    final compareOnNav = _compareNavMode.isOnNav;
    final settingsOnNav = _settingsEntryMode.isOnNav;
    if (!compareOnNav && !settingsOnNav) return const [];
    return [
      ShellNavDestination.products,
      if (compareOnNav) ShellNavDestination.compare,
      if (settingsOnNav) ShellNavDestination.settings,
    ];
  }

  bool get showsNavigationBar => navDestinations.isNotEmpty;

  bool get showCompareHeaderIcon => _compareNavMode.isOnHeader;
  bool get showSettingsHeaderIcon => _settingsEntryMode.isOnHeader;

  /// Whether shell should render a side rail instead of bottom bar.
  bool useSidebarNav(BuildContext context) {
    if (!showsNavigationBar) return false;
    if (!_sidebarNavEnabled) return false;
    return LayoutCapability.supportsSidebarSurface(context);
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
    final sidebarRaw = prefs.getBool(_sidebarNavKey);
    final compactRaw = prefs.getBool(_compactModeKey);

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
    if (settingsEntryRaw != null) {
      _settingsEntryMode = SettingsEntryMode.fromJson(settingsEntryRaw);
    } else {
      _settingsEntryMode = SettingsEntryMode.defaultForPlatform();
    }
    _sidebarNavEnabled = sidebarRaw ?? LayoutCapability.isDesktopPlatform;
    _compactMode = compactRaw ?? false;
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

  Future<void> setSettingsEntryMode(SettingsEntryMode mode) async {
    if (_settingsEntryMode == mode) return;
    _settingsEntryMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsEntryKey, mode.toJson());
  }

  Future<void> setSidebarNavEnabled(bool enabled) async {
    if (_sidebarNavEnabled == enabled) return;
    _sidebarNavEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sidebarNavKey, enabled);
  }

  Future<void> setCompactMode(bool enabled) async {
    if (_compactMode == enabled) return;
    _compactMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactModeKey, enabled);
  }
}
