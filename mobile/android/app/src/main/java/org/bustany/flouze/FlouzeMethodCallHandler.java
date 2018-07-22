package org.bustany.flouze;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlouzeMethodCallHandler implements MethodChannel.MethodCallHandler {
    private static boolean initialized = false;

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("init")) {
            try {
                init();
                result.success(new Object());
            } catch (Exception e) {
                result.error("INIT_ERROR", e.toString(), null);
            }

            return;
        }

        result.notImplemented();
    }

    private static synchronized void init() {
        if (!initialized) {
            System.loadLibrary("flouze_jni");
            initialized = true;
        }
    }
}
