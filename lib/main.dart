import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sensible Daten dürfen nicht in Screenshots / App-Switcher landen.
  // (Wird in Schritt 3 erweitert: FLAG_SECURE auf Auth-relevanten Screens.)
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const ProviderScope(
      child: BonBudgetApp(),
    ),
  );
}
