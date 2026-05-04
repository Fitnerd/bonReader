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
  String get actionScanReceipt;

  /// No description provided for @actionExpenses.
  String get actionExpenses;

  /// No description provided for @actionBudgets.
  String get actionBudgets;

  /// No description provided for @actionCategories.
  String get actionCategories;

  /// No description provided for @actionSettings.
  String get actionSettings;

  /// No description provided for @actionStats.
  String get actionStats;

  /// No description provided for @actionLogout.
  String get actionLogout;

  /// No description provided for @actionPickRange.
  String get actionPickRange;

  /// No description provided for @commonNew.
  String get commonNew;

  /// No description provided for @commonSave.
  String get commonSave;

  /// No description provided for @commonCreate.
  String get commonCreate;

  /// No description provided for @commonDelete.
  String get commonDelete;

  /// No description provided for @commonRemove.
  String get commonRemove;

  /// No description provided for @commonAdd.
  String get commonAdd;

  /// No description provided for @commonEdit.
  String get commonEdit;

  /// No description provided for @commonError.
  String get commonError;

  /// No description provided for @commonErrorWithDetail.
  String commonErrorWithDetail(String detail);

  /// No description provided for @expenseFallbackName.
  String get expenseFallbackName;

  /// No description provided for @homeNoBudgetSet.
  String get homeNoBudgetSet;

  /// No description provided for @homeRemainingThisMonth.
  String get homeRemainingThisMonth;

  /// No description provided for @homeSpentOfTotal.
  String homeSpentOfTotal(String spent, String total);

  /// No description provided for @homeScanReceiptSubtitle.
  String get homeScanReceiptSubtitle;

  /// No description provided for @homeExpensesSubtitle.
  String get homeExpensesSubtitle;

  /// No description provided for @homeBudgetsSubtitle.
  String get homeBudgetsSubtitle;

  /// No description provided for @homeCategoriesSubtitle.
  String get homeCategoriesSubtitle;

  /// No description provided for @dashboardEditBudgets.
  String get dashboardEditBudgets;

  /// No description provided for @dashboardNoVisibleCategories.
  String get dashboardNoVisibleCategories;

  /// No description provided for @dashboardRecentExpensesTitle.
  String get dashboardRecentExpensesTitle;

  /// No description provided for @dashboardSeeAll.
  String get dashboardSeeAll;

  /// No description provided for @dashboardNoExpensesThisMonth.
  String get dashboardNoExpensesThisMonth;

  /// No description provided for @dashboardNoBudgetSet.
  String get dashboardNoBudgetSet;

  /// No description provided for @dashboardRemaining.
  String get dashboardRemaining;

  /// No description provided for @dashboardTipEditBudgets.
  String get dashboardTipEditBudgets;

  /// No description provided for @dashboardSpent.
  String dashboardSpent(String spent);

  /// No description provided for @dashboardSpentOfTotal.
  String dashboardSpentOfTotal(String spent, String total);

  /// No description provided for @dashboardBudgetUsageLabel.
  String get dashboardBudgetUsageLabel;

  /// No description provided for @dashboardPercentSpoken.
  String dashboardPercentSpoken(int pct);

  /// No description provided for @settingsTitle.
  String get settingsTitle;

  /// No description provided for @settingsSecuritySection.
  String get settingsSecuritySection;

  /// No description provided for @settingsAutoLogoutTitle.
  String get settingsAutoLogoutTitle;

  /// No description provided for @settingsAutoLogoutLoading.
  String get settingsAutoLogoutLoading;

  /// No description provided for @settingsAutoLogoutLoadError.
  String get settingsAutoLogoutLoadError;

  /// No description provided for @settingsAutoLogoutValue.
  String settingsAutoLogoutValue(int minutes);

  /// No description provided for @settingsAutoLogoutSliderLabel.
  String settingsAutoLogoutSliderLabel(int minutes);

  /// No description provided for @settingsAutoLogoutDescription.
  String get settingsAutoLogoutDescription;

  /// No description provided for @settingsDataSection.
  String get settingsDataSection;

  /// No description provided for @settingsDeleteAccountTitle.
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountSubtitle.
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsAboutSection.
  String get settingsAboutSection;

  /// No description provided for @settingsAboutAppTitle.
  String settingsAboutAppTitle(String appName);

  /// No description provided for @settingsAboutSubtitle.
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAboutLegalese.
  String get settingsAboutLegalese;

  /// No description provided for @settingsLicensesTitle.
  String get settingsLicensesTitle;

  /// No description provided for @settingsBiometricsTitle.
  String get settingsBiometricsTitle;

  /// No description provided for @settingsBiometricsChecking.
  String get settingsBiometricsChecking;

  /// No description provided for @settingsBiometricsActive.
  String get settingsBiometricsActive;

  /// No description provided for @settingsBiometricsNone.
  String get settingsBiometricsNone;

  /// No description provided for @settingsResetSnack.
  String get settingsResetSnack;

  /// No description provided for @settingsResetError.
  String get settingsResetError;

  /// No description provided for @settingsResetTitle.
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  String get settingsResetBody;

  /// No description provided for @settingsResetConfirmCheck.
  String get settingsResetConfirmCheck;

  /// No description provided for @settingsResetConfirmAction.
  String get settingsResetConfirmAction;

  /// No description provided for @budgetTitle.
  String get budgetTitle;

  /// No description provided for @budgetTotal.
  String get budgetTotal;

  /// No description provided for @budgetSaveDialogTitle.
  String get budgetSaveDialogTitle;

  /// No description provided for @budgetSaveDialogBody.
  String budgetSaveDialogBody(String amount);

  /// No description provided for @budgetSaveButton.
  String get budgetSaveButton;

  /// No description provided for @budgetSavedSnack.
  String get budgetSavedSnack;

  /// No description provided for @categoriesTitle.
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  String get categoriesEmpty;

  /// No description provided for @categoriesBadgeDefault.
  String get categoriesBadgeDefault;

  /// No description provided for @categoriesBadgeHidden.
  String get categoriesBadgeHidden;

  /// No description provided for @categoriesDeleteTitle.
  String categoriesDeleteTitle(String name);

  /// No description provided for @categoriesDeleteBodyDefault.
  String get categoriesDeleteBodyDefault;

  /// No description provided for @categoriesDeleteBodyCustom.
  String get categoriesDeleteBodyCustom;

  /// No description provided for @categoryEditTitleEdit.
  String get categoryEditTitleEdit;

  /// No description provided for @categoryEditTitleNew.
  String get categoryEditTitleNew;

  /// No description provided for @categoryEditNameLabel.
  String get categoryEditNameLabel;

  /// No description provided for @categoryEditNameRequired.
  String get categoryEditNameRequired;

  /// No description provided for @categoryEditColorLabel.
  String get categoryEditColorLabel;

  /// No description provided for @categoryEditIconLabel.
  String get categoryEditIconLabel;

  /// No description provided for @statsTitle.
  String get statsTitle;

  /// No description provided for @statsTrendTitle.
  String get statsTrendTitle;

  /// No description provided for @statsTopCategoriesTitle.
  String get statsTopCategoriesTitle;

  /// No description provided for @statsCategoryVsBudgetTitle.
  String get statsCategoryVsBudgetTitle;

  /// No description provided for @statsCurrentPeriod.
  String get statsCurrentPeriod;

  /// No description provided for @statsPreviousPeriod.
  String statsPreviousPeriod(String amount);

  /// No description provided for @statsDailyAverageTitle.
  String get statsDailyAverageTitle;

  /// No description provided for @statsDailyAverageSubtitle.
  String get statsDailyAverageSubtitle;

  /// No description provided for @statsNoDataInRange.
  String get statsNoDataInRange;

  /// No description provided for @statsNoData.
  String get statsNoData;

  /// No description provided for @statsRest.
  String get statsRest;

  /// No description provided for @statsUnknown.
  String get statsUnknown;

  /// No description provided for @statsNoVisibleCategories.
  String get statsNoVisibleCategories;

  /// No description provided for @statsCategoryUsageLabel.
  String get statsCategoryUsageLabel;

  /// No description provided for @statsMonthJan.
  String get statsMonthJan;

  /// No description provided for @statsMonthFeb.
  String get statsMonthFeb;

  /// No description provided for @statsMonthMar.
  String get statsMonthMar;

  /// No description provided for @statsMonthApr.
  String get statsMonthApr;

  /// No description provided for @statsMonthMay.
  String get statsMonthMay;

  /// No description provided for @statsMonthJun.
  String get statsMonthJun;

  /// No description provided for @statsMonthJul.
  String get statsMonthJul;

  /// No description provided for @statsMonthAug.
  String get statsMonthAug;

  /// No description provided for @statsMonthSep.
  String get statsMonthSep;

  /// No description provided for @statsMonthOct.
  String get statsMonthOct;

  /// No description provided for @statsMonthNov.
  String get statsMonthNov;

  /// No description provided for @statsMonthDec.
  String get statsMonthDec;

  /// No description provided for @expensesListTitle.
  String get expensesListTitle;

  /// No description provided for @expensesListEmpty.
  String get expensesListEmpty;

  /// No description provided for @expensesListEmptyHint.
  String get expensesListEmptyHint;

  /// No description provided for @expensesCount.
  String expensesCount(int count);

  /// No description provided for @expenseItemsCount.
  String expenseItemsCount(int count);

  /// No description provided for @expenseDeleteTitle.
  String get expenseDeleteTitle;

  /// No description provided for @expenseDeleteBody.
  String expenseDeleteBody(String name, String amount);

  /// No description provided for @expenseFormTitleEdit.
  String get expenseFormTitleEdit;

  /// No description provided for @expenseFormTitleReview.
  String get expenseFormTitleReview;

  /// No description provided for @expenseFormTitleNew.
  String get expenseFormTitleNew;

  /// No description provided for @expenseFormSelectCategory.
  String get expenseFormSelectCategory;

  /// No description provided for @expenseFormAmountGreaterZero.
  String get expenseFormAmountGreaterZero;

  /// No description provided for @expenseFormSaveError.
  String expenseFormSaveError(String detail);

  /// No description provided for @expenseFormNoVisibleCategories.
  String get expenseFormNoVisibleCategories;

  /// No description provided for @expenseFormModeSection.
  String get expenseFormModeSection;

  /// No description provided for @expenseFormModeWithItems.
  String get expenseFormModeWithItems;

  /// No description provided for @expenseFormModeOnlyTotal.
  String get expenseFormModeOnlyTotal;

  /// No description provided for @expenseFormModeOnlyTotalHint.
  String get expenseFormModeOnlyTotalHint;

  /// No description provided for @expenseFormGeneralSection.
  String get expenseFormGeneralSection;

  /// No description provided for @expenseFormMerchantLabel.
  String get expenseFormMerchantLabel;

  /// No description provided for @expenseFormMerchantHint.
  String get expenseFormMerchantHint;

  /// No description provided for @expenseFormCategoryLabel.
  String get expenseFormCategoryLabel;

  /// No description provided for @expenseFormDateLabel.
  String get expenseFormDateLabel;

  /// No description provided for @expenseFormAmountSection.
  String get expenseFormAmountSection;

  /// No description provided for @expenseFormItemsSum.
  String expenseFormItemsSum(String amount);

  /// No description provided for @expenseFormTotalLabel.
  String get expenseFormTotalLabel;

  /// No description provided for @expenseFormTotalLabelOverridesItems.
  String get expenseFormTotalLabelOverridesItems;

  /// No description provided for @expenseFormTotalValidation.
  String get expenseFormTotalValidation;

  /// No description provided for @expenseFormItemsSection.
  String get expenseFormItemsSection;

  /// No description provided for @expenseFormItemsEmpty.
  String get expenseFormItemsEmpty;

  /// No description provided for @expenseFormItemHint.
  String get expenseFormItemHint;

  /// No description provided for @expenseFormItemRemoveTooltip.
  String get expenseFormItemRemoveTooltip;

  /// No description provided for @expenseFormNoteSection.
  String get expenseFormNoteSection;

  /// No description provided for @expenseFormNoteHint.
  String get expenseFormNoteHint;

  /// No description provided for @expenseFormCreateButton.
  String get expenseFormCreateButton;

  /// No description provided for @receiptScanTitle.
  String get receiptScanTitle;

  /// No description provided for @receiptScanOpeningCamera.
  String get receiptScanOpeningCamera;

  /// No description provided for @receiptScanOpeningGallery.
  String get receiptScanOpeningGallery;

  /// No description provided for @receiptScanReading.
  String get receiptScanReading;

  /// No description provided for @receiptScanLowConfidence.
  String receiptScanLowConfidence(int pct, String total);

  /// No description provided for @receiptScanFailed.
  String get receiptScanFailed;

  /// No description provided for @receiptScanPrivacyTitle.
  String get receiptScanPrivacyTitle;

  /// No description provided for @receiptScanPrivacyBody.
  String get receiptScanPrivacyBody;

  /// No description provided for @receiptScanCamera.
  String get receiptScanCamera;

  /// No description provided for @receiptScanGallery.
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
