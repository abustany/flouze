import 'package:collection/collection.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

final Function _listEquality = ListEquality().equals;

class ComparableTxId {
  final List<int> data;

  ComparableTxId(this.data);

  @override
  bool operator ==(other) {
    return _listEquality(data, other.data);
  }

  @override
  int get hashCode {
    int hash = 5381;
    data.forEach((i) { hash = (hash << 5) + hash + i; });
    return hash;
  }
}

List<Transaction> flattenHistory(List<Transaction> transactions) {
  Set<ComparableTxId> seenTransactions = Set();

  return transactions.where((tx) {
    if (tx.replaces != null && tx.replaces.isNotEmpty) {
      seenTransactions.add(ComparableTxId(tx.replaces));
    }

    return !(seenTransactions.contains(ComparableTxId(tx.uuid)) || tx.deleted);
  }).toList()..sort((tx1, tx2) => tx2.timestamp.compareTo(tx1.timestamp));
}

bool transactionHasId(Transaction transaction, List<int> id) =>
    _listEquality(transaction?.uuid, id);