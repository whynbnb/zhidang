import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_navigator.dart';
import 'l10n/app_strings.dart';
import 'screens/main_shell.dart';
import 'services/app_icon_service.dart';
import 'services/category_store.dart';
import 'services/comparison_store.dart';
import 'services/keyboard_event_guard.dart';
import 'services/quick_calc_store.dart';
import 'services/supplier_store.dart';
import 'services/unit_store.dart';
import 'settings/app_settings.dart';
import 'utils/layout.dart';
import 'widgets/macos_menu_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await Future.wait([
    SupplierStore.instance.load(),
    CategoryStore.instance.load(),
    UnitStore.instance.load(locale: AppSettings.instance.locale),
    ComparisonStore.instance.load(),
    QuickCalcStore.instance.load(),
    AppIconService.instance.load(),
  ]);
  runApp(const ZhidangApp());

  // ServicesBinding registers its raw key handler asynchronously during
  // startup. Wait for the first frame so this guard is the final handler.
  await WidgetsBinding.instance.endOfFrame;
  installKeyboardEventGuard();
}

class ZhidangApp extends StatefulWidget {
  const ZhidangApp({super.key});

  @override
  State<ZhidangApp> createState() => _ZhidangAppState();
}

class _ZhidangAppState extends State<ZhidangApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-resolve strings when the OS language changes in "system" mode.
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (AppSettings.instance.localeMode == LocaleMode.system) {
      setState(() {});
    }
  }

  /// Some Android ROMs finish restoring a freeform window without delivering
  /// a fresh MediaQuery to every page. Rebuild once now and once after the
  /// frame so responsive breakpoints settle on the restored window size.
  @override
  void didChangeMetrics() {
    _refreshWindow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWindow();
    }
  }

  void _refreshWindow() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        final seed = settings.seedColor;
        final light = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        );
        final dark = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        );

        ThemeData buildTheme(ColorScheme scheme) {
          return ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: false),
            inputDecorationTheme: const InputDecorationTheme(filled: true),
            cardTheme: const CardThemeData(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
            ),
          );
        }

        return MaterialApp(
          navigatorKey: AppNavigator.key,
          title: AppStrings(settings.locale).appName,
          debugShowCheckedModeBanner: false,
          locale: settings.materialLocale,
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          themeMode: settings.themeMode,
          theme: buildTheme(light),
          darkTheme: buildTheme(dark),
          builder: (context, child) {
            final media = sanitizeAndroidWindowInsets(MediaQuery.of(context));
            return MediaQuery(
              data: media,
              child: AppStrings.provide(
                locale: settings.locale,
                child: MacosMenuBar(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          home: const MainShell(),
        );
      },
    );
  }
}
