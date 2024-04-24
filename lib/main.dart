import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/AuthServices/auth_methods_.dart';
import 'package:firebase_chat/Pages/home_page.dart';
import 'package:firebase_chat/Pages/sing_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // runApp(const MyApp());
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  runApp(MyApp(analytics: analytics));
  FirebaseAnalytics.instance.logAppOpen();
  try {
    await Firebase.initializeApp();
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    print("Success to initialize Firebase:------------------");
  } catch(e) {
    print("Failed to initialize Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  const MyApp({super.key, required FirebaseAnalytics analytics});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<User?>(
        future: AuthServices().getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Log a custom event
            analytics.logEvent(name: 'circularProgressIndicator', parameters: null);

            // Set user properties
            analytics.setUserProperty(name: 'circularProgressIndicator', value: 'blue');
            return const CircularProgressIndicator();
          } else {
            if (snapshot.hasData) {
              return const HomePage();
            } else {
              return const SingUpScreen();
            }
          }
        },
      ),
    );
  }
}

// https://github1s.com/MarcusNg/flutter_chat_ui/blob/HEAD/lib/screens/chat_screen.dart#L129
