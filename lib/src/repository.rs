use std::collections::HashMap;

use super::errors;
use super::model;

pub trait Repository {
    fn add_account(&mut self, account: &model::Account) -> errors::Result<()>;
    fn get_account(&self, account_id: &model::AccountId) -> errors::Result<model::Account>;
    fn delete_account(&mut self, account_id: &model::AccountId) -> errors::Result<()>;
    fn list_accounts(&self) -> errors::Result<Vec<model::Account>>;
    fn set_latest_transaction(
        &mut self,
        account_id: &model::AccountId,
        tx_id: &model::TransactionId,
    ) -> errors::Result<()>;
    fn set_latest_synchronized_transaction(
        &mut self,
        account_id: &model::AccountId,
        tx_id: &model::TransactionId,
    ) -> errors::Result<()>;

    fn add_transaction(
        &mut self,
        account_uuid: &model::AccountId,
        transaction: &model::Transaction,
    ) -> errors::Result<()>;
    fn get_transaction(
        &self,
        account_uuid: &model::AccountId,
        transaction_id: &model::TransactionId,
    ) -> errors::Result<model::Transaction>;
    fn delete_transaction(
        &mut self,
        account_uuid: &model::AccountId,
        transaction_id: &model::TransactionId,
    ) -> errors::Result<()>;
    fn flush(&mut self) -> errors::Result<()>;
}

pub struct TransactionChain<'a> {
    repo: &'a dyn Repository,
    account_id: model::AccountId,
    id: model::TransactionId,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Transfer {
    pub debitor: model::PersonId,
    pub creditor: model::PersonId,
    pub amount: i64,
}

impl<'a> TransactionChain<'a> {
    fn new(
        repo: &'a dyn Repository,
        account_id: &model::AccountId,
        id: &model::TransactionId,
    ) -> TransactionChain<'a> {
        TransactionChain {
            repo,
            account_id: account_id.to_owned(),
            id: id.to_owned(),
        }
    }
}

impl<'a> Iterator for TransactionChain<'a> {
    type Item = errors::Result<model::Transaction>;

    fn next(&mut self) -> Option<errors::Result<model::Transaction>> {
        if self.id.is_empty() {
            return None;
        }

        let tx = match self.repo.get_transaction(&self.account_id, &self.id) {
            Err(e) => {
                return Some(Err(e));
            }
            Ok(tx) => tx,
        };

        self.id = tx.parent.to_owned();

        Some(Ok(tx))
    }
}

pub fn get_transaction_chain<'a>(
    repo: &'a dyn Repository,
    account: &model::Account,
) -> TransactionChain<'a> {
    TransactionChain::new(repo, &account.uuid, &account.latest_transaction)
}

pub fn check_chain_consistency(transactions: &[&model::Transaction]) -> bool {
    if transactions.is_empty() {
        return true;
    }

    let mut base = &transactions[0].parent;

    for tx in transactions {
        if &tx.parent != base {
            return false;
        }

        base = &tx.uuid;
    }

    true
}

fn update_balance(
    balance: &mut HashMap<model::PersonId, i64>,
    payed_by: &[model::PayedBy],
    payed_for: &[model::PayedFor],
    factor: i64,
) {
    for p in payed_by {
        if let Some(b) = balance.get_mut(&p.person) {
            *b += i64::from(p.amount) * factor;
        }
    }

    for p in payed_for {
        if let Some(b) = balance.get_mut(&p.person) {
            *b -= i64::from(p.amount) * factor;
        }
    }
}

fn get_first_non_deleted_ancestor(
    repo: &dyn Repository,
    account: &model::Account,
    deleted: model::Transaction,
) -> errors::Result<model::Transaction> {
    let mut cur = deleted;

    loop {
        if cur.replaces.is_empty() {
            return Err(errors::ErrorKind::NoSuchTransaction(cur.replaces.clone()).into());
        }

        cur = repo.get_transaction(&account.uuid, &cur.replaces)?;

        if !cur.deleted {
            break;
        }
    }

    Ok(cur)
}

