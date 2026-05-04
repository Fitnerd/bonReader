import '../../domain/repositories/expense_repository.dart';

/// Heuristischer Klassifikator: aus den Namen der OCR-erkannten
/// Bon-Positionen wird die wahrscheinlichste Kategorie abgeleitet.
///
/// Vorgehen:
///   * Lookup-Tabelle mit Patterns -> Kategorie-Slug.
///     Slugs sind die LOWERCASE-Namen der Default-Kategorien
///     (`lebensmittel`, `drogerie`, `restaurant`, `tanken`, ...).
///   * Patterns werden als Wort-Boundary-RegExp gematcht
///     (`\bPATTERN\b`, case-insensitive). Damit triggert z.B.
///     `OEL` nicht in `VOELLIG`, `TK` nicht in `STAATLICH`.
///   * Pro Item maximal EIN Slug-Treffer (das erste Match).
///   * Sieger = Slug mit den meisten Treffern. Bei Gleichstand
///     gewinnt der zuerst gefundene.
///   * Kein einziger Treffer -> null (Caller faellt auf seine
///     bisherige Default-Auswahl zurueck).
///
/// Bewusst KEINE harte Verbindung zur Kategorien-Tabelle: dieser
/// Service liefert nur einen Slug-Hinweis, der Caller mappt das
/// auf eine konkrete Kategorie-ID. So bleibt der Classifier reiner
/// Domain-Code, ohne DB-Abhaengigkeit, und gut testbar.
class CategoryClassifier {
  const CategoryClassifier();

