// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'BonBudget';

  @override
  String get splashLoading => 'App wird geladen';

  @override
  String setupTitleWelcome(String appName) {
    return 'Willkommen bei $appName';
  }

  @override
  String get setupExplanation =>
      'Deine Daten werden lokal verschluesselt gespeichert. Zugriff bekommst du ueber Biometrie (Fingerabdruck / Gesicht) oder die Geraete-PIN.';

  @override
  String get setupNoRecoveryWarning =>
      'Wichtig: Es gibt keinen Cloud-Backup und kein Recovery. Bei Geraeteverlust sind alle Bons, Budgets und Kategorien unwiederbringlich weg.';

  @override
  String get setupNoBiometricsHint =>
      'Auf diesem Geraet ist keine Biometrie eingerichtet. Bitte zuerst in den System-Einstellungen einen Fingerabdruck oder Face-ID hinterlegen und die App neu starten.';

  @override
  String get setupButton => 'Mit Biometrie einrichten';

  @override
  String get unlockHint =>
      'Tippe auf \"Entsperren\", um deine Daten freizugeben.';

  @override
  String get unlockButton => 'Entsperren';

  @override
  String get resetAccountAction => 'Account zuruecksetzen';

  @override
  String get resetAccountConfirmTitle => 'Wirklich zuruecksetzen?';

  @override
  String get resetAccountConfirmBody =>
      'Alle Bons, Budgets und Kategorien werden unwiederbringlich geloescht. Danach steht die App wieder am Anfang. Diese Aktion kann nicht rueckgaengig gemacht werden.';

  @override
  String get resetAccountConfirmAction => 'Loeschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String legacyMigrationTitle(String appName) {
    return '$appName: Anmeldung umstellen';
  }

  @override
  String get legacyMigrationExplanation =>
      'Wir stellen die Anmeldung auf Biometrie um. Dafuer brauchen wir einmal dein altes App-Passwort.';

  @override
  String get legacyMigrationOldPasswordLabel => 'Bisheriges Passwort';

  @override
  String get legacyMigrationButton => 'Auf Biometrie umstellen';

  @override
  String get legacyMigrationEmptyError => 'Bitte eingeben.';

  @override
  String get biometricCancelled => 'Vorgang abgebrochen.';

  @override
  String biometricNotAvailable(String reason) {
    return 'Biometrie nicht verfuegbar: $reason';
  }

  @override
  String get biometricLockedOutPermanent =>
      'Biometrie ist dauerhaft gesperrt. Bitte ueber die Geraete-Einstellungen freischalten.';

  @override
  String get biometricLockedOutTemporary =>
      'Biometrie ist temporaer gesperrt. Bitte spaeter erneut versuchen.';

  @override
  String get biometricGenericFailure => 'Biometrie-Fehler.';

  @override
  String get setupFailedGeneric => 'Einrichtung fehlgeschlagen.';

  @override
  String get unlockFailedGeneric => 'Entsperren fehlgeschlagen.';

  @override
  String get legacyMigrationWrongPassword => 'Passwort falsch.';

  @override
  String get legacyMigrationFailed => 'Migration fehlgeschlagen.';

  @override
  String get legacyMigrationNoBiometricsSetUp =>
      'Auf diesem Geraet ist keine Biometrie eingerichtet. Bitte zuerst einrichten.';

  @override
  String get actionScanReceipt => 'Bon scannen';

  @override
  String get actionExpenses => 'Ausgaben';

  @override
  String get actionBudgets => 'Budgets';

  @override
  String get actionCategories => 'Kategorien';

  @override
  String get actionSettings => 'Einstellungen';

  @override
  String get actionStats => 'Statistik';

  @override
  String get actionLogout => 'Abmelden';

  @override
  String get actionPickRange => 'Zeitraum wählen';

  @override
  String get commonNew => 'Neu';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCreate => 'Anlegen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonError => 'Fehler';

  @override
  String commonErrorWithDetail(String detail) {
    return 'Fehler: $detail';
  }

  @override
  String get expenseFallbackName => 'Ausgabe';

  @override
  String get homeNoBudgetSet => 'Noch kein Budget gesetzt';

  @override
  String get homeRemainingThisMonth => 'Restbudget diesen Monat';

  @override
  String homeSpentOfTotal(String spent, String total) {
    return 'Ausgegeben: $spent von $total';
  }

  @override
  String get homeScanReceiptSubtitle => 'Foto + OCR, dann prüfen & speichern';

  @override
  String get homeExpensesSubtitle => 'Erfassen, einsehen, bearbeiten';

  @override
  String get homeBudgetsSubtitle => 'Monatsbudget pro Kategorie setzen';

  @override
  String get homeCategoriesSubtitle =>
      'Eigene Kategorien anlegen, ein-/ausblenden';

  @override
  String get dashboardEditBudgets => 'Budgets bearbeiten';

  @override
  String get dashboardNoVisibleCategories => 'Keine Kategorien sichtbar.';

  @override
  String get dashboardRecentExpensesTitle => 'Letzte Ausgaben';

  @override
  String get dashboardSeeAll => 'Alle ansehen';

  @override
  String get dashboardNoExpensesThisMonth =>
      'Noch keine Ausgaben in diesem Monat.';

  @override
  String get dashboardNoBudgetSet => 'Kein Budget gesetzt';

  @override
  String get dashboardRemaining => 'verbleibend';

  @override
  String get dashboardTipEditBudgets => 'Tippe \"Budgets bearbeiten\"';

  @override
  String dashboardSpent(String spent) {
    return 'Ausgegeben: $spent';
  }

  @override
  String dashboardSpentOfTotal(String spent, String total) {
    return 'Ausgegeben: $spent von $total';
  }

  @override
  String get dashboardBudgetUsageLabel => 'Budget-Auslastung';

  @override
  String dashboardPercentSpoken(int pct) {
    return '$pct Prozent';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSecuritySection => 'Sicherheit';

  @override
  String get settingsAutoLogoutTitle => 'Auto-Logout';

  @override
  String get settingsAutoLogoutLoading => 'Lade…';

  @override
  String get settingsAutoLogoutLoadError =>
      'Einstellung konnte nicht geladen werden.';

  @override
  String settingsAutoLogoutValue(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesString Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String settingsAutoLogoutSliderLabel(int minutes) {
    return '$minutes Min';
  }

  @override
  String get settingsAutoLogoutDescription =>
      'Nach so vielen Minuten ohne Bedienung wirst du abgemeldet. Beim Wechsel in den Hintergrund passiert das sofort, unabhängig vom Wert.';

  @override
  String get settingsDataSection => 'Daten';

  @override
  String get settingsDeleteAccountTitle => 'Account und alle Daten löschen';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Unwiderruflich. Setzt die App auf Werkseinstellungen zurück.';

  @override
  String get settingsAboutSection => 'Über';

  @override
  String settingsAboutAppTitle(String appName) {
    return 'Über $appName';
  }

  @override
  String get settingsAboutSubtitle => 'Lokal, privacy-first, keine Cloud.';

  @override
  String get settingsAboutLegalese =>
      'Alle Daten bleiben lokal auf diesem Gerät. AES-256 verschlüsselte Datenbank. Zugriff per Biometrie / Geräte-PIN.';

  @override
  String get settingsLicensesTitle => 'Open-Source-Lizenzen';

  @override
  String get settingsBiometricsTitle => 'Biometrie / Geräte-PIN';

  @override
  String get settingsBiometricsChecking => 'Prüfe…';

  @override
  String get settingsBiometricsActive =>
      'Aktiv. Nur Biometrie oder Geräte-PIN gibt Zugriff frei.';

  @override
  String get settingsBiometricsNone =>
      'Auf dem Gerät ist keine Biometrie eingerichtet. Bitte System-Einstellungen prüfen.';

  @override
  String get settingsResetSnack => 'Account und alle Daten gelöscht.';

  @override
  String get settingsResetError => 'Fehler beim Zurücksetzen.';

  @override
  String get settingsResetTitle => 'Wirklich alles löschen?';

  @override
  String get settingsResetBody =>
      'Account, alle Kategorien, Budgets und Ausgaben werden unwiderruflich entfernt. Es gibt keinen Backup.';

  @override
  String get settingsResetConfirmCheck =>
      'Mir ist klar, dass das nicht rückgängig zu machen ist.';

  @override
  String get settingsResetConfirmAction => 'Endgültig löschen';

  @override
  String get budgetTitle => 'Budgets';

  @override
  String get budgetTotal => 'Gesamt-Budget';

  @override
  String get budgetSaveDialogTitle => 'Budgets speichern?';

  @override
  String budgetSaveDialogBody(String amount) {
    return 'Neues Gesamt-Budget: $amount';
  }

  @override
  String get budgetSaveButton => 'Budgets speichern';

  @override
  String get budgetSavedSnack => 'Budgets gespeichert.';

  @override
  String get categoriesTitle => 'Kategorien';

  @override
  String get categoriesEmpty => 'Noch keine Kategorien.';

  @override
  String get categoriesBadgeDefault => 'Standard';

  @override
  String get categoriesBadgeHidden => 'Ausgeblendet';

  @override
  String categoriesDeleteTitle(String name) {
    return '„$name\" entfernen?';
  }

  @override
  String get categoriesDeleteBodyDefault =>
      'Default-Kategorien werden nur ausgeblendet, damit deine bisherigen Ausgaben weiterhin korrekt zugeordnet sind. Du kannst sie später wieder einblenden.';

  @override
  String get categoriesDeleteBodyCustom =>
      'Die Kategorie wird endgültig gelöscht. Bestehende Ausgaben in dieser Kategorie verhindern das Löschen.';

  @override
  String get categoryEditTitleEdit => 'Kategorie bearbeiten';

  @override
  String get categoryEditTitleNew => 'Neue Kategorie';

  @override
  String get categoryEditNameLabel => 'Name';

  @override
  String get categoryEditNameRequired => 'Bitte einen Namen eingeben.';

  @override
  String get categoryEditColorLabel => 'Farbe';

  @override
  String get categoryEditIconLabel => 'Icon';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsTrendTitle => 'Verlauf der letzten 12 Monate';

  @override
  String get statsTopCategoriesTitle => 'Top-Kategorien';

  @override
  String get statsCategoryVsBudgetTitle => 'Kategorie vs. Budget';

  @override
  String get statsCurrentPeriod => 'Aktueller Zeitraum';

  @override
  String statsPreviousPeriod(String amount) {
    return 'Vorperiode: $amount';
  }

  @override
  String get statsDailyAverageTitle => 'Tagesdurchschnitt';

  @override
  String get statsDailyAverageSubtitle => 'pro Tag';

  @override
  String get statsNoDataInRange => 'Noch keine Ausgaben im gewählten Zeitraum.';

  @override
  String get statsNoData => 'Noch keine Daten.';

  @override
  String get statsRest => 'Rest';

  @override
  String get statsUnknown => 'Unbekannt';

  @override
  String get statsNoVisibleCategories => 'Keine sichtbaren Kategorien.';

  @override
  String get statsCategoryUsageLabel => 'Auslastung Kategorie';

  @override
  String get statsMonthJan => 'Jan';

  @override
  String get statsMonthFeb => 'Feb';

  @override
  String get statsMonthMar => 'Mrz';

  @override
  String get statsMonthApr => 'Apr';

  @override
  String get statsMonthMay => 'Mai';

  @override
  String get statsMonthJun => 'Jun';

  @override
  String get statsMonthJul => 'Jul';

  @override
  String get statsMonthAug => 'Aug';

  @override
  String get statsMonthSep => 'Sep';

  @override
  String get statsMonthOct => 'Okt';

  @override
  String get statsMonthNov => 'Nov';

  @override
  String get statsMonthDec => 'Dez';

  @override
  String get expensesListTitle => 'Ausgaben';

  @override
  String get expensesListEmpty => 'Noch keine Ausgaben in diesem Monat';

  @override
  String get expensesListEmptyHint =>
      'Tippe auf \"Neu\", um eine Ausgabe zu erfassen.';

  @override
  String expensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben',
      one: '1 Ausgabe',
    );
    return '$_temp0';
  }

  @override
  String expenseItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Positionen',
      one: '1 Position',
    );
    return '$_temp0';
  }

  @override
  String get expenseDeleteTitle => 'Ausgabe löschen?';

  @override
  String expenseDeleteBody(String name, String amount) {
    return '$name ($amount) wird unwiderruflich gelöscht.';
  }

  @override
  String get expenseFormTitleEdit => 'Ausgabe bearbeiten';

  @override
  String get expenseFormTitleReview => 'Ausgabe prüfen & speichern';

  @override
  String get expenseFormTitleNew => 'Neue Ausgabe';

  @override
  String get expenseFormSelectCategory => 'Bitte eine Kategorie wählen.';

  @override
  String get expenseFormAmountGreaterZero => 'Betrag muss größer 0 sein.';

  @override
  String expenseFormSaveError(String detail) {
    return 'Fehler beim Speichern: $detail';
  }

  @override
  String get expenseFormNoVisibleCategories =>
      'Keine sichtbaren Kategorien. Bitte erst eine Kategorie anlegen.';

  @override
  String get expenseFormModeSection => 'Modus';

  @override
  String get expenseFormModeWithItems => 'Mit Positionen';

  @override
  String get expenseFormModeOnlyTotal => 'Nur Gesamtbetrag';

  @override
  String get expenseFormModeOnlyTotalHint =>
      'Positionen werden nicht gespeichert. Default-Kategorie ist \"Sonstiges\" – du kannst auch eine andere wählen.';

  @override
  String get expenseFormGeneralSection => 'Allgemein';

  @override
  String get expenseFormMerchantLabel => 'Händler';

  @override
  String get expenseFormMerchantHint => 'z. B. Rewe, Aldi';

  @override
  String get expenseFormCategoryLabel => 'Kategorie';

  @override
  String get expenseFormDateLabel => 'Datum';

  @override
  String get expenseFormAmountSection => 'Betrag';

  @override
  String expenseFormItemsSum(String amount) {
    return 'Aus Positionen: $amount';
  }

  @override
  String get expenseFormTotalLabel => 'Gesamtbetrag';

  @override
  String get expenseFormTotalLabelOverridesItems =>
      'Gesamtbetrag (überschreibt Positionen-Summe)';

  @override
  String get expenseFormTotalValidation => 'Bitte einen Betrag > 0 eingeben';

  @override
  String get expenseFormItemsSection => 'Positionen (optional)';

  @override
  String get expenseFormItemsEmpty =>
      'Keine Positionen erfasst. Wenn du den Bon abfotografierst, füllt der OCR-Parser das automatisch.';

  @override
  String get expenseFormItemHint => 'Position';

  @override
  String get expenseFormItemRemoveTooltip => 'Position entfernen';

  @override
  String get expenseFormNoteSection => 'Notiz (optional)';

  @override
  String get expenseFormNoteHint => 'z. B. Wocheneinkauf';

  @override
  String get expenseFormCreateButton => 'Ausgabe anlegen';

  @override
  String get receiptScanTitle => 'Bon scannen';

  @override
  String get receiptScanOpeningCamera => 'Kamera wird geöffnet…';

  @override
  String get receiptScanOpeningGallery => 'Galerie wird geöffnet…';

  @override
  String get receiptScanReading => 'Bon wird gelesen…';

  @override
  String receiptScanLowConfidence(int pct, String total) {
    return 'Erkennung unsicher ($pct %). Bitte Werte prüfen. Total: $total';
  }

  @override
  String get receiptScanFailed =>
      'Bon konnte nicht gelesen werden. Bitte erneut versuchen.';

  @override
  String get receiptScanPrivacyTitle => 'Privacy first';

  @override
  String get receiptScanPrivacyBody =>
      'Das Bild bleibt auf deinem Gerät. Es wird lokal kontrastoptimiert, dann läuft die OCR on-device. Nach der Auswertung wird das Foto sofort gelöscht.';

  @override
  String get receiptScanCamera => 'Foto aufnehmen';

  @override
  String get receiptScanGallery => 'Aus Galerie wählen';
}