pub fn get_balance(
    repo: &dyn Repository,
    account: &model::Account,
) -> errors::Result<HashMap<model::PersonId, i64>> {
    let mut balance: HashMap<model::PersonId, i64> = account
        .members
        .iter()
        .map(|m| (m.uuid.clone(), 0))
        .collect();
    let chain = get_transaction_chain(repo, account);

    for tx in chain {
        let tx = tx?;

        if !tx.replaces.is_empty() || tx.deleted {
            if !tx.deleted {
                update_balance(&mut balance, &tx.payed_by, &tx.payed_for, 1);
            }

            let original = get_first_non_deleted_ancestor(repo, account, tx)?;
            update_balance(&mut balance, &original.payed_by, &original.payed_for, -1);
        } else {
            update_balance(&mut balance, &tx.payed_by, &tx.payed_for, 1);
        }
    }

    Ok(balance)
}

fn is_solution_better(candidate: &Vec<Transfer>, existing: &Vec<Transfer>) -> bool {
    candidate.len() < existing.len()
}

fn get_transfers_helper<S: Clone + ::std::hash::BuildHasher>(
    solution: &mut Option<Vec<Transfer>>,
    balance: &HashMap<model::PersonId, i64, S>,
    transfers: &mut Vec<Transfer>,
) {
    let (creditor, credit) = match balance.iter().find(|&(_, amount)| *amount > 0) {
        // Someone still needs to get reimbursed
        Some(x) => x,
        // No more creditors, we're done!
        None => {
            if solution.is_none() || is_solution_better(transfers, solution.as_ref().unwrap()) {
                *solution = Some(transfers.to_owned());
            }

            return;
        }
    };

    // Don't try to find a new transfer for a solution that is already as long
    // as the best one
    if let Some(solution) = solution {
        if transfers.len() >= solution.len() {
            return;
        }
    }

    for (debitor, debit) in balance.iter().filter(|&(_, amount)| *amount < 0) {
        let transfer_amount = i64::min(*credit, -debit);
        let transfer = Transfer {
            debitor: debitor.to_owned(),
            creditor: creditor.to_owned(),
            amount: transfer_amount,
        };

        let mut new_balance = HashMap::clone(balance);
        new_balance
            .entry(transfer.creditor.to_owned())
            .and_modify(|b| *b -= transfer.amount);
        new_balance
            .entry(transfer.debitor.to_owned())
            .and_modify(|b| *b += transfer.amount);

        transfers.push(transfer);
        get_transfers_helper(solution, &new_balance, transfers);
        transfers.pop();
    }
}

pub fn get_transfers<S: Clone + ::std::hash::BuildHasher>(
    balance: &HashMap<model::PersonId, i64, S>,
) -> Vec<Transfer> {
    let mut solution: Option<Vec<Transfer>> = None;
    get_transfers_helper(&mut solution, balance, &mut vec![]);
    solution.unwrap()
}

pub fn receive_transactions(
    repo: &mut dyn Repository,
    account_id: &model::AccountId,
    transactions: &[&model::Transaction],
) -> errors::Result<()> {
    let account = repo.get_account(account_id)?;

    if transactions.is_empty() {
        return Ok(());
    }

    if account.latest_transaction != transactions[0].parent {
        return Err(errors::ErrorKind::MustRebase.into());
    }

    if !check_chain_consistency(transactions) {
        return Err(errors::ErrorKind::InconsistentChain.into());
    }

    for tx in transactions {
        repo.add_transaction(&account.uuid, &model::Transaction::clone(tx))?;
    }

    repo.set_latest_transaction(&account.uuid, &transactions.last().unwrap().uuid)?;

    Ok(())
}

pub fn get_child_transactions(
    repo: &dyn Repository,
    account_id: &model::AccountId,
    base: &model::TransactionId,
) -> errors::Result<Vec<model::Transaction>> {
    // Check that the base transaction ID is valid, else we'll get a
    // NoSuchTransaction error.
    if !base.is_empty() {
        repo.get_transaction(account_id, base)?;
    }

    let account = repo.get_account(account_id)?;
    let mut transactions: Vec<model::Transaction> = Vec::new();

    for tx in get_transaction_chain(repo, &account) {
        let tx = tx?;

        if &tx.uuid == base {
            break;
        }

        transactions.push(tx);
    }

    // Put the oldest transaction first
    transactions.reverse();

    Ok(transactions)
}

