// ignore_for_file: use_build_context_synchronously, use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/modern_drawer.dart';
import 'dashboard/dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _userMode;
  String? _companyName;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserMode();
  }

  Future<void> _fetchUserMode() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        final data = userSnapshot.data() as Map<String, dynamic>?;
        setState(() {
          _userMode = data?['mode'] ?? 'individual';
          _companyName = _userMode == 'organization'
              ? (data != null ? data['company_name'] : null)
              : null;
          _userId = userId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
      }
    }
  }

  Future<void> _refreshDashboard() async {
    await _fetchUserMode();
    setState(() {});
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/product');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/add');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/stocklevels');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/orders');
          break;
      }
    }
  }

  void _handleScanPressed() {
    BarcodeScannerService.scanAndFindProduct(
      context,
      userMode: _userMode,
      companyName: _companyName,
      userId: _userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ModernDrawer(userMode: _userMode, companyName: _companyName),
      body: Column(
        children: [
          Expanded(
            child: DashboardView(
              scaffoldKey: _scaffoldKey,
              onRefresh: _refreshDashboard,
              onScanPressed: _handleScanPressed,
              userMode: _userMode,
              companyName: _companyName,
              userId: _userId,
            ),
          ),
          BottomNavigationBar(
            backgroundColor: const Color(0xFF0B6477),
            selectedItemColor: const Color(0xFF45DFB1),
            unselectedItemColor: Colors.black,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Products',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_outlined),
                label: 'Stock Levels',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Order',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
