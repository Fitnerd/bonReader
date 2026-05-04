import 'dart:io';

import 'package:bonbudget/data/datasources/database/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Integrationstest, der die SQLCipher-Verschluesselung verifiziert.
///
/// Pruefungen:
/// 1. DB mit Passphrase A wird angelegt und befuellt.
/// 2. Versuch, sie mit Passphrase B zu oeffnen → muss fehlschlagen.
/// 3. Mit Passphrase A geoeffnet → Daten lesbar.
/// 4. Roh-Bytes der DB-Datei enthalten KEINE Klartexte (Tabellen- oder
///    Inhaltsstrings).
///
/// Laeuft on-device, weil sqflite_sqlcipher nur dort funktioniert.
/// Auf Host (sqflite_common_ffi) gibt es keine Verschluesselung.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DB ist mit Passphrase A verschluesselt, Passphrase B faellt durch',
      (tester) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'sqlcipher_test_${DateTime.now().millisecondsSinceEpoch}.db');

    addTearDown(() async {
      final f = File(path);
      if (await f.exists()) await f.delete();
    });

    const passphraseA = 'super-secret-A-32-bytes-padded-1234';
    const passphraseB = 'wrong-passphrase-B-32-bytes-pad-5678';

    // 1) DB mit A anlegen + Daten reinschreiben.
    final dbA = await openDatabase(
      path,
      password: passphraseA,
      version: Migrations.latestVersion,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
    );
    await dbA.execute(
      "INSERT INTO categories(id,name,color_value,icon_code_point,is_default,is_hidden,created_at) "
      "VALUES('c1','TestKategorieMitMarkertext',0,0,0,0,0)",
    );
    await dbA.close();

    // 2) Mit Passphrase B oeffnen → muss werfen.
    var openedWithWrongPassphrase = false;
    try {
      final dbB = await openDatabase(path, password: passphraseB);
      // Manche Plattformen werfen erst beim ersten Query.
      await dbB.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      openedWithWrongPassphrase = true;
      await dbB.close();
    } on Object {
      // erwartet
    }
    expect(openedWithWrongPassphrase, isFalse,
        reason:
            'DB darf NICHT mit falscher Passphrase lesbar sein.');

    // 3) Mit A wieder oeffnen → Daten lesbar.
    final dbA2 = await openDatabase(path, password: passphraseA);
    final rows = await dbA2.query('categories');
    expect(rows, hasLength(1));
    expect(rows.first['name'], 'TestKategorieMitMarkertext');
    await dbA2.close();

    // 4) Roh-Bytes pruefen: kein Klartext-Marker.
    final raw = await File(path).readAsBytes();
    final asString = String.fromCharCodes(
        raw.where((b) => b >= 0x20 && b < 0x7f));
    expect(
      asString.contains('TestKategorieMitMarkertext'),
      isFalse,
      reason: 'Datenbankdatei darf keinen Klartext enthalten.',
    );
    expect(
      asString.contains('categories'),
      isFalse,
      reason:
          'Tabellennamen muessen verschluesselt sein, nicht im Klartext.',
    );
  });
}
