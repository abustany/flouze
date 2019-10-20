///
//  Generated code. Do not modify.
//  source: flouze.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const PayedBy$json = const {
  '1': 'PayedBy',
  '2': const [
    const {'1': 'person', '3': 1, '4': 1, '5': 12, '10': 'person'},
    const {'1': 'amount', '3': 2, '4': 1, '5': 13, '10': 'amount'},
  ],
};

const PayedFor$json = const {
  '1': 'PayedFor',
  '2': const [
    const {'1': 'person', '3': 1, '4': 1, '5': 12, '10': 'person'},
    const {'1': 'amount', '3': 2, '4': 1, '5': 13, '10': 'amount'},
  ],
};

const Transaction$json = const {
  '1': 'Transaction',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 12, '10': 'uuid'},
    const {'1': 'parent', '3': 2, '4': 1, '5': 12, '10': 'parent'},
    const {'1': 'amount', '3': 3, '4': 1, '5': 13, '10': 'amount'},
    const {'1': 'payed_by', '3': 4, '4': 3, '5': 11, '6': '.flouze.model.PayedBy', '10': 'payedBy'},
    const {'1': 'payed_for', '3': 5, '4': 3, '5': 11, '6': '.flouze.model.PayedFor', '10': 'payedFor'},
    const {'1': 'label', '3': 6, '4': 1, '5': 9, '10': 'label'},
    const {'1': 'timestamp', '3': 7, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'deleted', '3': 8, '4': 1, '5': 8, '10': 'deleted'},
    const {'1': 'replaces', '3': 9, '4': 1, '5': 12, '10': 'replaces'},
  ],
};

const Person$json = const {
  '1': 'Person',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 12, '10': 'uuid'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

const Account$json = const {
  '1': 'Account',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 12, '10': 'uuid'},
    const {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    const {'1': 'latest_transaction', '3': 3, '4': 1, '5': 12, '10': 'latestTransaction'},
    const {'1': 'latest_synchronized_transaction', '3': 4, '4': 1, '5': 12, '10': 'latestSynchronizedTransaction'},
    const {'1': 'members', '3': 5, '4': 3, '5': 11, '6': '.flouze.model.Person', '10': 'members'},
  ],
};

