package org.bustany.flouze.flouzeflutter;

class SledRepository {
    public static native long temporary();
    public static native long fromFile(String path);
    public static native void destroy(long ptr);
    public static native void addAccount(long ptr, byte[] account);
    public static native void deleteAccount(long ptr, byte[] accountId);
    public static native byte[] getAccount(long ptr, byte[] accountId);
    public static native byte[] listAccounts(long ptr);
    public static native byte[] listTransactions(long ptr, byte[] accountId);
    public static native void addTransaction(long ptr, byte[] accountId, byte[] transaction);
}
