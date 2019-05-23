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
    private EventChannel.EventSink events;

    /** Plugin registration. */
    public static void registerWith(Registrar registrar) {
        final FlouzeFlutterPlugin instance = new FlouzeFlutterPlugin();

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flouze_flutter");
        channel.setMethodCallHandler(instance);

        final EventChannel eventChannel = new EventChannel(registrar.messenger(), "flouze_flutter/events");
        eventChannel.setStreamHandler(instance);
    }

    @TargetApi(Build.VERSION_CODES.CUPCAKE)
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        new FlouzeAsyncTask(result, events).execute(call);
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        events = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        events = null;
    }
}
