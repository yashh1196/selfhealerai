import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = (FlutterErrorDetails details) async {
    // 1. Record to Firebase Crashlytics as usual (Mark it as FATAL)
    await FirebaseCrashlytics.instance.recordFlutterError(details, fatal: true);

    // 2. Bypass Firebase limits and send directly to your free Render server!
    try {
      await http.post(
        Uri.parse('https://jira-webhook-server.onrender.com/createJiraOnCrash'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'crashlytics': {
              'issueTitle': details.exceptionAsString(),
              'issueUrl': 'Flutter App Crash',
              'eventCount': 1,
            }
          }
        }),
      );
    } catch (e) {
      debugPrint('Failed to trigger Render webhook: $e');
    }

    // Forcefully kill the app so it shows "Lost connection" in the console
    exit(1);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const CrashScreen(),
    );
  }
}

class CrashScreen extends StatefulWidget {
  const CrashScreen({super.key});

  @override
  State<CrashScreen> createState() => _CrashScreenState();
}

class _CrashScreenState extends State<CrashScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Big upside heading
              Text(
                'Self\nHealer\nAI',
                style: t.displaySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Crashlytics · debug',
                style: TextStyle(fontSize: 13, color: c.onSurfaceVariant),
              ),

              const SizedBox(height: 48),

              // Crash count
              Text(
                'Crashes recorded',
                style: TextStyle(fontSize: 13, color: c.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '$_count',
                style: t.displayMedium?.copyWith(fontWeight: FontWeight.w500),
              ),

              const Spacer(),

              // Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.onSurface,
                    foregroundColor: c.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _count++);
                    // Throwing a Dart error so it triggers FlutterError.onError and our webhook successfully!
                    throw Exception("Test Jira Crash from Flutter!");
                  },
                  child: const Text('Force crash'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}