#[macro_use]
pub mod testmacros {
    #[macro_export]
    macro_rules! repository_test {
        ($name: ident, $factory: expr) => {
            #[test]
            fn $name() {
                let mut repo = $factory();

                use repository::tests;
                tests::$name(&mut repo);
            }
        };
    }

    #[macro_export]
    macro_rules! repository_tests {
        ($factory: expr) => {
            ::repository_test!(test_account_crud, $factory);
            ::repository_test!(test_transaction_insert, $factory);
            ::repository_test!(test_transaction_chain, $factory);
            ::repository_test!(test_balance, $factory);
        };
    }
}

#[cfg(test)]
pub mod tests {
    use std::fmt::Debug;

    use super::*;

    pub fn expect_no_such_account<T: Debug>(r: errors::Result<T>) {
        match r {
            Err(errors::Error(errors::ErrorKind::NoSuchAccount(_), _)) => {}
            _ => {
                panic!("Expected NoSuchAccount error, got {:?}", r);
            }
        }
    }

    pub fn expect_no_such_transaction<T: Debug>(r: errors::Result<T>) {
        match r {
            Err(errors::Error(errors::ErrorKind::NoSuchTransaction(_), _)) => {}
            _ => {
                panic!("Expected NoSuchTransaction error, got {:?}", r);
            }
        }
    }

    pub fn make_test_account() -> model::Account {
        model::Account {
            uuid: model::generate_account_id(),
            label: "Test account".to_owned(),
            latest_transaction: vec![],
            latest_synchronized_transaction: vec![],
            members: vec![
                model::Person {
                    uuid: model::generate_person_id(),
                    name: "Member 1".to_owned(),
                },
                model::Person {
                    uuid: model::generate_person_id(),
                    name: "Member 2".to_owned(),
                },
            ],
        }
    }

    pub fn make_test_transaction_1(account: &model::Account) -> model::Transaction {
        model::Transaction {
            uuid: model::generate_transaction_id(),
            parent: vec![],
            amount: 35,
            payed_by: vec![model::PayedBy {
                person: account.members[0].uuid.to_owned(),
                amount: 35,
            }],
            payed_for: vec![
                model::PayedFor {
                    person: account.members[0].uuid.to_owned(),
                    amount: 17,
                },
                model::PayedFor {
                    person: account.members[1].uuid.to_owned(),
                    amount: 18,
                },
            ],
            label: "Fish & Chips".to_owned(),
            timestamp: 1530288593,
            deleted: false,
            replaces: vec![],
        }
    }

    pub fn make_test_transaction_2(
        account: &model::Account,
        parent: &model::TransactionId,
    ) -> model::Transaction {
        model::Transaction {
            uuid: model::generate_transaction_id(),
            parent: parent.to_owned(),
            amount: 10,
            payed_by: vec![model::PayedBy {
                person: account.members[1].uuid.to_owned(),
                amount: 10,
            }],
            payed_for: vec![model::PayedFor {
                person: account.members[0].uuid.to_owned(),
                amount: 10,
            }],
            label: "Book".to_owned(),
            timestamp: 1530289903,
            deleted: false,
            replaces: vec![],
        }
    }

    pub fn make_test_transaction_3(parent: &model::TransactionId) -> model::Transaction {
        model::Transaction {
            uuid: model::generate_transaction_id(),
            parent: parent.to_owned(),
            amount: 0,
            payed_by: vec![],
            payed_for: vec![],
            label: "TX".to_owned(),
            timestamp: 0,
            deleted: false,
            replaces: vec![],
        }
    }

