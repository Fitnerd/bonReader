import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Layout ist auf Portrait optimiert; Hochkant fixieren.
  // (Der Schutz vor Screenshots / App-Switcher-Vorschau passiert in
  // MainActivity.kt via FLAG_SECURE, NICHT hier.)
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const ProviderScope(
      child: BonBudgetApp(),
    ),
  );
}
