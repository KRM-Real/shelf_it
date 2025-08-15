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
        primaryColor: const Color.fromARGB(
            255, 40, 231, 110), // Grab's primary green color
        primarySwatch: Colors.green,
      ),
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
