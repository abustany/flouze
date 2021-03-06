///
//  Generated code. Do not modify.
//  source: bindings.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const AccountList$json = const {
  '1': 'AccountList',
  '2': const [
    const {'1': 'accounts', '3': 1, '4': 3, '5': 11, '6': '.flouze.model.Account', '10': 'accounts'},
  ],
};

const TransactionList$json = const {
  '1': 'TransactionList',
  '2': const [
    const {'1': 'transactions', '3': 1, '4': 3, '5': 11, '6': '.flouze.model.Transaction', '10': 'transactions'},
  ],
};

const Balance$json = const {
  '1': 'Balance',
  '2': const [
    const {'1': 'entries', '3': 1, '4': 3, '5': 11, '6': '.flouze_flutter.Balance.Entry', '10': 'entries'},
  ],
  '3': const [Balance_Entry$json],
};

const Balance_Entry$json = const {
  '1': 'Entry',
  '2': const [
    const {'1': 'person', '3': 1, '4': 1, '5': 12, '10': 'person'},
    const {'1': 'balance', '3': 2, '4': 1, '5': 3, '10': 'balance'},
  ],
};

const Transfer$json = const {
  '1': 'Transfer',
  '2': const [
    const {'1': 'debitor', '3': 1, '4': 1, '5': 12, '10': 'debitor'},
    const {'1': 'creditor', '3': 2, '4': 1, '5': 12, '10': 'creditor'},
    const {'1': 'amount', '3': 3, '4': 1, '5': 3, '10': 'amount'},
  ],
};

const Transfers$json = const {
  '1': 'Transfers',
  '2': const [
    const {'1': 'transfers', '3': 1, '4': 3, '5': 11, '6': '.flouze_flutter.Transfer', '10': 'transfers'},
  ],
};

