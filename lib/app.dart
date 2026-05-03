import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Wurzel-Widget der App.
///
/// Theme, Router und Lokalisierung. Der Router wird einmalig beim
/// Aufbau erzeugt und mit dem Riverpod-`Ref` verdrahtet, damit er
/// auf Auth-Aenderungen reagieren kann.
class BonBudgetApp extends ConsumerStatefulWidget {
  const BonBudgetApp({super.key});

  @override
  ConsumerState<BonBudgetApp> createState() => _BonBudgetAppState();
}

class _BonBudgetAppState extends ConsumerState<BonBudgetApp> {
  late final GoRouter _router = buildAppRouter(ref);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ],
    );
  }
}