    pub fn test_account_crud(repo: &mut dyn Repository) {
        let account = make_test_account();

        expect_no_such_account(repo.get_account(&account.uuid));
        assert_eq!(repo.list_accounts().unwrap(), vec!());
        repo.add_account(&account).unwrap();

        let mut fetched = repo.get_account(&account.uuid).unwrap();
        assert_eq!(fetched, account);
        assert_eq!(repo.list_accounts().unwrap(), vec!(account.clone()));

        fetched.label = "New fancy name".to_owned();
        repo.add_account(&fetched).unwrap();

        let fetched2 = repo.get_account(&account.uuid).unwrap();
        assert_eq!(fetched2, fetched);

        expect_no_such_account(repo.delete_account(&model::generate_account_id()));
        repo.delete_account(&account.uuid).unwrap();
        expect_no_such_account(repo.delete_account(&account.uuid));
        expect_no_such_account(repo.get_account(&account.uuid));
    }

    pub fn test_transaction_insert(repo: &mut dyn Repository) {
        let account = make_test_account();
        repo.add_account(&account).unwrap();

        let tx = make_test_transaction_1(&account);

        expect_no_such_transaction(repo.get_transaction(&account.uuid, &tx.uuid));
        repo.add_transaction(&account.uuid, &tx).unwrap();

        let mut fetched = repo.get_transaction(&account.uuid, &tx.uuid).unwrap();
        assert_eq!(fetched, tx);

        fetched.timestamp = 1530289104;
        repo.add_transaction(&account.uuid, &fetched).unwrap();

        let fetched2 = repo.get_transaction(&account.uuid, &tx.uuid).unwrap();
        assert_eq!(fetched2, fetched);
    }

    pub fn test_transaction_chain(repo: &mut dyn Repository) {
        let mut account = make_test_account();
        repo.add_account(&account).unwrap();

        {
            let mut chain = get_transaction_chain(repo, &account);
            assert!(chain.next().is_none());
        }

        let tx1 = make_test_transaction_1(&account);

        {
            repo.add_transaction(&account.uuid, &tx1).unwrap();
            account.latest_transaction = tx1.uuid.to_owned();

            let mut chain = get_transaction_chain(repo, &account);
            assert_eq!(chain.next().unwrap().unwrap(), tx1);
            assert!(chain.next().is_none());
        }

        let tx2 = make_test_transaction_2(&account, &tx1.uuid);

        {
            repo.add_transaction(&account.uuid, &tx2).unwrap();
            account.latest_transaction = tx2.uuid.to_owned();

            let mut chain = get_transaction_chain(repo, &account);
            assert_eq!(chain.next().unwrap().unwrap(), tx2);
            assert_eq!(chain.next().unwrap().unwrap(), tx1);
            assert!(chain.next().is_none());
        }
    }

    #[test]
    fn test_check_chain_consistency() {
        let account = make_test_account();
        let tx1 = make_test_transaction_1(&account);
        let tx2 = make_test_transaction_2(&account, &tx1.uuid);
        let tx3 = make_test_transaction_3(&tx2.uuid);

        assert_eq!(check_chain_consistency(&vec!()), true);
        assert_eq!(check_chain_consistency(&vec!(&tx1, &tx2, &tx3)), true);
        assert_eq!(check_chain_consistency(&vec!(&tx2, &tx3)), true);
        assert_eq!(check_chain_consistency(&vec!(&tx1)), true);
        assert_eq!(check_chain_consistency(&vec!(&tx1, &tx3)), false);
    }

