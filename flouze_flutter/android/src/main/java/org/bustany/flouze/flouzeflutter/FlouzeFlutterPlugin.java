package org.bustany.flouze.flouzeflutter;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlouzeFlutterPlugin */
public class FlouzeFlutterPlugin implements MethodCallHandler {
    /** Plugin registration. */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flouze_flutter");
        channel.setMethodCallHandler(new FlouzeFlutterPlugin());
    }

    private long pointerValue(Object object) {
        if (object instanceof Long) {
            return (Long)object;
        }

        if (object instanceof Integer) {
            return (Integer)object;
        }

        throw new RuntimeException("Pointer object is neither Integer or Long");
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
        case "getPlatformVersion":
            result.success("This is Android " + android.os.Build.VERSION.RELEASE);
            return;
        case "init":
            try {
                System.loadLibrary("flouze_flutter");
                result.success(null);
            } catch (Throwable e) {
                result.error("INIT_ERROR", e.getMessage(), null);
            }
            return;
        case "SledRepository::temporary":
            try {
                result.success(SledRepository.temporary());
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.getMessage(), null);
            }
            return;
        case "SledRepository::fromFile":
            try {
                final String path = call.arguments();
                result.success(SledRepository.fromFile(path));
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "SledRepository::close":
            try {
                final long ptr = pointerValue(call.arguments());
                SledRepository.destroy(ptr);
                result.success(null);
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "SledRepository::addAccount":
            try {
                final long ptr = pointerValue(call.argument("ptr"));
                final byte[] account = call.argument("account");
                SledRepository.addAccount(ptr, account);
                result.success(null);
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "SledRepository::listAccounts":
            try {
                final long ptr = pointerValue(call.arguments());
                result.success(SledRepository.listAccounts(ptr));
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "SledRepository::listTransactions":
            try {
                final long ptr = pointerValue(call.argument("ptr"));
                final byte[] accountId = call.argument("accountId");
                result.success(SledRepository.listTransactions(ptr, accountId));
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "SledRepository::addTransaction":
            try {
                final long ptr = pointerValue(call.argument("ptr"));
                final byte[] accountId = call.argument("accountId");
                final byte[] transaction = call.argument("transaction");
                SledRepository.addTransaction(ptr, accountId, transaction);
                result.success(null);
            } catch (Throwable e) {
                result.error("SLED_REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "Repository::getBalance":
            try {
                final long ptr = pointerValue(call.argument("ptr"));
                final byte[] accountId = call.argument("accountId");
                result.success(Repository.getBalance(ptr, accountId));
            } catch (Throwable e) {
                result.error("REPOSITORY_ERROR", e.toString(), null);
            }
            return;
        case "JsonRpcClient::create":
            try {
                final String url = call.arguments();
                result.success(JsonRpcClient.create(url));
            } catch (Throwable e) {
                result.error("JSON_RPC_CLIENT_ERROR", e.toString(), null);
            }
            return;
        case "JsonRpcClient::createAccount":
            try {
                final long ptr = pointerValue(call.argument("ptr"));
                final byte[] account = call.argument("account");
                JsonRpcClient.createAccount(ptr, account);
                result.success(null);
            } catch (Throwable e) {
                result.error("JSON_RPC_CLIENT_ERROR", e.toString(), null);
            }
            return;
        case "Sync::sync":
            try {
                final long repoPtr = pointerValue(call.argument("repoPtr"));
                final long remotePtr = pointerValue(call.argument("remotePtr"));
                final byte[] accountId = call.argument("accountId");
                Sync.sync(repoPtr, remotePtr, accountId);
                result.success(null);
            } catch (Throwable e) {
                result.error("SYNC_ERROR", e.toString(), null);
            }
            return;
        default:
            result.notImplemented();
        }
  }
}
