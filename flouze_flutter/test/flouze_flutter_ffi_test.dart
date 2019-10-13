import 'package:test/test.dart';
import 'package:flouze_flutter/flouze_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fixnum/fixnum.dart';

Uuid _uuid = new Uuid();

List<int> generateUuid() {
  List<int> res = List.filled(16, 0);
  _uuid.v4buffer(res);
  return res;
}

Int64 timestampFromDate(DateTime dt) =>
    Int64(dt.millisecondsSinceEpoch~/1000);

Map<String, int> uuidMap(Map<List<int>, int> m) =>
  Map.fromEntries(m.entries.map((e) => MapEntry(_uuid.unparse(e.key), e.value)));

void main() {
  group('SledRepository', () {
    final member1 = Person.create()
      ..uuid = generateUuid()
      ..name = "Jane";
    final member2 = Person.create()
      ..uuid = generateUuid()
      ..name = "Bob";
    final account = Account.create()
      ..uuid = generateUuid()
      ..label = "Test account"
      ..members.addAll([member1, member2]);
    final Transaction tx1 = Transaction.create()
      ..uuid = generateUuid()
      ..label = "Books"
      ..amount = 10
      ..payedBy.add(PayedBy.create()
        ..person = member1.uuid
        ..amount = 10)
      ..payedFor.addAll([
        PayedFor.create()
          ..person = member1.uuid
          ..amount = 5,
        PayedFor.create()
          ..person = member2.uuid
          ..amount = 5,
      ])
      ..timestamp = timestampFromDate(DateTime.now());

    test('account list/add/delete', () async {
      final repo = SledRepository.temporary();
      expect(await repo.listAccounts(), equals(<Account>[]));
      await repo.addAccount(account);
      expect(await repo.listAccounts(), equals(<Account>[account]));
      await repo.deleteAccount(account.uuid);
      expect(await repo.listAccounts(), equals(<Account>[]));
      repo.destroy();
    });

    test('transaction list/add/delete', () async {
      final repo = SledRepository.temporary();
      await repo.addAccount(account);
      expect(await repo.listTransactions(account.uuid), equals(<Transaction>[]));
      await repo.addTransaction(account.uuid, tx1);
      expect(await repo.listTransactions(account.uuid), equals(<Transaction>[tx1]));
      repo.destroy();
    });

    test('balance', () async {
      final repo = SledRepository.temporary();
      await repo.addAccount(account);
      expect(uuidMap(await repo.getBalance(account.uuid)), equals(uuidMap({member2.uuid: 0, member1.uuid: 0})));
      await repo.addTransaction(account.uuid, tx1);
      expect(uuidMap(await repo.getBalance(account.uuid)), equals(uuidMap({member1.uuid: 5, member2.uuid: -5})));
      repo.destroy();
    });
  });
}