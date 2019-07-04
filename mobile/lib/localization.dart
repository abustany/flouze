import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/messages_all.dart';

class FlouzeLocalizations {
  static Future<FlouzeLocalizations> load(Locale locale) {
    final String name = (locale.countryCode == null || locale.countryCode.isEmpty) ?
      locale.languageCode
        : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return FlouzeLocalizations();
    });
  }

  static FlouzeLocalizations of(BuildContext context) {
    return Localizations.of<FlouzeLocalizations>(context, FlouzeLocalizations);
  }

  // AccountPage

  String get accountPageTransactionsTab => Intl.message(
    'Transactions',
    name: 'accountPageTransactionsTab',
    desc: 'Title of the "Transactions" tab on the account page',
  );

  String get accountPageBalanceTab => Intl.message(
    'Balance',
    name: 'accountPageBalanceTab',
    desc: 'Title of the "Balance" tab on the account page',
  );

  String get accountPageSynchronizedSuccessfullySnack => Intl.message(
    'Synchronized successfully!',
    name: 'accountPageSynchronizedSuccessfullySnack',
    desc: 'The snack shown after a synchronization succeeds',
  );

  String get accountPageDeleteDialogTitle => Intl.message(
    'Delete the account?',
    name: 'accountPageDeleteDialogTitle',
    desc: 'Title of the "Delete account" confirmation dialog',
  );

  String get accountPageDeleteDialogBody => Intl.message(
    'All transactions will be lost. This action cannot be undone.',
    name: 'accountPageDeleteDialogBody',
    desc: 'Body of the "Delete account" confirmation dialog',
  );

  String get accountPageDeleteDialogDeleteButton => Intl.message(
    'Delete the account',
    name: 'accountPageDeleteDialogDeleteButton',
    desc: 'Delete button label in "Delete account" confirmation dialog',
  );

  String get accountPageAddTransactionButtonTooltip => Intl.message(
    'Add a new transaction',
    name: 'accountPageAddTransactionButtonTooltip',
    desc: 'Tooltip of the "Add transaction" button',
  );

  String get accountPageSynchronizeButtonTooltip => Intl.message(
    'Synchronize account',
    name: 'accountPageSynchronizeButtonTooltip',
    desc: 'Tooltip of the "Synchronize" button',
  );

  String get accountPageShareButtonTooltip => Intl.message(
    'Share account',
    name: 'accountPageShareButtonTooltip',
    desc: 'Tooltip of the "Share" button',
  );

  String get accountPageDeleteActionLabel => Intl.message(
    'Delete account',
    name: 'accountPageDeleteActionLabel',
    desc: 'Label of the "Delete account" action',
  );

  String get accountPageEmptyStateText => Intl.message(
    'No transactions yet...',
    name: 'accountPageEmptyStateText',
    desc: 'Background text of the account page when there are no transactions',
  );

  String get accountPageErrorLoadingAccountConfig => Intl.message(
    'Error while loading account configuration',
    name: 'accountPageErrorLoadingAccountConfig',
    desc: 'Error prefix when loading the account configuration failed',
  );

  String get accountPageErrorSavingAccountConfig => Intl.message(
    'Error while saving account configuration',
    name: 'accountPageErrorSavingAccountConfig',
    desc: 'Error prefix when saving the account configuration failed',
  );

  String get accountPageErrorSharing => Intl.message(
    'Error while sharing account',
    name: 'accountPageErrorSharing',
    desc: 'Error prefix when sharing an account failed',
  );

  String get accountPageErrorSynchronizing => Intl.message(
    'Error while synchronizing account',
    name: 'accountPageErrorSynchronizing',
    desc: 'Error prefix when sychronizing an account failed',
  );

  // AccountClonePage

  String get accountClonePageLoading => Intl.message(
    'Retrieving remote account information...',
    name: 'accountClonePageLoading',
    desc: 'Text shown while retrieving remote account information',
  );

  String accountClonePageAccountAlreadyExists(String name) => Intl.message(
    'You already have the account "$name" on your device',
    name: 'accountClonePageAccountAlreadyExists',
    desc: 'Text shown when the account being imported is already present on the device',
    args: [name],
  );

  String accountClonePageReadyToImport(String name) => Intl.message(
    'Ready to import account "$name"',
    name: 'accountClonePageReadyToImport',
    desc: 'Text shown when the account is ready to be imported',
    args: [name],
  );

  String get accountClonePageImportButton => Intl.message(
    'Import',
    name: 'accountClonePageImportButton',
    desc: 'Label of the import button',
  );

  String accountClonePageImporting(String name) => Intl.message(
    'Importing account "$name"...',
    name: 'accountClonePageImporting',
    desc: 'Text shown while the account is importing',
    args: [name],
  );

  String get accountClonePageErrorPreparingImport => Intl.message(
    'Error while preparing import',
    name: 'accountClonePageErrorPreparingImport',
    desc: 'Error prefix when preparing the import failed',
  );

  String get accountClonePageErrorImport => Intl.message(
      'Error while importing',
      name: 'accountClonePageErrorImport',
      desc: 'Error prefix when the import failed',
  );

  // AccountListPage

  String get accountListPageAddAccountButtonTooltip => Intl.message(
    'Add a new account',
    name: 'accountListPageAddAccountButtonTooltip',
    desc: 'Tooltip of the "Add account" button',
  );

  String get accountListPageEmptyStateText => Intl.message(
    'Get started by creating a new account',
    name: 'accountListPageEmptyStateText',
    desc: 'Background text of the account list page when there are no accounts',
  );

  String get accountListPageErrorLoading => Intl.message(
    'Error while loading accounts',
    name: 'accountListPageErrorLoading',
    desc: 'Error prefix when loading the account list failed',
  );

  String get accountListPageErrorSaving => Intl.message(
    'Error while saving account',
    name: 'accountListPageErrorSaving',
    desc: 'Error prefix when saving an account failed',
  );

  // AddAccountPage

  String get addAccountPageTitle => Intl.message(
    'Create an account',
    name: 'addAccountPageTitle',
    desc: 'Title of the "Add account" page',
  );

  String get addAccountPageSaveAccountButtonTooltip => Intl.message(
    'Save the account',
    name: 'addAccountPageSaveAccountButtonTooltip',
    desc: 'Tooltip of the "Save account" button',
  );

  String get addAccountPageValidationErrorAccountNameEmpty => Intl.message(
    'Account name cannot be empty',
    name: 'addAccountPageValidationErrorAccountNameEmpty',
    desc: 'Validation error when an empty account name is given',
  );

  String get addAccountPageTitleLabel => Intl.message(
    'Title',
    name: 'addAccountPageTitleLabel',
    desc: 'Label of the account title field',
  );

  String get addAccountPageAccountOwnerLabel => Intl.message(
    'Your name',
    name: 'addAccountPageAccountOwnerLabel',
    desc: 'Label of the account owner field',
  );

  String get addAccountPageAddMemberButton => Intl.message(
    'Add member',
    name: 'addAccountPageAddMemberButton',
    desc: 'Label of the "Add member" button',
  );

  String get addAccountPageAccountMemberLabel => Intl.message(
    'Member name',
    name: 'addAccountPageAccountMemberLabel',
    desc: 'Label of an account member field',
  );

  // AddTransactionPage

  String get addTransactionPageTitle => Intl.message(
    'Add a transaction',
    name: 'addTransactionPageTitle',
    desc: 'Title of the "Add a transaction" page',
  );

  String get addTransactionPageDescriptionLabel => Intl.message(
    'Description',
    name: 'addTransactionPageDescriptionLabel',
    desc: 'Label of the description field',
  );

  String get addTransactionPageAmountLabel => Intl.message(
    'Amount',
    name: 'addTransactionPageAmountLabel',
    desc: 'Label of the amount field',
  );

  String get addTransactionPageDateLabel => Intl.message(
    'Date',
    name: 'addTransactionPageDateLabel',
    desc: 'Label of the date field',
  );

  String get addTransactionPagePayedByLabel => Intl.message(
    'Payed by',
    name: 'addTransactionPagePayedByLabel',
    desc: 'Label of the "Payed by" field',
  );

  String get addTransactionPagePayedForLabel => Intl.message(
    'Payed for',
    name: 'addTransactionPagePayedForLabel',
    desc: 'Label of the "Payed for" field',
  );

  String get addTransactionPageDeleteDialogTitle => Intl.message(
    'Delete the transaction?',
    name: 'addTransactionPageDeleteDialogTitle',
    desc: 'Title of the "Delete transaction" confirmation dialog',
  );


  String get addTransactionPageDeleteDialogDeleteButton => Intl.message(
    'Delete',
    name: 'addTransactionPageDeleteDialogDeleteButton',
    desc: 'Delete button label in "Delete transaction" confirmation dialog',
  );

  String get addTransactionPageSaveButtonTooltip => Intl.message(
    'Save the transaction',
    name: 'addTransactionPageSaveButtonTooltip',
    desc: 'Tooltip of the "Save transaction" button',
  );

  String get addTransactionPageValidationErrorDescriptionEmpty => Intl.message(
    'Description cannot be empty',
    name: 'addTransactionPageValidationErrorDescriptionEmpty',
    desc: 'Validation error when the description is empty',
  );

  String get addTransactionPageValidationErrorPayedByOneNoneSelected => Intl.message(
    'Please select the person who paid',
    name: 'addTransactionPageValidationErrorPayedByOneNoneSelected',
    desc: 'Validation error when no paying person was selected',
  );

  String get addTransactionPageValidationErrorPayedByManyAmountNotMatch => Intl.message(
    'Entered amounts do not match the total amount',
    name: 'addTransactionPageValidationErrorPayedByManyAmountNotMatch',
    desc: 'Validation error when the entered amounts don\'t match the total amount',
  );

  String get addTransactionPageValidationErrorPayedSplitEvenNoneSelected => Intl.message(
    'Please select at least one person',
    name: 'addTransactionPageValidationErrorPayedSplitEvenNoneSelected',
    desc: 'Validation error when no payed for person was selected',
  );

  String get addTransactionPageValidationErrorPayedForCustomAmountNotMatch => Intl.message(
    'Entered amounts do not match the total amount',
    name: 'addTransactionPageValidationErrorPayedForCustomAmountNotMatch',
    desc: 'Validation error when the entered amounts don\'t match the total amount',
  );

  // AmountField widget

  String get amountFieldValidationErrorAmountEmpty => Intl.message(
    'Amount cannot be empty',
    name: 'amountFieldValidationErrorAmountEmpty',
    desc: 'Validation error when an empty amount is given',
  );

  String get amountFieldValidationErrorAmountNotANumber => Intl.message(
    'Amount is not a valid number',
    name: 'amountFieldValidationErrorAmountNotANumber',
    desc: 'Validation error when an invalid amount is given',
  );

  String get amountFieldValidationErrorAmountZero => Intl.message(
    'Amount should be greater than 0',
    name: 'amountFieldValidationErrorAmountZero',
    desc: 'Validation error when a null amount is given',
  );

  // MemberEntryWidget

  String get memberEntryWidgetValidationErrorNameEmpty => Intl.message(
    'Member name cannot be empty',
    name: 'memberEntryWidgetValidationErrorNameEmpty',
    desc: 'Validation error when an empty member name is given',
  );

  // SimplePayedBy widget

  String get simplePayedBySplitButton => Intl.message(
    'Split...',
    name: 'simplePayedBySplitButton',
    desc: 'Label of the split button',
  );

  // SimplePayedFor widget

  String get simplePayedForAdvancedButton => Intl.message(
    'Advanced...',
    name: 'simplePayedForAdvancedButton',
    desc: 'Label of the advanced button',
  );

  // TransactionList

  String transactionListOnBy(String date, String who) =>
    Intl.message(
      'On $date by $who',
      name: 'transactionListOnBy',
      desc: 'Description line under the transaction title',
      args: [date, who],
    );

  // General strings

  String get confirmDialogCancelButton => Intl.message(
    'Cancel',
    name: 'confirmDialogCancelButton',
    desc: 'Cancel button label in confirmation dialogs',
  );
}

class FlouzeLocalizationsDelegate extends LocalizationsDelegate<FlouzeLocalizations> {
  const FlouzeLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<FlouzeLocalizations> load(Locale locale) => FlouzeLocalizations.load(locale);

  @override
  bool shouldReload(LocalizationsDelegate<FlouzeLocalizations> old) => false;
}