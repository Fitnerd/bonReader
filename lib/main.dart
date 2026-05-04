import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // dargon2_flutter braucht eine explizite Plugin-Registrierung. Ohne
  // diesen Aufruf faellt DArgon2.hashPasswordString auf den No-Op-Stub
  // EmptyDArgon2Flutter zurueck und das Passwort wird nie gehasht.
  DArgon2Flutter.init();

  // Sensible Daten duerfen nicht in Screenshots / App-Switcher landen.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const ProviderScope(
      child: BonBudgetApp(),
    ),
  );
}
