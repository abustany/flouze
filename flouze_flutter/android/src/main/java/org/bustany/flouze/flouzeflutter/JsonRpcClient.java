package org.bustany.flouze.flouzeflutter;

class JsonRpcClient {
    public static native long create(String url);
    public static native void createAccount(long ptr, byte[] account);

    // We don't need any other functions for now, since we use the higher level Sync API
}
