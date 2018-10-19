import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:sentry/sentry.dart';

import 'package:flouze/pages/welcome.dart';
import 'package:flouze/utils/build_info.dart';

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true); // Only evaluated in debug mode
  return inDebugMode;
}

Future<SentryClient> _initSentry() async {
  if (isInDebugMode) {
    return null;
  }

  try {
    Map<String, dynamic> eventData = {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'build_info': await getBuildInfo(),
    };

    return SentryClient(
      dsn: (await rootBundle.loadString('assets/sentry_dsn.txt')).trim(),
      environmentAttributes: Event(extra: eventData),
    );
  } catch (e) {
    print('Error while loading Sentry configuration: $e');
    // Probably no sentry DSN found
    return null;
  }
}

Future<Null> _reportError(SentryClient client, dynamic error, dynamic stackTrace) async {
  print('Caught error: $error');

  if (isInDebugMode || client == null) {
    print(stackTrace);
    print('In dev mode or Sentry not configured. Not sending report to Sentry.io.');
    return;
  }

  print('Reporting to Sentry.io...');

  final SentryResponse response = await client.captureException(
    exception: error,
    stackTrace: stackTrace,
  );

  if (response.isSuccessful) {
    print('Success! Event ID: ${response.eventId}');
  } else {
    print('Failed to report to Sentry.io: ${response.error}');
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flouze!',
      theme: new ThemeData(
        primarySwatch: Colors.green,
      ),
      home: new WelcomePage(),
    );
  }
}

Future<Null> main() async {
  var sentryClient = await _initSentry();

  FlutterError.onError = (FlutterErrorDetails details) async {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  runZoned<Future<Null>>(() async {
    runApp(new MyApp());
  }, onError: (error, stackTrace) async {
    await _reportError(sentryClient, error, stackTrace);
  });
}
