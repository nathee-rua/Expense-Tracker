import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar to transparent and set light icons for premium look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0F16),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const PremiumExpenseTrackerApp());
}

class PremiumExpenseTrackerApp extends StatelessWidget {
  const PremiumExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity Premium Finance',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F16),
        primaryColor: const Color(0xFF8E2DE2),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8E2DE2),
          secondary: Color(0xFF00C6FF),
          background: Color(0xFF0F0F16),
          surface: Color(0xFF1E1E2C),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white70,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.white87,
            fontSize: 15,
          ),
          bodyMedium: TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
