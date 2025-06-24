import "package:flutter_localizations/flutter_localizations.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/home_page.dart';
import 'src/services/notification_service.dart';

void main() {
  runApp(const ProviderScope(child: ElloApp()));
}

class ElloApp extends StatelessWidget {
  const ElloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    
    // Initialize the notification service
    NotificationService.initialize(scaffoldMessengerKey);
    
    return MaterialApp(
      title: 'ello.AI',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
          useMaterial3: true),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const HomePage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
