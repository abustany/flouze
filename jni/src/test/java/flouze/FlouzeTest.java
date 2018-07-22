package flouze;

import com.google.protobuf.ByteString;
import org.junit.Test;
import static org.junit.Assert.*;

public class FlouzeTest {
    static {
        Flouze.init();
    }

    @Test
    public void testSledRepository() {
        SledRepository repo = SledRepository.temporary();

        final byte[] person_id = {1, 2, 3};
        final Model.Person member = Model.Person.newBuilder()
            .setUuid(ByteString.copyFrom(person_id))
            .setName("John")
            .build();

        final byte[] account_id = {1, 2, 3};
        final Model.Account account = Model.Account.newBuilder()
            .setUuid(ByteString.copyFrom(account_id))
            .setLabel("My account")
            .addMembers(member)
            .build();

        repo.addAccount(account);

        final Model.Account fetched = repo.getAccount(account_id);

        assertEquals(account, fetched);

        repo.close();
    }
}
