import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shelf_it/add_item_screen.dart';
import 'package:shelf_it/dashboard_screen.dart';
import 'package:shelf_it/login_screen.dart';
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
          seedColor: const Color.fromARGB(255, 40, 231, 110), // Shelf-It primary green
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 4,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 40, 231, 110),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 4,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Respects system theme preference
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/product': (context) => ProductPage(),
        '/add': (context) => const AddItemScreen(),
        '/stocklevels': (context) => StockLevelPage(),
        '/orders': (context) => OrderPage(),
      },
    );
  }
}
