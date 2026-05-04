import '../../domain/repositories/expense_repository.dart';

/// Heuristischer Klassifikator: aus den Namen der OCR-erkannten
/// Bon-Positionen wird die wahrscheinlichste Kategorie abgeleitet.
///
/// Vorgehen:
///   * Lookup-Tabelle mit Substring-Patterns -> Kategorie-Slug.
///     Slugs sind die LOWERCASE-Namen der Default-Kategorien
///     (`lebensmittel`, `drogerie`, `restaurant`, `tanken`, ...).
///   * Pro Item zaehlen wir Treffer pro Slug.
///   * Sieger = Slug mit meisten Treffern. Bei Gleichstand gewinnt
///     der zuerst gefundene.
///   * Kein einziger Treffer -> null (Caller faellt auf seine
///     bisherige Default-Auswahl zurueck).
///
/// Bewusst KEINE harte Verbindung zur Kategorien-Tabelle: dieser
/// Service liefert nur einen Slug-Hinweis, der Caller mappt das
/// auf eine konkrete Kategorie-ID. So bleibt der Classifier reiner
/// Domain-Code, ohne DB-Abhaengigkeit, und gut testbar.
class CategoryClassifier {
  const CategoryClassifier();

  /// Patterns sind alles UPPERCASE, weil wir gegen `.toUpperCase()`
  /// matchen. Reihenfolge spielt keine Rolle - wir zaehlen nur
  /// Treffer.
  static const Map<String, List<String>> _patterns = <String, List<String>>{
    'lebensmittel': <String>[
      // Brot/Backwaren
      'BROT', 'BROETCHEN', 'BRÖTCHEN', 'TOAST', 'KNAECKE', 'BAGUETTE',
      'CROISSANT', 'BREZEL', 'KUCHEN', 'TORTE', 'KEKS',
      // Milchprodukte
      'MILCH', 'BUTTER', 'JOGHURT', 'KAESE', 'KÄSE', 'GOUDA', 'QUARK',
      'SAHNE', 'SKYR', 'KEFIR', 'MOZZARELLA', 'GRANA', 'PARMESAN',
      'CREME FRAICHE', 'FRISCHKAESE', 'FRISCHKÄSE',
      // Obst/Gemuese
      'TOMATE', 'GURKE', 'KAROTTE', 'KAROTTINI', 'PAPRIKA', 'SALAT',
      'APFEL', 'BIRNE', 'BANANE', 'ORANGE', 'KARTOFFEL', 'ZWIEBEL',
      'LAUCH', 'PORREE', 'KOHL', 'ROTKOHL', 'WIRSING', 'BROKKOLI',
      'BLUMENKOHL', 'AVOCADO', 'PILZ', 'CHAMPIGNON', 'OBST', 'GEMUESE',
      'GEMÜSE', 'PAKCHOI', 'SPROSSEN', 'HEIDELBEE', 'BEERE', 'TRAUBE',
      // Fleisch/Wurst/Fisch
      'FLEISCH', 'WURST', 'SCHINKEN', 'SALAMI', 'GULASCH', 'STEAK',
      'HACK', 'HAEHNCHEN', 'HÄHNCHEN', 'HUHN', 'PUTE', 'RIND',
      'SCHWEIN', 'LACHS', 'FORELLE', 'THUNFISCH', 'FISCH',
      // Vegan/Veggie
      'TOFU', 'SEITAN', 'VEG.', 'VEGAN', 'PLANTED', 'WIENER',
      // Trockenware
      'REIS', 'NUDEL', 'PASTA', 'PENNE', 'TAGLIATELLE', 'SPAGHETTI',
      'TORTI', 'FARFALLE', 'COLLEZ', 'MEHL', 'ZUCKER', 'SALZ', 'OEL',
      'ÖL', 'ESSIG', 'SENF', 'KETCHUP', 'MAYO', 'PESTO', 'TOMAT',
      'BOHNEN', 'LINSEN', 'KICHER', 'CHILI', 'OREGANO', 'BASILIK',
      'GEWUERZ', 'GEWÜRZ',
      // Eier
      'EIER', 'EI ', 'BIO EIER',
      // Konserven/Tiefkuehl
      'KONSERVE', 'TK', 'TIEFKUEHL', 'TIEFKÜHL', 'DOSE',
      // Getraenke (Lebensmittel-Kategorie passt am ehesten)
      'WASSER', 'SAFT', 'COLA', 'LIMO', 'EISTEE', 'KAFFEE', 'TEE',
      'GRUENTEE', 'GRÜNTEE', 'MATCHA', 'MINERALWASSER', 'VOLVIC',
      'SPRUDEL', 'APFELSCHORLE', 'BIER', 'WEIN', 'SEKT',
      // Snacks/Suess
      'CHIPS', 'FLIPS', 'SCHOKOLADE', 'NUSS', 'MANDEL', 'CASHEW',
      'MUESLI', 'MÜSLI', 'CEREAL', 'HAFER', 'CORNFLAKES', 'POPCORN',
      'BONBON', 'GUMMI',
      // Sonstiges Lebensmittel-Marker
      'PFAND', 'LEERGUT', 'EINWEGPFAND', 'MEHRWEGPFAND',
      'SUPPENGRUEN', 'SUPPENGRÜN',
      // Aufstrich
      'NUTELLA', 'MUS', 'MARMELADE', 'HONIG', 'MANDELMUS',
    ],
    'drogerie': <String>[
      'ZAHNPASTA', 'ELMEX', 'COLGATE', 'SENSODYNE', 'AJONA',
      'ZAHNBUERSTE', 'ZAHNBÜRSTE', 'ZAHNSEIDE',
      'SHAMPOO', 'SPUELUNG', 'SPÜLUNG', 'CONDITIONER',
      'DUSCHGEL', 'SEIFE', 'DEO', 'DEOSPRAY', 'PARFUEM', 'PARFÜM',
      'CREME', 'BODYLOTION', 'LOTION', 'HANDCREME',
      'WINDEL', 'PAMPERS', 'BABYNAHRUNG',
      'TOILETTENPAPIER', 'TOILETTEN', 'KLOPAPIER', 'TASCHENTUCH',
      'TAMPONS', 'BINDEN', 'HYGIENE',
      'WASCHMITTEL', 'WEICHSPUELER', 'WEICHSPÜLER', 'PUTZMITTEL',
      'SPUELI', 'SPÜLI', 'GESCHIRRSPUEL',
      'MUELLBEUTEL', 'MUELLBTL', 'MÜLLBEUTEL', 'OEKO',
      'RASIERER', 'KLINGEN', 'GILLETTE', 'NIVEA',
      'TABLETTE', 'VITAMIN', 'ASPIRIN', 'IBUPROFEN',
    ],
    'restaurant': <String>[
      'ZU GO', 'TO GO', 'KAFFEE TO GO', 'ESPRESSO', 'CAPPUCCINO',
      'LATTE', 'POMMES', 'BURGER', 'DOENER', 'DÖNER', 'KEBAB',
      'PIZZERIA', 'TRINKGELD',
    ],
    'tanken': <String>[
      'BENZIN', 'DIESEL', 'SUPER', 'E10', 'E5', 'PREMIUM',
      'KRAFTSTOFF', 'OEL ', 'AUTOWAESCHE', 'AUTOWÄSCHE',
    ],
    'wohnen': <String>[
      'IKEA', 'BAUMARKT', 'HORNBACH', 'OBI', 'TOOM',
      'SCHRAUBE', 'NAGEL', 'WERKZEUG', 'FARBE',
      'GARDINE', 'TEPPICH', 'KISSEN', 'BETTWAESCHE', 'BETTWÄSCHE',
    ],
    'kleidung': <String>[
      'HEMD', 'HOSE', 'JEANS', 'PULLOVER', 'SHIRT', 'T-SHIRT',
      'JACKE', 'MANTEL', 'SCHUHE', 'SOCKEN', 'STRUMPF',
      'UNTERWAESCHE', 'UNTERWÄSCHE',
    ],
    'freizeit': <String>[
      'KINO', 'TICKET', 'SPIEL', 'BUCH', 'ROMAN', 'ZEITSCHRIFT',
      'BRETTSPIEL', 'PUZZLE', 'KONSOLE', 'GAME',
    ],
  };

  /// Liefert den Kategorie-Slug, der am besten zu den Items passt,
  /// oder `null` wenn kein Item irgendein Pattern getroffen hat.
  String? suggestSlug(List<ExpenseItemDraft> items) {
    if (items.isEmpty) return null;
    final votes = <String, int>{};
    for (final item in items) {
      final upper = item.name.toUpperCase();
      // Pro Item maximal EINEN Slug zaehlen (das erste Match), damit
      // nicht ein einzelner Item-Name mit mehreren Patterns das
      // Ranking dominiert.
      for (final entry in _patterns.entries) {
        if (entry.value.any(upper.contains)) {
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
