import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In de, this message translates to:
  /// **'BonBudget'**
  String get appName;

  /// No description provided for @splashLoading.
  ///
  /// In de, this message translates to:
  /// **'App wird geladen'**
  String get splashLoading;

  /// No description provided for @setupTitleWelcome.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei {appName}'**
  String setupTitleWelcome(String appName);

  /// No description provided for @setupExplanation.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten werden lokal verschluesselt gespeichert. Zugriff bekommst du ueber Biometrie (Fingerabdruck / Gesicht) oder die Geraete-PIN.'**
  String get setupExplanation;

  /// No description provided for @setupNoRecoveryWarning.
  ///
  /// In de, this message translates to:
  /// **'Wichtig: Es gibt keinen Cloud-Backup und kein Recovery. Bei Geraeteverlust sind alle Bons, Budgets und Kategorien unwiederbringlich weg.'**
  String get setupNoRecoveryWarning;

  /// No description provided for @setupNoBiometricsHint.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Geraet ist keine Biometrie eingerichtet. Bitte zuerst in den System-Einstellungen einen Fingerabdruck oder Face-ID hinterlegen und die App neu starten.'**
  String get setupNoBiometricsHint;

  /// No description provided for @setupButton.
  ///
  /// In de, this message translates to:
  /// **'Mit Biometrie einrichten'**
  String get setupButton;

  /// No description provided for @unlockHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf \"Entsperren\", um deine Daten freizugeben.'**
  String get unlockHint;

  /// No description provided for @unlockButton.
  ///
  /// In de, this message translates to:
  /// **'Entsperren'**
  String get unlockButton;

  /// No description provided for @resetAccountAction.
  ///
  /// In de, this message translates to:
  /// **'Account zuruecksetzen'**
  String get resetAccountAction;

  /// No description provided for @resetAccountConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Wirklich zuruecksetzen?'**
  String get resetAccountConfirmTitle;

  /// No description provided for @resetAccountConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Bons, Budgets und Kategorien werden unwiederbringlich geloescht. Danach steht die App wieder am Anfang. Diese Aktion kann nicht rueckgaengig gemacht werden.'**
  String get resetAccountConfirmBody;

  /// No description provided for @resetAccountConfirmAction.
  ///
  /// In de, this message translates to:
  /// **'Loeschen'**
  String get resetAccountConfirmAction;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @legacyMigrationTitle.
  ///
  /// In de, this message translates to:
  /// **'{appName}: Anmeldung umstellen'**
  String legacyMigrationTitle(String appName);

  /// No description provided for @legacyMigrationExplanation.
  ///
  /// In de, this message translates to:
  /// **'Wir stellen die Anmeldung auf Biometrie um. Dafuer brauchen wir einmal dein altes App-Passwort.'**
  String get legacyMigrationExplanation;

  /// No description provided for @legacyMigrationOldPasswordLabel.
  ///
  /// In de, this message translates to:
  /// **'Bisheriges Passwort'**
  String get legacyMigrationOldPasswordLabel;

  /// No description provided for @legacyMigrationButton.
  ///
  /// In de, this message translates to:
  /// **'Auf Biometrie umstellen'**
  String get legacyMigrationButton;

  /// No description provided for @legacyMigrationEmptyError.
  ///
  /// In de, this message translates to:
  /// **'Bitte eingeben.'**
  String get legacyMigrationEmptyError;

  /// No description provided for @biometricCancelled.
  ///
  /// In de, this message translates to:
  /// **'Vorgang abgebrochen.'**
  String get biometricCancelled;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Biometrie nicht verfuegbar: {reason}'**
  String biometricNotAvailable(String reason);

  /// No description provided for @biometricLockedOutPermanent.
  ///
  /// In de, this message translates to:
  /// **'Biometrie ist dauerhaft gesperrt. Bitte ueber die Geraete-Einstellungen freischalten.'**
  String get biometricLockedOutPermanent;

  /// No description provided for @biometricLockedOutTemporary.
  ///
  /// In de, this message translates to:
  /// **'Biometrie ist temporaer gesperrt. Bitte spaeter erneut versuchen.'**
  String get biometricLockedOutTemporary;

  /// No description provided for @biometricGenericFailure.
  ///
  /// In de, this message translates to:
  /// **'Biometrie-Fehler.'**
  String get biometricGenericFailure;

  /// No description provided for @setupFailedGeneric.
  ///
  /// In de, this message translates to:
  /// **'Einrichtung fehlgeschlagen.'**
  String get setupFailedGeneric;

  /// No description provided for @unlockFailedGeneric.
  ///
  /// In de, this message translates to:
  /// **'Entsperren fehlgeschlagen.'**
  String get unlockFailedGeneric;

  /// No description provided for @legacyMigrationWrongPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort falsch.'**
  String get legacyMigrationWrongPassword;

  /// No description provided for @legacyMigrationFailed.
  ///
  /// In de, this message translates to:
  /// **'Migration fehlgeschlagen.'**
  String get legacyMigrationFailed;

  /// No description provided for @legacyMigrationNoBiometricsSetUp.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Geraet ist keine Biometrie eingerichtet. Bitte zuerst einrichten.'**
  String get legacyMigrationNoBiometricsSetUp;

  /// No description provided for @actionScanReceipt.
  ///
  /// In de, this message translates to:
  /// **'Bon scannen'**
  String get actionScanReceipt;

  /// No description provided for @actionExpenses.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get actionExpenses;

  /// No description provided for @actionBudgets.
  ///
  /// In de, this message translates to:
  /// **'Budgets'**
  String get actionBudgets;

  /// No description provided for @actionCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get actionCategories;

  /// No description provided for @actionSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get actionSettings;

  /// No description provided for @actionStats.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get actionStats;

  /// No description provided for @actionLogout.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get actionLogout;

  /// No description provided for @actionPickRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum wählen'**
  String get actionPickRange;

  /// No description provided for @commonNew.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get commonNew;

  /// No description provided for @commonSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @commonCreate.
  ///
  /// In de, this message translates to:
  /// **'Anlegen'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get commonRemove;

  /// No description provided for @commonAdd.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get commonEdit;

  /// No description provided for @commonError.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get commonError;

  /// No description provided for @commonErrorWithDetail.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {detail}'**
  String commonErrorWithDetail(String detail);

  /// No description provided for @expenseFallbackName.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe'**
  String get expenseFallbackName;

  /// No description provided for @homeNoBudgetSet.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Budget gesetzt'**
  String get homeNoBudgetSet;

  /// No description provided for @homeRemainingThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Restbudget diesen Monat'**
  String get homeRemainingThisMonth;

  /// No description provided for @homeSpentOfTotal.
  ///
  /// In de, this message translates to:
  /// **'Ausgegeben: {spent} von {total}'**
  String homeSpentOfTotal(String spent, String total);

  /// No description provided for @homeScanReceiptSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Foto + OCR, dann prüfen & speichern'**
  String get homeScanReceiptSubtitle;

  /// No description provided for @homeExpensesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Erfassen, einsehen, bearbeiten'**
  String get homeExpensesSubtitle;

  /// No description provided for @homeBudgetsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Monatsbudget pro Kategorie setzen'**
  String get homeBudgetsSubtitle;

  /// No description provided for @homeCategoriesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Eigene Kategorien anlegen, ein-/ausblenden'**
  String get homeCategoriesSubtitle;

  /// No description provided for @dashboardEditBudgets.
  ///
  /// In de, this message translates to:
  /// **'Budgets bearbeiten'**
  String get dashboardEditBudgets;

  /// No description provided for @dashboardNoVisibleCategories.
  ///
  /// In de, this message translates to:
  /// **'Keine Kategorien sichtbar.'**
  String get dashboardNoVisibleCategories;

  /// No description provided for @dashboardRecentExpensesTitle.
  ///
  /// In de, this message translates to:
  /// **'Letzte Ausgaben'**
  String get dashboardRecentExpensesTitle;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In de, this message translates to:
  /// **'Alle ansehen'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardNoExpensesThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgaben in diesem Monat.'**
  String get dashboardNoExpensesThisMonth;

  /// No description provided for @dashboardNoBudgetSet.
  ///
  /// In de, this message translates to:
  /// **'Kein Budget gesetzt'**
  String get dashboardNoBudgetSet;

  /// No description provided for @dashboardRemaining.
  ///
  /// In de, this message translates to:
  /// **'verbleibend'**
  String get dashboardRemaining;

  /// No description provided for @dashboardTipEditBudgets.
  ///
  /// In de, this message translates to:
  /// **'Tippe \"Budgets bearbeiten\"'**
  String get dashboardTipEditBudgets;

  /// No description provided for @dashboardSpent.
  ///
  /// In de, this message translates to:
  /// **'Ausgegeben: {spent}'**
  String dashboardSpent(String spent);

  /// No description provided for @dashboardSpentOfTotal.
  ///
  /// In de, this message translates to:
  /// **'Ausgegeben: {spent} von {total}'**
  String dashboardSpentOfTotal(String spent, String total);

  /// No description provided for @dashboardBudgetUsageLabel.
  ///
  /// In de, this message translates to:
  /// **'Budget-Auslastung'**
  String get dashboardBudgetUsageLabel;

  /// No description provided for @dashboardPercentSpoken.
  ///
  /// In de, this message translates to:
  /// **'{pct} Prozent'**
  String dashboardPercentSpoken(int pct);

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get settingsSecuritySection;

  /// No description provided for @settingsAutoLogoutTitle.
  ///
  /// In de, this message translates to:
  /// **'Auto-Logout'**
  String get settingsAutoLogoutTitle;

  /// No description provided for @settingsAutoLogoutLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade…'**
  String get settingsAutoLogoutLoading;

  /// No description provided for @settingsAutoLogoutLoadError.
  ///
  /// In de, this message translates to:
  /// **'Einstellung konnte nicht geladen werden.'**
  String get settingsAutoLogoutLoadError;

  /// No description provided for @settingsAutoLogoutValue.
  ///
  /// In de, this message translates to:
  /// **'{minutes, plural, =1{1 Minute} other{{minutes} Minuten}}'**
  String settingsAutoLogoutValue(int minutes);

  /// No description provided for @settingsAutoLogoutSliderLabel.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min'**
  String settingsAutoLogoutSliderLabel(int minutes);

  /// No description provided for @settingsAutoLogoutDescription.
  ///
  /// In de, this message translates to:
  /// **'Nach so vielen Minuten ohne Bedienung wirst du abgemeldet. Beim Wechsel in den Hintergrund passiert das sofort, unabhängig vom Wert.'**
  String get settingsAutoLogoutDescription;

  /// No description provided for @settingsDataSection.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get settingsDataSection;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In de, this message translates to:
  /// **'Account und alle Daten löschen'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Unwiderruflich. Setzt die App auf Werkseinstellungen zurück.'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsAboutSection.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get settingsAboutSection;

  /// No description provided for @settingsAboutAppTitle.
  ///
  /// In de, this message translates to:
  /// **'Über {appName}'**
  String settingsAboutAppTitle(String appName);

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Lokal, privacy-first, keine Cloud.'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAboutLegalese.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben lokal auf diesem Gerät. AES-256 verschlüsselte Datenbank. Zugriff per Biometrie / Geräte-PIN.'**
  String get settingsAboutLegalese;

  /// No description provided for @settingsLicensesTitle.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get settingsLicensesTitle;

  /// No description provided for @settingsBiometricsTitle.
  ///
  /// In de, this message translates to:
  /// **'Biometrie / Geräte-PIN'**
  String get settingsBiometricsTitle;

  /// No description provided for @settingsBiometricsChecking.
  ///
  /// In de, this message translates to:
  /// **'Prüfe…'**
  String get settingsBiometricsChecking;

  /// No description provided for @settingsBiometricsActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv. Nur Biometrie oder Geräte-PIN gibt Zugriff frei.'**
  String get settingsBiometricsActive;

  /// No description provided for @settingsBiometricsNone.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Gerät ist keine Biometrie eingerichtet. Bitte System-Einstellungen prüfen.'**
  String get settingsBiometricsNone;

  /// No description provided for @settingsResetSnack.
  ///
  /// In de, this message translates to:
  /// **'Account und alle Daten gelöscht.'**
  String get settingsResetSnack;

  /// No description provided for @settingsResetError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Zurücksetzen.'**
  String get settingsResetError;

  /// No description provided for @settingsResetTitle.
  ///
  /// In de, this message translates to:
  /// **'Wirklich alles löschen?'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In de, this message translates to:
  /// **'Account, alle Kategorien, Budgets und Ausgaben werden unwiderruflich entfernt. Es gibt keinen Backup.'**
  String get settingsResetBody;

  /// No description provided for @settingsResetConfirmCheck.
  ///
  /// In de, this message translates to:
  /// **'Mir ist klar, dass das nicht rückgängig zu machen ist.'**
  String get settingsResetConfirmCheck;

  /// No description provided for @settingsResetConfirmAction.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get settingsResetConfirmAction;

  /// No description provided for @budgetTitle.
  ///
  /// In de, this message translates to:
  /// **'Budgets'**
  String get budgetTitle;

  /// No description provided for @budgetTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamt-Budget'**
  String get budgetTotal;

  /// No description provided for @budgetSaveDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Budgets speichern?'**
  String get budgetSaveDialogTitle;

  /// No description provided for @budgetSaveDialogBody.
  ///
  /// In de, this message translates to:
  /// **'Neues Gesamt-Budget: {amount}'**
  String budgetSaveDialogBody(String amount);

  /// No description provided for @budgetSaveButton.
  ///
  /// In de, this message translates to:
  /// **'Budgets speichern'**
  String get budgetSaveButton;

  /// No description provided for @budgetSavedSnack.
  ///
  /// In de, this message translates to:
  /// **'Budgets gespeichert.'**
  String get budgetSavedSnack;

  /// No description provided for @categoriesTitle.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Kategorien.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesBadgeDefault.
  ///
  /// In de, this message translates to:
  /// **'Standard'**
  String get categoriesBadgeDefault;

  /// No description provided for @categoriesBadgeHidden.
  ///
  /// In de, this message translates to:
  /// **'Ausgeblendet'**
  String get categoriesBadgeHidden;

  /// No description provided for @categoriesDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'„{name}\" entfernen?'**
  String categoriesDeleteTitle(String name);

  /// No description provided for @categoriesDeleteBodyDefault.
  ///
  /// In de, this message translates to:
  /// **'Default-Kategorien werden nur ausgeblendet, damit deine bisherigen Ausgaben weiterhin korrekt zugeordnet sind. Du kannst sie später wieder einblenden.'**
  String get categoriesDeleteBodyDefault;

  /// No description provided for @categoriesDeleteBodyCustom.
  ///
  /// In de, this message translates to:
  /// **'Die Kategorie wird endgültig gelöscht. Bestehende Ausgaben in dieser Kategorie verhindern das Löschen.'**
  String get categoriesDeleteBodyCustom;

  /// No description provided for @categoryEditTitleEdit.
  ///
  /// In de, this message translates to:
  /// **'Kategorie bearbeiten'**
  String get categoryEditTitleEdit;

  /// No description provided for @categoryEditTitleNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Kategorie'**
  String get categoryEditTitleNew;

  /// No description provided for @categoryEditNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get categoryEditNameLabel;

  /// No description provided for @categoryEditNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen eingeben.'**
  String get categoryEditNameRequired;

  /// No description provided for @categoryEditColorLabel.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get categoryEditColorLabel;

  /// No description provided for @categoryEditIconLabel.
  ///
  /// In de, this message translates to:
  /// **'Icon'**
  String get categoryEditIconLabel;

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statsTitle;

  /// No description provided for @statsTrendTitle.
  ///
  /// In de, this message translates to:
  /// **'Verlauf der letzten 12 Monate'**
  String get statsTrendTitle;

  /// No description provided for @statsTopCategoriesTitle.
  ///
  /// In de, this message translates to:
  /// **'Top-Kategorien'**
  String get statsTopCategoriesTitle;

  /// No description provided for @statsCategoryVsBudgetTitle.
  ///
  /// In de, this message translates to:
  /// **'Kategorie vs. Budget'**
  String get statsCategoryVsBudgetTitle;

  /// No description provided for @statsCurrentPeriod.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Zeitraum'**
  String get statsCurrentPeriod;

  /// No description provided for @statsPreviousPeriod.
  ///
  /// In de, this message translates to:
  /// **'Vorperiode: {amount}'**
  String statsPreviousPeriod(String amount);

  /// No description provided for @statsDailyAverageTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagesdurchschnitt'**
  String get statsDailyAverageTitle;

  /// No description provided for @statsDailyAverageSubtitle.
  ///
  /// In de, this message translates to:
  /// **'pro Tag'**
  String get statsDailyAverageSubtitle;

  /// No description provided for @statsNoDataInRange.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgaben im gewählten Zeitraum.'**
  String get statsNoDataInRange;

  /// No description provided for @statsNoData.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten.'**
  String get statsNoData;

  /// No description provided for @statsRest.
  ///
  /// In de, this message translates to:
  /// **'Rest'**
  String get statsRest;

  /// No description provided for @statsUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get statsUnknown;

  /// No description provided for @statsNoVisibleCategories.
  ///
  /// In de, this message translates to:
  /// **'Keine sichtbaren Kategorien.'**
  String get statsNoVisibleCategories;

  /// No description provided for @statsCategoryUsageLabel.
  ///
  /// In de, this message translates to:
  /// **'Auslastung Kategorie'**
  String get statsCategoryUsageLabel;

  /// No description provided for @statsMonthJan.
  ///
  /// In de, this message translates to:
  /// **'Jan'**
  String get statsMonthJan;

  /// No description provided for @statsMonthFeb.
  ///
  /// In de, this message translates to:
  /// **'Feb'**
  String get statsMonthFeb;

  /// No description provided for @statsMonthMar.
  ///
  /// In de, this message translates to:
  /// **'Mrz'**
  String get statsMonthMar;

  /// No description provided for @statsMonthApr.
  ///
  /// In de, this message translates to:
  /// **'Apr'**
  String get statsMonthApr;

  /// No description provided for @statsMonthMay.
  ///
  /// In de, this message translates to:
  /// **'Mai'**
  String get statsMonthMay;

  /// No description provided for @statsMonthJun.
  ///
  /// In de, this message translates to:
  /// **'Jun'**
  String get statsMonthJun;

  /// No description provided for @statsMonthJul.
  ///
  /// In de, this message translates to:
  /// **'Jul'**
  String get statsMonthJul;

  /// No description provided for @statsMonthAug.
  ///
  /// In de, this message translates to:
  /// **'Aug'**
  String get statsMonthAug;

  /// No description provided for @statsMonthSep.
  ///
  /// In de, this message translates to:
  /// **'Sep'**
  String get statsMonthSep;

  /// No description provided for @statsMonthOct.
  ///
  /// In de, this message translates to:
  /// **'Okt'**
  String get statsMonthOct;

  /// No description provided for @statsMonthNov.
  ///
  /// In de, this message translates to:
  /// **'Nov'**
  String get statsMonthNov;

  /// No description provided for @statsMonthDec.
  ///
  /// In de, this message translates to:
  /// **'Dez'**
  String get statsMonthDec;

  /// No description provided for @expensesListTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get expensesListTitle;

  /// No description provided for @expensesListEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgaben in diesem Monat'**
  String get expensesListEmpty;

  /// No description provided for @expensesListEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf \"Neu\", um eine Ausgabe zu erfassen.'**
  String get expensesListEmptyHint;

  /// No description provided for @expensesCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Ausgabe} other{{count} Ausgaben}}'**
  String expensesCount(int count);

  /// No description provided for @expenseItemsCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Position} other{{count} Positionen}}'**
  String expenseItemsCount(int count);

  /// No description provided for @expenseDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe löschen?'**
  String get expenseDeleteTitle;

  /// No description provided for @expenseDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'{name} ({amount}) wird unwiderruflich gelöscht.'**
  String expenseDeleteBody(String name, String amount);

  /// No description provided for @expenseFormTitleEdit.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe bearbeiten'**
  String get expenseFormTitleEdit;

  /// No description provided for @expenseFormTitleReview.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe prüfen & speichern'**
  String get expenseFormTitleReview;

  /// No description provided for @expenseFormTitleNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Ausgabe'**
  String get expenseFormTitleNew;

  /// No description provided for @expenseFormSelectCategory.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Kategorie wählen.'**
  String get expenseFormSelectCategory;

  /// No description provided for @expenseFormAmountGreaterZero.
  ///
  /// In de, this message translates to:
  /// **'Betrag muss größer 0 sein.'**
  String get expenseFormAmountGreaterZero;

  /// No description provided for @expenseFormSaveError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern: {detail}'**
  String expenseFormSaveError(String detail);

  /// No description provided for @expenseFormNoVisibleCategories.
  ///
  /// In de, this message translates to:
  /// **'Keine sichtbaren Kategorien. Bitte erst eine Kategorie anlegen.'**
  String get expenseFormNoVisibleCategories;

  /// No description provided for @expenseFormModeSection.
  ///
  /// In de, this message translates to:
  /// **'Modus'**
  String get expenseFormModeSection;

  /// No description provided for @expenseFormModeWithItems.
  ///
  /// In de, this message translates to:
  /// **'Mit Positionen'**
  String get expenseFormModeWithItems;

  /// No description provided for @expenseFormModeOnlyTotal.
  ///
  /// In de, this message translates to:
  /// **'Nur Gesamtbetrag'**
  String get expenseFormModeOnlyTotal;

  /// No description provided for @expenseFormModeOnlyTotalHint.
  ///
  /// In de, this message translates to:
  /// **'Positionen werden nicht gespeichert. Default-Kategorie ist \"Sonstiges\" – du kannst auch eine andere wählen.'**
  String get expenseFormModeOnlyTotalHint;

  /// No description provided for @expenseFormGeneralSection.
  ///
  /// In de, this message translates to:
  /// **'Allgemein'**
  String get expenseFormGeneralSection;

  /// No description provided for @expenseFormMerchantLabel.
  ///
  /// In de, this message translates to:
  /// **'Händler'**
  String get expenseFormMerchantLabel;

  /// No description provided for @expenseFormMerchantHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Rewe, Aldi'**
  String get expenseFormMerchantHint;

  /// No description provided for @expenseFormCategoryLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get expenseFormCategoryLabel;

  /// No description provided for @expenseFormDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get expenseFormDateLabel;

  /// No description provided for @expenseFormAmountSection.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get expenseFormAmountSection;

  /// No description provided for @expenseFormItemsSum.
  ///
  /// In de, this message translates to:
  /// **'Aus Positionen: {amount}'**
  String expenseFormItemsSum(String amount);

  /// No description provided for @expenseFormTotalLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesamtbetrag'**
  String get expenseFormTotalLabel;

  /// No description provided for @expenseFormTotalLabelOverridesItems.
  ///
  /// In de, this message translates to:
  /// **'Gesamtbetrag (überschreibt Positionen-Summe)'**
  String get expenseFormTotalLabelOverridesItems;

  /// No description provided for @expenseFormTotalValidation.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Betrag > 0 eingeben'**
  String get expenseFormTotalValidation;

  /// No description provided for @expenseFormItemsSection.
  ///
  /// In de, this message translates to:
  /// **'Positionen (optional)'**
  String get expenseFormItemsSection;

  /// No description provided for @expenseFormItemsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Positionen erfasst. Wenn du den Bon abfotografierst, füllt der OCR-Parser das automatisch.'**
  String get expenseFormItemsEmpty;

  /// No description provided for @expenseFormItemHint.
  ///
  /// In de, this message translates to:
  /// **'Position'**
  String get expenseFormItemHint;

  /// No description provided for @expenseFormItemRemoveTooltip.
  ///
  /// In de, this message translates to:
  /// **'Position entfernen'**
  String get expenseFormItemRemoveTooltip;

  /// No description provided for @expenseFormNoteSection.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get expenseFormNoteSection;

  /// No description provided for @expenseFormNoteHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Wocheneinkauf'**
  String get expenseFormNoteHint;

  /// No description provided for @expenseFormCreateButton.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe anlegen'**
  String get expenseFormCreateButton;

  /// No description provided for @receiptScanTitle.
  ///
  /// In de, this message translates to:
  /// **'Bon scannen'**
  String get receiptScanTitle;

  /// No description provided for @receiptScanOpeningCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera wird geöffnet…'**
  String get receiptScanOpeningCamera;

  /// No description provided for @receiptScanOpeningGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie wird geöffnet…'**
  String get receiptScanOpeningGallery;

  /// No description provided for @receiptScanReading.
  ///
  /// In de, this message translates to:
  /// **'Bon wird gelesen…'**
  String get receiptScanReading;

  /// No description provided for @receiptScanLowConfidence.
  ///
  /// In de, this message translates to:
  /// **'Erkennung unsicher ({pct} %). Bitte Werte prüfen. Total: {total}'**
  String receiptScanLowConfidence(int pct, String total);

  /// No description provided for @receiptScanFailed.
  ///
  /// In de, this message translates to:
  /// **'Bon konnte nicht gelesen werden. Bitte erneut versuchen.'**
  String get receiptScanFailed;

  /// No description provided for @receiptScanPrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Privacy first'**
  String get receiptScanPrivacyTitle;

  /// No description provided for @receiptScanPrivacyBody.
  ///
  /// In de, this message translates to:
  /// **'Das Bild bleibt auf deinem Gerät. Es wird lokal kontrastoptimiert, dann läuft die OCR on-device. Nach der Auswertung wird das Foto sofort gelöscht.'**
  String get receiptScanPrivacyBody;

  /// No description provided for @receiptScanCamera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get receiptScanCamera;

  /// No description provided for @receiptScanGallery.
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie wählen'**
  String get receiptScanGallery;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