  /// Rohe Pattern-Strings pro Slug. Werden in [_compiledPatterns]
  /// einmalig in RegExp mit `\b...\b` und case-insensitive gemappt.
  static const Map<String, List<String>> _rawPatterns =
      <String, List<String>>{
    'lebensmittel': <String>[
      // Brot/Backwaren
      'BROT', 'BROETCHEN', 'BROETCHEN', 'TOAST', 'KNAECKE', 'BAGUETTE',
      'CROISSANT', 'BREZEL', 'KUCHEN', 'TORTE', 'KEKS',
      // Milchprodukte
      'MILCH', 'BUTTER', 'JOGHURT', 'KAESE', 'GOUDA', 'QUARK',
      'SAHNE', 'SKYR', 'KEFIR', 'MOZZARELLA', 'GRANA', 'PARMESAN',
      'FRISCHKAESE',
      // Obst/Gemuese
      'TOMATE', 'TOMATEN', 'GURKE', 'KAROTTE', 'KAROTTINI', 'PAPRIKA',
      'SALAT', 'APFEL', 'BIRNE', 'BANANE', 'ORANGE', 'KARTOFFEL',
      'ZWIEBEL', 'LAUCH', 'PORREE', 'KOHL', 'ROTKOHL', 'WIRSING',
      'BROKKOLI', 'BLUMENKOHL', 'AVOCADO', 'PILZ', 'CHAMPIGNON',
      'OBST', 'GEMUESE', 'PAKCHOI', 'SPROSSEN', 'HEIDELBEE', 'BEERE',
      'TRAUBE',
      // Fleisch/Wurst/Fisch
      'FLEISCH', 'WURST', 'SCHINKEN', 'SALAMI', 'GULASCH', 'STEAK',
      'HACK', 'HAEHNCHEN', 'HUHN', 'PUTE', 'RIND', 'SCHWEIN', 'LACHS',
      'FORELLE', 'THUNFISCH', 'FISCH',
      // Vegan/Veggie
      'TOFU', 'SEITAN', 'VEG', 'VEGAN', 'PLANTED', 'WIENER',
      // Trockenware
      'REIS', 'NUDEL', 'PASTA', 'PENNE', 'TAGLIATELLE', 'SPAGHETTI',
      'TORTI', 'FARFALLE', 'COLLEZ', 'MEHL', 'ZUCKER', 'SALZ',
      'OLIVENOEL', 'RAPSOEL', 'SPEISEOEL', 'SONNENBLUMENOEL',
      'ESSIG', 'SENF', 'KETCHUP', 'MAYO', 'PESTO', 'TOMAT',
      'BOHNEN', 'LINSEN', 'KICHER', 'CHILI', 'OREGANO', 'BASILIK',
      'GEWUERZ',
      // Eier
      'EIER', 'BIO EIER',
      // Konserven/Tiefkuehl - 'TK' nur als ganzes Wort, dank \b\b sicher
      'KONSERVE', 'TK', 'TIEFKUEHL', 'DOSE',
      // Getraenke
      'WASSER', 'SAFT', 'COLA', 'LIMO', 'EISTEE', 'KAFFEE', 'TEE',
      'GRUENTEE', 'MATCHA', 'MINERALWASSER', 'VOLVIC', 'SPRUDEL',
      'APFELSCHORLE', 'BIER', 'WEIN', 'SEKT',
      // Snacks/Suess
      'CHIPS', 'FLIPS', 'SCHOKOLADE', 'NUSS', 'MANDEL', 'CASHEW',
      'MUESLI', 'CEREAL', 'HAFER', 'CORNFLAKES', 'POPCORN',
      'BONBON', 'GUMMI',
      // Pfand & Gemuese-Kuerzel
      'PFAND', 'LEERGUT', 'EINWEGPFAND', 'MEHRWEGPFAND',
      'SUPPENGRUEN',
      // Aufstrich
      'NUTELLA', 'MARMELADE', 'HONIG', 'MANDELMUS', 'NUSSMUS',
    ],
    'drogerie': <String>[
      'ZAHNPASTA', 'ELMEX', 'COLGATE', 'SENSODYNE', 'AJONA',
      'ZAHNBUERSTE', 'ZAHNSEIDE',
      'SHAMPOO', 'SPUELUNG', 'CONDITIONER',
      'DUSCHGEL', 'SEIFE', 'DEO', 'DEOSPRAY', 'PARFUEM',
      'CREME', 'BODYLOTION', 'LOTION', 'HANDCREME',
      'WINDEL', 'PAMPERS', 'BABYNAHRUNG',
      'TOILETTENPAPIER', 'KLOPAPIER', 'TASCHENTUCH',
      'TAMPONS', 'BINDEN', 'HYGIENE',
      'WASCHMITTEL', 'WEICHSPUELER', 'PUTZMITTEL',
      'SPUELI', 'GESCHIRRSPUEL',
      'MUELLBEUTEL', 'MUELLBTL', 'OEKO',
      'RASIERER', 'KLINGEN', 'GILLETTE', 'NIVEA',
      'TABLETTE', 'VITAMIN', 'ASPIRIN', 'IBUPROFEN',
    ],
    'restaurant': <String>[
      'TO GO', 'ESPRESSO', 'CAPPUCCINO', 'LATTE', 'POMMES', 'BURGER',
      'DOENER', 'KEBAB', 'PIZZERIA', 'TRINKGELD',
    ],
    'tanken': <String>[
      'BENZIN', 'DIESEL', 'SUPER', 'E10', 'E5', 'PREMIUM',
      'KRAFTSTOFF', 'AUTOWAESCHE',
    ],
    'wohnen': <String>[
      'IKEA', 'BAUMARKT', 'HORNBACH', 'OBI', 'TOOM',
      'SCHRAUBE', 'NAGEL', 'WERKZEUG', 'FARBE',
      'GARDINE', 'TEPPICH', 'KISSEN', 'BETTWAESCHE',
    ],
    'kleidung': <String>[
      'HEMD', 'HOSE', 'JEANS', 'PULLOVER', 'SHIRT', 'T-SHIRT',
      'JACKE', 'MANTEL', 'SCHUHE', 'SOCKEN', 'STRUMPF',
      'UNTERWAESCHE',
    ],
    'freizeit': <String>[
      'KINO', 'TICKET', 'SPIEL', 'BUCH', 'ROMAN', 'ZEITSCHRIFT',
      'BRETTSPIEL', 'PUZZLE', 'KONSOLE', 'GAME',
    ],
  };

  /// Compile-Once Cache der RegExps mit Wort-Boundary-Matching.
  static final Map<String, List<RegExp>> _patterns = _compile();

  static Map<String, List<RegExp>> _compile() {
    final out = <String, List<RegExp>>{};
    for (final e in _rawPatterns.entries) {
      out[e.key] = e.value
          .map((p) => RegExp(
                r'\b' + RegExp.escape(p) + r'\b',
                caseSensitive: false,
              ))
          .toList(growable: false);
    }
    return out;
  }

  /// Liefert den Kategorie-Slug, der am besten zu den Items passt,
  /// oder `null` wenn kein Item irgendein Pattern getroffen hat.
  String? suggestSlug(List<ExpenseItemDraft> items) {
    if (items.isEmpty) return null;
    final votes = <String, int>{};
    for (final item in items) {
      final name = item.name;
      // Pro Item maximal EINEN Slug zaehlen (das erste Match), damit
      // nicht ein einzelner Item-Name mit mehreren Patterns das
      // Ranking dominiert.
      for (final entry in _patterns.entries) {
        if (entry.value.any((re) => re.hasMatch(name))) {
          votes[entry.key] = (votes[entry.key] ?? 0) + 1;
          break;
        }
      }
    }
    if (votes.isEmpty) return null;
    String? winner;
    var max = 0;
    for (final e in votes.entries) {
      if (e.value > max) {
        max = e.value;
        winner = e.key;
      }
    }
    return winner;
  }
}
