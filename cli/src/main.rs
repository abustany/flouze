#[macro_use]
extern crate error_chain;
extern crate rand;
extern crate structopt;
#[macro_use]
extern crate structopt_derive;

extern crate flouze;

use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

use rand::Rng;

use structopt::StructOpt;

use flouze::model;
use flouze::repository::{Repository, get_transaction_chain};
use flouze::sledrepository::SledRepository;

mod errors {
    error_chain! {
        links {
            Lib(::flouze::errors::Error, ::flouze::errors::ErrorKind);
        }
    }
}

use errors::*;

#[derive(StructOpt)]
enum Command {
    #[structopt(name="add-account")]
    /// Create a new account
    AddAccount {
        /// Name of the account
        label: String,
        /// List of members of this account
        members: Vec<String>,
    },
    #[structopt(name="list-accounts")]
    /// List all accounts in the file
    ListAccounts,
    #[structopt(name="delete-account")]
    /// Delete an existing account and all its transactions
    DeleteAccount {
        /// Name of the account
        label: String
    },

    #[structopt(name="add-transaction")]
    /// Add a new transaction into an account
    AddTransaction {
        account_name: String,
        label: String,
        amount: u32,
        payed_by: String,
    },

    #[structopt(name="list-transactions")]
    /// List the transactions in an account
    ListTransactions {
        account_name: String,
    }
}

#[derive(StructOpt)]
#[structopt(name="flouze-cli", author="Adrien Bustany <adrien@bustany.org>", about="CLI to access flouze accounts", version="0.1")]
struct App {
    /// Path to the flouze file
    file: String,
    #[structopt(subcommand)]
    command: Command,
}

fn find_account_by_label<T: Repository>(store: &T, label: &str) -> Result<Option<model::Account>> {
    Ok(store.list_accounts()?.into_iter().find(|a| a.label == label))
}

fn find_member_by_name(members: &[model::Person], name: &str) -> Option<model::AccountId> {
    members.iter().find(|m| m.name == name).map(|m| m.uuid.to_owned())
}

fn split_amount(amount: u32, n: usize) -> Vec<u32> {
    assert!(n > 0, "The amount must be split in at least once part");

    let slice = ((amount as usize)/n) as u32;
    let mut res = vec![slice; n];
    let missing = amount - (((slice as usize) * n) as u32);

    for i in 0..missing {
        res[i as usize % n] += 1;
    }

    res
}

fn seq_shuffle<T>(items: &mut [T]) {
    let mut rng = rand::thread_rng();

    for i in (1..items.len()).rev() {
        let j = rng.gen_range(0, 1+i);
        items.swap(i, j);
    }
}

fn run() -> Result<()> {
    let opt = App::from_args();
    let mut store = SledRepository::new(&opt.file)?;
    
    match opt.command {
        Command::AddAccount{label, members} => {
            if members.len() == 0 {
                bail!("We need at least one member in the account");
            }

            // Check if we have any existing with the same name as a safe-guard
            if find_account_by_label(&store, &label)?.is_some() {
                bail!("An account with this name already exists");
            }

            let account = model::Account{
                uuid: model::generate_account_id(),
                label: label,
                latest_transaction: vec!(),
                members: members.into_iter().map(|name| model::Person{
                    uuid: model::generate_person_id(),
                    name: name,
                }).collect(),
            };

            store.add_account(&account).map_err(|e| e.into())
        },
        Command::ListAccounts => {
            for account in store.list_accounts()? {
                let member_names = account.members.iter().map(|m| m.name.as_str()).collect::<Vec<&str>>().join(", ");
                println!("{} (members: {})", &account.label, member_names);
            }

            Ok(())
        },
        Command::DeleteAccount{label} => {
            let account = find_account_by_label(&store, &label)?;

            if account.is_none() {
                bail!("No such account in the file");
            }

            store.delete_account(&account.unwrap().uuid).map_err(|e| e.into())
        }

        Command::AddTransaction{account_name, label, amount, payed_by} => {
            let account = find_account_by_label(&store, &account_name)?;

            if account.is_none() {
                bail!("No such account in the file");
            }

            let account = account.unwrap();

            let member = find_member_by_name(&account.members, &payed_by);

            if member.is_none() {
                bail!("Couldn't find a member with this name in the account")
            }

            let member = member.unwrap();
            let mut amounts = split_amount(amount, account.members.len());

            // Shuffle the sequence for fairness
            seq_shuffle(&mut amounts);

            let payed_for = amounts.iter()
                .zip(&account.members)
                .map(|(amount, member)| model::PayedFor{
                    person: member.uuid.to_owned(),
                    amount: amount.to_owned(),
                })
                .collect();
            let timestamp = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();

            let tx = model::Transaction{
                uuid: model::generate_transaction_id(),
                parent: vec!(),
                amount: amount,
                payed_by: vec!(model::PayedBy{
                    person: member,
                    amount: amount,
                }),
                payed_for: payed_for,
                label: label,
                timestamp: timestamp,
                deleted: false,
                replaces: vec!(),
            };

            store.add_transaction(&account.uuid, &tx)?;
            store.set_latest_transaction(&account.uuid, &tx.uuid).map_err(|e| e.into())
        }

        Command::ListTransactions{account_name} => {
            let account = find_account_by_label(&store, &account_name)?;

            if account.is_none() {
                bail!("No such account in the file");
            }

            let account = account.unwrap();

            let persons: HashMap<&model::PersonId, &str> = account.members.iter().map(|p| (&p.uuid, p.name.as_str())).collect();

            for tx in get_transaction_chain(&store, &account) {
                if tx.is_err() {
                    bail!("Error while fetching transactions");
                }

                let tx = tx.unwrap();

                let payed_by = match tx.payed_by.len() {
                    0 => "noone?",
                    1 => persons.get(&tx.payed_by[0].person).unwrap_or(&"someone unknown"),
                    _ => "many people",
                };

                println!("{}: {} (payed by {})", tx.label, tx.amount, payed_by);
            }

            Ok(())
        }
    }
}

fn main() {
    if let Err(ref e) = run() {
        println!("error: {}", e);

        for e in e.iter().skip(1) {
            println!("caused by: {}", e);
        }

        if let Some(backtrace) = e.backtrace() {
            println!("backtrace: {:?}", backtrace);
        }

        ::std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::split_amount;

    #[test]
    fn test_split_amount() {
        assert_eq!(split_amount(0, 2), vec!(0, 0));
        assert_eq!(split_amount(1, 2), vec!(1, 0));
        assert_eq!(split_amount(2, 2), vec!(1, 1));
        assert_eq!(split_amount(3, 2), vec!(2, 1));
        assert_eq!(split_amount(4, 2), vec!(2, 2));
        assert_eq!(split_amount(4, 1), vec!(4));
        assert_eq!(split_amount(8, 5), vec!(2, 2, 2, 1, 1));
    }
}
