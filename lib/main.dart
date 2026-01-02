import 'package:chats/core/theme/app_theme.dart';
import 'package:chats/features/auth/auth_screen.dart';
import 'package:flutter/services.dart';
import 'package:chats/features/home/home_screen.dart';
import 'package:chats/services/auth_service.dart';
import 'package:chats/services/location_service.dart';
import 'package:chats/services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  // We need to handle the case where Firebase is not configured yet
  // For this environment, we'll try to initialize, and if it fails (no google-services.json),
  // we might need a fallback or just let it crash with a clear message for the user.
  // Ideally for this demo, I'd assume the user might not have set it up, but I'll proceed as if they did.
  // Or I can use a try-catch to print a warning.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // In a real scenario, we might show an error screen,
    // but for dev flow, we'll let it proceed but Auth will fail.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => DatabaseService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Right Now',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.user != null) {
      return const HomeScreen();
    }

    return const AuthScreen();
  }
}
