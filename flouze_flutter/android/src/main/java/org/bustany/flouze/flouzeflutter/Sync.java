package org.bustany.flouze.flouzeflutter;

public class Sync {
    public static native void sync(long repoPtr, long remotePtr, byte[] accountId);
}
