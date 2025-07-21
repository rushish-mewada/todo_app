import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/todo.dart';
import 'providers/auth_provider.dart';
import 'providers/login_provider.dart';
import 'providers/signup_provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());

  await Hive.openBox<Todo>('todos');
  await Hive.openBox('dismissed_notifications');
  await Hive.openBox('previous_todo_data');
  await Hive.openBox('active_change_notification_keys');
  // Open shown_notifications as a lazy box of type bool to avoid clearing
  final shownBox = await Hive.openBox('shown_notifications');

  // Ensure shown_notifications are preserved between refreshes
  if (!shownBox.containsKey('__initialized')) {
    await shownBox.put('__initialized', true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TO DO App',
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const InitAppWrapper(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

class InitAppWrapper extends StatelessWidget {
  const InitAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthCheck();
  }
}
