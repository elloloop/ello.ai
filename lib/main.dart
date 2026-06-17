import "package:flutter_localizations/flutter_localizations.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'src/ui/home_page.dart';
import 'src/services/crash_reporting_service.dart';

void main() async {
  await _runAppWithCrashReporting();
}

Future<void> _runAppWithCrashReporting() async {
  // Initialize crash reporting service
  await CrashReportingService.initialize();

  // Run the app with Sentry error handling
  await SentryFlutter.init(
    (options) {
      // Sentry configuration is handled in CrashReportingService
      // This wrapper ensures Flutter framework errors are caught
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.debug = false; // Avoid duplicate logs since CrashReportingService handles this
    },
    appRunner: () => runApp(const ProviderScope(child: ElloApp())),
  );
}

class ElloApp extends StatelessWidget {
  const ElloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ello.AI',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
          useMaterial3: true),
      home: const HomePage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      // Add error handling for widget build errors
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          // Report widget build errors to crash reporting
          CrashReportingService.reportError(
            errorDetails.exception,
            errorDetails.stack,
            message: 'Widget build error: ${errorDetails.summary}',
            extra: {
              'library': errorDetails.library,
              'context': errorDetails.context?.toString(),
            },
          );
          
          // Return a user-friendly error widget
          return Material(
            child: Container(
              color: Colors.red[50],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please restart the app or contact support if the problem persists.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}
