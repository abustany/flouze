package org.bustany.flouze.flouzeflutter;

import android.annotation.TargetApi;
import android.os.AsyncTask;
import android.os.Build;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.CUPCAKE)
public class FlouzeAsyncTask extends AsyncTask<MethodCall, Void, FlouzeAsyncTask.Result> {
    static class Result {
        static Result ok(Object value) {
            final Result r = new Result();
            r.result = value;
            return r;
        }

        static Result error(Exception e) {
            final Result r = new Result();
            r.exception = e;
            return r;
        }

        private Result accountListChanged() {
            this.accountListChanged = true;
            return this;
        }

        Object result;
        Exception exception;
        boolean accountListChanged;
    }

    private static long pointerValue(Object object) {
        if (object instanceof Long) {
            return (Long)object;
        }

        if (object instanceof Integer) {
            return (Integer)object;
        }

        throw new RuntimeException("Pointer object is neither Integer or Long");
    }

    private static byte[] byteArrayValue(Object object) {
        return (byte[]) object;
    }

    private final MethodChannel.Result flutterResult;
    private final EventChannel.EventSink events;

    FlouzeAsyncTask(MethodChannel.Result flutterResult, EventChannel.EventSink events) {
        this.flutterResult = flutterResult;
        this.events = events;
    }

    private void onAccountListChanged() {
        if (events == null) {
            return;
        }

        events.success("account_list_changed");
    }

    @Override
    protected Result doInBackground(MethodCall[] calls) {
        final MethodCall call = calls[0];

        try {
            switch (call.method) {
            case "init":
                System.loadLibrary("flouze_flutter");
                return Result.ok(null);
            case "SledRepository::temporary":
                return Result.ok(SledRepository.temporary());
            case "SledRepository::fromFile":
                final String path = call.argument("path");
                return Result.ok(SledRepository.fromFile(path));
            case "SledRepository::close":
                SledRepository.destroy(pointerValue(call.argument("ptr")));
                return Result.ok(null);
            case "SledRepository::addAccount":
                SledRepository.addAccount(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("account"))
                );
                return Result.ok(null).accountListChanged();
            case "SledRepository::deleteAccount":
                SledRepository.deleteAccount(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("accountId"))
                );
                return Result.ok(null).accountListChanged();
            case "SledRepository::listAccounts":
                return Result.ok(SledRepository.listAccounts(pointerValue(call.argument("ptr"))));
            case "SledRepository::listTransactions":
                return Result.ok(SledRepository.listTransactions(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("accountId")))
                );
            case "SledRepository::addTransaction":
                SledRepository.addTransaction(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("accountId")),
                        byteArrayValue(call.argument("transaction"))
                );
                return Result.ok(null);
            case "Repository::getBalance":
                return Result.ok(Repository.getBalance(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("accountId")))
                );
            case "JsonRpcClient::create":
                final String url = call.argument("url");
                return Result.ok(JsonRpcClient.create(url));
            case "JsonRpcClient::createAccount":
                JsonRpcClient.createAccount(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("account"))
                );
                return Result.ok(null);
            case "JsonRpcClient::getAccountInfo":
                return Result.ok(JsonRpcClient.getAccountInfo(
                        pointerValue(call.argument("ptr")),
                        byteArrayValue(call.argument("accountId")))
                );
            case "JsonRpcClient::destroy":
                JsonRpcClient.destroy(
                        pointerValue(call.argument("ptr"))
                );
                return Result.ok(null);
            case "Sync::cloneRemote":
                Sync.cloneRemote(
                        pointerValue(call.argument("repoPtr")),
                        pointerValue(call.argument("remotePtr")),
                        byteArrayValue(call.argument("accountId"))
                );
                return Result.ok(null).accountListChanged();
            case "Sync::sync":
                Sync.sync(
                        pointerValue(call.argument("repoPtr")),
                        pointerValue(call.argument("remotePtr")),
                        byteArrayValue(call.argument("accountId"))
                );
                return Result.ok(null);
            default:
                return Result.error(new Exception("Not implemented"));
            }
        } catch (Exception e) {
            return Result.error(e);
        }
    }

    @Override
    protected void onPostExecute(Result result) {
        if (result.exception != null) {
            flutterResult.error(result.exception.getClass().getName(), result.exception.getMessage(), null);
        } else {
            flutterResult.success(result.result);

            if (result.accountListChanged) {
                onAccountListChanged();
            }
        }
    }
}
