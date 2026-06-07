import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/book_service.dart';
import 'services/settings_service.dart';
import 'services/stats_service.dart';
import 'services/backup_service.dart';
import 'services/library_service.dart';
import 'screens/settings_screen.dart';
import 'screens/appearance_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/cloud_connections_screen.dart';
import 'screens/txt_rules_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'screens/upgrade_pro_screen.dart';
import 'screens/about_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/user_guide_screen.dart';
import 'screens/menu_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // Firebase not configured for this platform — skip auth
  }
  runApp(EbookReaderApp(firebaseReady: firebaseReady));
}

class EbookReaderApp extends StatelessWidget {
  final bool firebaseReady;
  const EbookReaderApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mei 阅读器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: AuthGate(firebaseReady: firebaseReady),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/appearance': (context) => const AppearanceScreen(),
        '/stats': (context) => const StatsScreen(),
        '/backup': (context) => const BackupScreen(),
        '/cloud_connections': (context) => const CloudConnectionsScreen(),
        '/txt_rules': (context) => const TxtRulesScreen(),
        '/privacy_security': (context) => const PrivacySecurityScreen(),
        '/upgrade_pro': (context) => const UpgradeProScreen(),
        '/about': (context) => const AboutScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/user_guide': (context) => const UserGuideScreen(),
        '/menu_management': (context) => const MenuManagementScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool firebaseReady;
  const AuthGate({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    // If Firebase is not configured, skip auth and go directly to home
    if (!firebaseReady) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => BookService()),
          ChangeNotifierProvider(create: (context) => SettingsService()),
          ChangeNotifierProvider(create: (context) => StatsService()),
          ChangeNotifierProvider(create: (context) => BackupService()),
          ChangeNotifierProvider(create: (context) => LibraryService()),
        ],
        child: const HomeScreen(),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => BookService()),
              ChangeNotifierProvider(create: (context) => SettingsService()),
              ChangeNotifierProvider(create: (context) => StatsService()),
              ChangeNotifierProvider(create: (context) => BackupService()),
              ChangeNotifierProvider(create: (context) => LibraryService()),
            ],
            child: const HomeScreen(),
          );
        }

        // User is not logged in
        return const AuthScreen();
      },
    );
  }
}