    pub fn test_balance(repo: &mut dyn Repository) {
        let mut account = make_test_account();
        let tx1 = make_test_transaction_1(&account);
        let tx2 = make_test_transaction_2(&account, &tx1.uuid);

        repo.add_account(&account).unwrap();
        repo.add_transaction(&account.uuid, &tx1).unwrap();
        repo.add_transaction(&account.uuid, &tx2).unwrap();
        account.latest_transaction = tx2.uuid.to_owned();

        let balance = get_balance(repo, &account).unwrap();
        assert_eq!(balance.get(&account.members[0].uuid).unwrap(), &8);
        assert_eq!(balance.get(&account.members[1].uuid).unwrap(), &-8);

        let mut tx1_edit = tx1.clone();
        tx1_edit.uuid = model::generate_transaction_id();
        tx1_edit.parent = tx2.uuid.clone();
        tx1_edit.amount = 25;
        tx1_edit.payed_by[0].amount = 25;
        tx1_edit.payed_for[0].amount = 12;
        tx1_edit.payed_for[1].amount = 13;
        tx1_edit.replaces = tx1.uuid.clone();
        repo.add_transaction(&account.uuid, &tx1_edit).unwrap();
        account.latest_transaction = tx1_edit.uuid.to_owned();

        let balance = get_balance(repo, &account).unwrap();
        assert_eq!(balance.get(&account.members[0].uuid).unwrap(), &3);
        assert_eq!(balance.get(&account.members[1].uuid).unwrap(), &-3);
    }

    fn sort_transfers(transfers: &mut [Transfer]) {
        transfers.sort_unstable_by(|a, b| {
            a.creditor
                .cmp(&b.creditor)
                .then_with(|| a.debitor.cmp(&b.debitor))
                .then_with(|| a.amount.cmp(&b.amount))
        })
    }

    #[test]
    pub fn test_get_transfers_trivial() {
        let person_1: model::PersonId = vec![0x01];
        let person_2: model::PersonId = vec![0x02];
        let person_3: model::PersonId = vec![0x03];

        let mut balance: HashMap<model::PersonId, i64> = HashMap::new();
        balance.insert(person_1.clone(), 5);
        balance.insert(person_2.clone(), -5);

        let transfers = get_transfers(&balance);
        let expected_transfer = Transfer {
            debitor: person_2.clone(),
            creditor: person_1.clone(),
            amount: 5,
        };

        assert_eq!(transfers.len(), 1);
        assert_eq!(transfers[0], expected_transfer);

        balance.clear();
        balance.insert(person_1.clone(), 5);
        balance.insert(person_2.clone(), -3);
        balance.insert(person_3.clone(), -2);

        let mut transfers = get_transfers(&balance);
        sort_transfers(&mut transfers);
        assert_eq!(transfers.len(), 2);
        assert_eq!(
            transfers[0],
            Transfer {
                debitor: person_2.clone(),
                creditor: person_1.clone(),
                amount: 3,
            }
        );
        assert_eq!(
            transfers[1],
            Transfer {
                debitor: person_3.clone(),
                creditor: person_1.clone(),
                amount: 2,
            }
        );
    }

    pub fn test_get_transfers_less_trivial_i() {
        let persons: Vec<model::PersonId> = vec![
            vec![0x01],
            vec![0x02],
            vec![0x03],
            vec![0x04],
            vec![0x05],
            vec![0x06],
        ];

        let mut balance: HashMap<model::PersonId, i64> = HashMap::new();
        balance.insert(persons[0].clone(), 1);
        balance.insert(persons[1].clone(), 2);
        balance.insert(persons[2].clone(), 3);
        balance.insert(persons[3].clone(), -1);
        balance.insert(persons[4].clone(), -2);
        balance.insert(persons[5].clone(), -3);

        let mut transfers = get_transfers(&balance);
        sort_transfers(&mut transfers);
        assert_eq!(transfers.len(), 3);
        assert_eq!(
            transfers[0],
            Transfer {
                debitor: persons[3].clone(),
                creditor: persons[0].clone(),
                amount: 1,
            }
        );
        assert_eq!(
            transfers[1],
            Transfer {
                debitor: persons[4].clone(),
                creditor: persons[1].clone(),
                amount: 2,
            }
        );
        assert_eq!(
            transfers[2],
            Transfer {
                debitor: persons[5].clone(),
                creditor: persons[2].clone(),
                amount: 3,
            }
        );
    }

    #[test]
    pub fn test_get_transfers_less_trivial() {
        // We repeat the tests several times since HashMap's iteration order is
        // undefined, so a stupid algorithm might be "lucky" and find the best
        // solution just because the entries were iterated in a particular
        // order.
        for _ in 0..100 {
            test_get_transfers_less_trivial_i();
        }
    }
}
