package org.bustany.flouze.flouzeflutter;

public class Sync {
    public static native void cloneRemote(long repoPtr, long remotePtr, byte[] accountId);
    public static native void sync(long repoPtr, long remotePtr, byte[] accountId);
}
