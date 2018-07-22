package flouze;

import com.google.protobuf.InvalidProtocolBufferException;
import flouze.Model.Account;

class SledRepository implements Repository {
    private final long ptr;

    private SledRepository(long ptr) {
        this.ptr = ptr;
    }

    public static SledRepository temporary() {
        long ptr = _newSledTemporary();

        return new SledRepository(ptr);
    }

    public void close() {
        _destroy(ptr);
    }

    @Override
    public void addAccount(Account account) {
        _addAccount(ptr, account.toByteArray());
    }

    @Override
    public Account getAccount(byte[] accountId) {
        try {
            return Account.parseFrom(_getAccount(ptr, accountId));
        } catch (InvalidProtocolBufferException e) {
            throw new RuntimeException(e);
        }
    }

    private static native long _newSledTemporary();
    private native void _destroy(long ptr);
    private static native void _addAccount(long ptr, byte[] account);
    private native byte[] _getAccount(long ptr, byte[] accountId);
}
