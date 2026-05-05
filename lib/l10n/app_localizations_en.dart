// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BonBudget';

  @override
  String get splashLoading => 'Loading app';

  @override
  String setupTitleWelcome(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get setupExplanation =>
      'Your data is stored locally and encrypted. Access goes through biometrics (fingerprint / face) or the device PIN.';

  @override
  String get setupNoRecoveryWarning =>
      'Important: there is no cloud backup and no recovery. If you lose this device, all receipts, budgets and categories are gone for good.';

  @override
  String get setupNoBiometricsHint =>
      'Biometrics are not set up on this device. Please add a fingerprint or Face ID in your system settings and restart the app.';

  @override
  String get setupButton => 'Set up with biometrics';

  @override
  String get unlockHint => 'Tap \'Unlock\' to release your data.';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get resetAccountAction => 'Reset account';

  @override
  String get resetAccountConfirmTitle => 'Really reset?';

  @override
  String get resetAccountConfirmBody =>
      'All receipts, budgets and categories will be deleted permanently. The app will return to its initial state. This cannot be undone.';

  @override
  String get resetAccountConfirmAction => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String legacyMigrationTitle(String appName) {
    return '$appName: switch sign-in';
  }

  @override
  String get legacyMigrationExplanation =>
      'We are switching sign-in to biometrics. Please enter your old app password once.';

  @override
  String get legacyMigrationOldPasswordLabel => 'Existing password';

  @override
  String get legacyMigrationButton => 'Switch to biometrics';

  @override
  String get legacyMigrationEmptyError => 'Please enter the password.';

  @override
  String get biometricCancelled => 'Cancelled.';

  @override
  String biometricNotAvailable(String reason) {
    return 'Biometrics not available: $reason';
  }

  @override
  String get biometricLockedOutPermanent =>
      'Biometrics are permanently locked. Please unlock via device settings.';

  @override
  String get biometricLockedOutTemporary =>
      'Biometrics are temporarily locked. Please try again later.';

  @override
  String get biometricGenericFailure => 'Biometric error.';

  @override
  String get setupFailedGeneric => 'Setup failed.';

  @override
  String get unlockFailedGeneric => 'Unlock failed.';

  @override
  String get legacyMigrationWrongPassword => 'Wrong password.';

  @override
  String get legacyMigrationFailed => 'Migration failed.';

  @override
  String get legacyMigrationNoBiometricsSetUp =>
      'Biometrics are not set up on this device. Please set them up first.';

  @override
  String get actionScanReceipt => 'Scan receipt';

  @override
  String get actionExpenses => 'Expenses';

  @override
  String get actionBudgets => 'Budgets';

  @override
  String get actionCategories => 'Categories';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionStats => 'Statistics';

  @override
  String get actionLogout => 'Sign out';

  @override
  String get actionPickRange => 'Choose period';

  @override
  String get commonNew => 'New';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonError => 'Error';

  @override
  String commonErrorWithDetail(String detail) {
    return 'Error: $detail';
  }

  @override
  String get expenseFallbackName => 'Expense';

  @override
  String get homeNoBudgetSet => 'No budget set yet';

  @override
  String get homeRemainingThisMonth => 'Remaining this month';

  @override
  String homeSpentOfTotal(String spent, String total) {
    return 'Spent: $spent of $total';
  }

  @override
  String get homeScanReceiptSubtitle => 'Photo + OCR, then review & save';

  @override
  String get homeExpensesSubtitle => 'Add, view, edit';

  @override
  String get homeBudgetsSubtitle => 'Set monthly budget per category';

  @override
  String get homeCategoriesSubtitle =>
      'Create, show or hide your own categories';

  @override
  String get dashboardEditBudgets => 'Edit budgets';

  @override
  String get dashboardNoVisibleCategories => 'No categories visible.';

  @override
  String get dashboardRecentExpensesTitle => 'Recent expenses';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get dashboardNoExpensesThisMonth => 'No expenses this month yet.';

  @override
  String get dashboardNoBudgetSet => 'No budget set';

  @override
  String get dashboardRemaining => 'remaining';

  @override
  String get dashboardTipEditBudgets => 'Tap \'Edit budgets\'';

  @override
  String dashboardSpent(String spent) {
    return 'Spent: $spent';
  }

  @override
  String dashboardSpentOfTotal(String spent, String total) {
    return 'Spent: $spent of $total';
  }

  @override
  String get dashboardBudgetUsageLabel => 'Budget usage';

  @override
  String dashboardPercentSpoken(int pct) {
    return '$pct percent';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSecuritySection => 'Security';

  @override
  String get settingsAutoLogoutTitle => 'Auto sign-out';

  @override
  String get settingsAutoLogoutLoading => 'Loading…';

  @override
  String get settingsAutoLogoutLoadError => 'Could not load setting.';

  @override
  String settingsAutoLogoutValue(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesString minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String settingsAutoLogoutSliderLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsAutoLogoutDescription =>
      'After this many minutes without interaction you\'ll be signed out. When the app goes into the background that happens immediately, regardless of the value.';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsDeleteAccountTitle => 'Delete account and all data';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Irreversible. Resets the app to its initial state.';

  @override
  String get settingsAboutSection => 'About';

  @override
  String settingsAboutAppTitle(String appName) {
    return 'About $appName';
  }

  @override
  String get settingsAboutSubtitle => 'Local, privacy-first, no cloud.';

  @override
  String get settingsAboutLegalese =>
      'All data stays local on this device. AES-256 encrypted database. Access via biometrics / device PIN.';

  @override
  String get settingsLicensesTitle => 'Open-source licenses';

  @override
  String get settingsBiometricsTitle => 'Biometrics / device PIN';

  @override
  String get settingsBiometricsChecking => 'Checking…';

  @override
  String get settingsBiometricsActive =>
      'Active. Only biometrics or the device PIN unlock the app.';

  @override
  String get settingsBiometricsNone =>
      'Biometrics are not set up on this device. Please check your system settings.';

  @override
  String get settingsResetSnack => 'Account and all data deleted.';

  @override
  String get settingsResetError => 'Reset failed.';

  @override
  String get settingsResetTitle => 'Really delete everything?';

  @override
  String get settingsResetBody =>
      'Account, all categories, budgets and expenses will be removed permanently. There is no backup.';

  @override
  String get settingsResetConfirmCheck => 'I understand this cannot be undone.';

  @override
  String get settingsResetConfirmAction => 'Delete permanently';

  @override
  String get budgetTitle => 'Budgets';

  @override
  String get budgetTotal => 'Total budget';

  @override
  String get budgetSaveDialogTitle => 'Save budgets?';

  @override
  String budgetSaveDialogBody(String amount) {
    return 'New total budget: $amount';
  }

  @override
  String get budgetSaveButton => 'Save budgets';

  @override
  String get budgetSavedSnack => 'Budgets saved.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmpty => 'No categories yet.';

  @override
  String get categoriesBadgeDefault => 'Default';

  @override
  String get categoriesBadgeHidden => 'Hidden';

  @override
  String categoriesDeleteTitle(String name) {
    return 'Remove \'$name\'?';
  }

  @override
  String get categoriesDeleteBodyDefault =>
      'Default categories are only hidden so your existing expenses stay correctly categorised. You can show them again later.';

  @override
  String get categoriesDeleteBodyCustom =>
      'The category will be deleted permanently. Existing expenses in this category will block the deletion.';

  @override
  String get categoryEditTitleEdit => 'Edit category';

  @override
  String get categoryEditTitleNew => 'New category';

  @override
  String get categoryEditNameLabel => 'Name';

  @override
  String get categoryEditNameRequired => 'Please enter a name.';

  @override
  String get categoryEditColorLabel => 'Color';

  @override
  String get categoryEditIconLabel => 'Icon';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsTrendTitle => 'Last 12 months trend';

  @override
  String get statsTopCategoriesTitle => 'Top categories';

  @override
  String get statsCategoryVsBudgetTitle => 'Category vs. budget';

  @override
  String get statsCurrentPeriod => 'Current period';

  @override
  String statsPreviousPeriod(String amount) {
    return 'Previous period: $amount';
  }

  @override
  String get statsDailyAverageTitle => 'Daily average';

  @override
  String get statsDailyAverageSubtitle => 'per day';

  @override
  String get statsNoDataInRange => 'No expenses in the selected period yet.';

  @override
  String get statsNoData => 'No data yet.';

  @override
  String get statsRest => 'Other';

  @override
  String get statsUnknown => 'Unknown';

  @override
  String get statsNoVisibleCategories => 'No visible categories.';

  @override
  String get statsCategoryUsageLabel => 'Category usage';

  @override
  String get statsMonthJan => 'Jan';

  @override
  String get statsMonthFeb => 'Feb';

  @override
  String get statsMonthMar => 'Mar';

  @override
  String get statsMonthApr => 'Apr';

  @override
  String get statsMonthMay => 'May';

  @override
  String get statsMonthJun => 'Jun';

  @override
  String get statsMonthJul => 'Jul';

  @override
  String get statsMonthAug => 'Aug';

  @override
  String get statsMonthSep => 'Sep';

  @override
  String get statsMonthOct => 'Oct';

  @override
  String get statsMonthNov => 'Nov';

  @override
  String get statsMonthDec => 'Dec';

  @override
  String get expensesListTitle => 'Expenses';

  @override
  String get expensesListEmpty => 'No expenses this month yet';

  @override
  String get expensesListEmptyHint => 'Tap \'New\' to add an expense.';

  @override
  String expensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String expenseItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get expenseDeleteTitle => 'Delete expense?';

  @override
  String expenseDeleteBody(String name, String amount) {
    return '$name ($amount) will be deleted permanently.';
  }

  @override
  String get expenseFormTitleEdit => 'Edit expense';

  @override
  String get expenseFormTitleReview => 'Review & save expense';

  @override
  String get expenseFormTitleNew => 'New expense';

  @override
  String get expenseFormSelectCategory => 'Please select a category.';

  @override
  String get expenseFormAmountGreaterZero => 'Amount must be greater than 0.';

  @override
  String expenseFormSaveError(String detail) {
    return 'Save failed: $detail';
  }

  @override
  String get expenseFormNoVisibleCategories =>
      'No visible categories. Please create one first.';

  @override
  String get expenseFormModeSection => 'Mode';

  @override
  String get expenseFormModeWithItems => 'With items';

  @override
  String get expenseFormModeOnlyTotal => 'Total only';

  @override
  String get expenseFormModeOnlyTotalHint =>
      'Items are not stored. Default category is \'Other\' – you can choose another one.';

  @override
  String get expenseFormGeneralSection => 'General';

  @override
  String get expenseFormMerchantLabel => 'Merchant';

  @override
  String get expenseFormMerchantHint => 'e.g. Rewe, Aldi';

  @override
  String get expenseFormCategoryLabel => 'Category';

  @override
  String get expenseFormDateLabel => 'Date';

  @override
  String get expenseFormAmountSection => 'Amount';

  @override
  String expenseFormItemsSum(String amount) {
    return 'From items: $amount';
  }

  @override
  String get expenseFormTotalLabel => 'Total';

  @override
  String get expenseFormTotalLabelOverridesItems =>
      'Total (overrides item sum)';

  @override
  String get expenseFormTotalValidation => 'Please enter an amount > 0';

  @override
  String get expenseFormItemsSection => 'Items (optional)';

  @override
  String get expenseFormItemsEmpty =>
      'No items captured. If you photograph the receipt, the OCR parser will fill these in automatically.';

  @override
  String get expenseFormItemHint => 'Item';

  @override
  String get expenseFormItemRemoveTooltip => 'Remove item';

  @override
  String get expenseFormNoteSection => 'Note (optional)';

  @override
  String get expenseFormNoteHint => 'e.g. weekly groceries';

  @override
  String get expenseFormCreateButton => 'Create expense';

  @override
  String get receiptScanTitle => 'Scan receipt';

  @override
  String get receiptScanOpeningCamera => 'Opening camera…';

  @override
  String get receiptScanOpeningGallery => 'Opening gallery…';

  @override
  String get receiptScanReading => 'Reading receipt…';

  @override
  String receiptScanLowConfidence(int pct, String total) {
    return 'Recognition uncertain ($pct %). Please verify values. Total: $total';
  }

  @override
  String get receiptScanFailed =>
      'Receipt could not be read. Please try again.';

  @override
  String get receiptScanPrivacyTitle => 'Privacy first';

  @override
  String get receiptScanPrivacyBody =>
      'The image stays on your device. It is contrast-enhanced locally, then OCR runs on-device. Right after parsing the photo is deleted.';

  @override
  String get receiptScanCamera => 'Take photo';

  @override
  String get receiptScanGallery => 'Pick from gallery';
}
