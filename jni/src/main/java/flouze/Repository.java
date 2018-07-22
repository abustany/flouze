package flouze;

import flouze.Model.Account;

interface Repository {
    void addAccount(Account account);
    Account getAccount(byte[] accountId);
}
