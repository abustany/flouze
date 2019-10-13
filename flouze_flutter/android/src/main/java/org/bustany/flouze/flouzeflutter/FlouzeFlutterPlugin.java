package org.bustany.flouze.flouzeflutter;

import android.annotation.TargetApi;
import android.os.Build;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlouzeFlutterPlugin */
public class FlouzeFlutterPlugin implements MethodCallHandler, EventChannel.StreamHandler {
    /** Plugin registration. */
    public static void registerWith(Registrar registrar) {
    }

    @TargetApi(Build.VERSION_CODES.CUPCAKE)
    @Override
    public void onMethodCall(MethodCall call, Result result) {
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
    }

    @Override
    public void onCancel(Object o) {
    }
}
