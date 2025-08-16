import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shelf_it/add_item_screen.dart';
import 'package:shelf_it/dashboard_screen.dart';
import 'package:shelf_it/login_screen.dart';
import 'package:shelf_it/signup_screen.dart';
import 'package:shelf_it/stock_level.dart'; // Import the Stock Levels page correctly
import 'product_page.dart'; // Import the Product page
import 'order_page.dart'; // Import the Product page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shelf-It',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Professional blue
          brightness: Brightness.light,
          primary: const Color(0xFF1565C0), // Deep blue
          secondary: const Color(0xFF37474F), // Professional gray
          surface: const Color(0xFFFAFAFA), // Light gray background
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1565C0),
            side: const BorderSide(color: Color(0xFF1565C0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5), // Softer light gray
        cardColor: Colors.white,
        dividerColor: Colors.grey.shade200,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
          primary: const Color(0xFF42A5F5),
          secondary: const Color(0xFF78909C),
          surface: const Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFF2D2D2D),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/product': (context) => ProductPage(),
        '/add': (context) => const AddItemScreen(),
        '/stocklevels': (context) => StockLevelPage(),
        '/orders': (context) => OrderPage(),
      },
    );
  }
}
