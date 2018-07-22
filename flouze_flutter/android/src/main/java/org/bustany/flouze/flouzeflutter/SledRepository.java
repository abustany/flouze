package org.bustany.flouze.flouzeflutter;

import java.util.List;

class SledRepository {
    public static native long temporary();
    public static native long fromFile(String path);
    public static native void destroy(long ptr);
    public static native void addAccount(long ptr, byte[] account);
    public static native byte[] getAccount(long ptr, byte[] accountId);
    public static native void listAccounts(long ptr, List<byte[]> accounts);
    public static native void listTransactions(long ptr, byte[] accountId, List<byte[]> transactions);
    public static native void addTransaction(long ptr, byte[] accountId, byte[] transaction);
}
