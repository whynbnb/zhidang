import 'package:flutter/material.dart';

import 'app/app_navigator.dart';
import 'l10n/app_strings.dart';
import 'screens/main_shell.dart';
import 'services/app_icon_service.dart';
import 'services/comparison_store.dart';
import 'services/supplier_store.dart';
import 'services/unit_store.dart';
import 'settings/app_settings.dart';
import 'widgets/macos_menu_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await Future.wait([
    SupplierStore.instance.load(),
    UnitStore.instance.load(locale: AppSettings.instance.locale),
    ComparisonStore.instance.load(),
    AppIconService.instance.load(),
  ]);
  runApp(const ZhidangApp());
}

class ZhidangApp extends StatelessWidget {
  const ZhidangApp({super.key});

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
          locale: settings.locale,
          themeMode: settings.themeMode,
          theme: buildTheme(light),
          darkTheme: buildTheme(dark),
          builder: (context, child) {
            return AppStrings.provide(
              locale: settings.locale,
              child: MacosMenuBar(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const MainShell(),
        );
      },
    );
  }
}
