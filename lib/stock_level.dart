// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StockLevelPage extends StatefulWidget {
  @override
  _StockLevelPageState createState() => _StockLevelPageState();
}

class _StockLevelPageState extends State<StockLevelPage> {
  int _selectedIndex = 3; // Set to 3 for Stock Levels tab
  String _selectedSortOption = 'Stock Level (Descending)';
  String? _userMode; // To store the user's mode (personal/organization)
  String? _companyName; // To store the user's company name (if applicable)
  String? _userId; // To store the user's ID

  List<String> sortOptions = [
    'Name',
    'Stock Level (Ascending)',
    'Stock Level (Descending)',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserMode();
  }

  Future<void> _fetchUserMode() async {
    try {
      // Get the current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user data from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _userMode = userSnapshot['mode'];
          _companyName = userSnapshot['mode'] == 'organization'
              ? userSnapshot['company_name']
              : null;
          _userId = userId; // Save the user's ID
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
    }
  }

  // Bottom navigation bar handler
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: sortOptions.map((option) {
            return ListTile(
              title: Text(option),
              onTap: () {
                setState(() {
                  _selectedSortOption = option;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    Query query = FirebaseFirestore.instance.collection('Product');

    // Filter by company_name or userId based on user mode
    if (_userMode == 'organization') {
      query = query.where('company_name', isEqualTo: _companyName);
    } else {
      query = query.where('userId', isEqualTo: _userId);
    }

    // Apply sorting by selected option
    if (_selectedSortOption == 'Stock Level (Descending)') {
      query = query.orderBy('quantity', descending: true);
    } else if (_selectedSortOption == 'Stock Level (Ascending)') {
      query = query.orderBy('quantity', descending: false);
    } else if (_selectedSortOption == 'Name') {
      query = query.orderBy('name');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Levels', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF213A57), // Dark teal from the color scheme
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: _userMode == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Color(0xFFE6F2F0), // A soft, light teal for background
              child: StreamBuilder(
                stream: _getFilteredStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    if (snapshot.error.toString().contains(
                      'failed-precondition',
                    )) {
                      return Center(
                        child: Text(
                          'Query requires a Firestore index. Please set up the index in Firebase Console.',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Center(
                      child: Text('An error occurred: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No products available.'));
                  }

                  var products = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      var data = product.data() as Map<String, dynamic>?;

                      String name = data != null && data.containsKey('name')
                          ? data['name']
                          : 'No Name';
                      int quantity =
                          data != null && data.containsKey('quantity')
                          ? int.tryParse(data['quantity'].toString()) ?? 0
                          : 0;
                      int? threshold =
                          data != null && data.containsKey('threshold')
                          ? int.tryParse(data['threshold'].toString())
                          : null;

                      return StockLevelTile(
                        name: name,
                        quantity: quantity,
                        threshold: threshold,
                        onSetThreshold: (newThreshold) {
                          product.reference.update({'threshold': newThreshold});
                        },
                      );
                    },
                  );
                },
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B6477),
        selectedItemColor: const Color(0xFF45DFB1),
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Products",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            label: "Stock Levels",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Order"),
        ],
      ),
    );
  }
}

class StockLevelTile extends StatelessWidget {
  final String name;
  final int quantity;
  final int? threshold;
  final ValueChanged<int> onSetThreshold;

  const StockLevelTile({
    required this.name,
    required this.quantity,
    required this.threshold,
    required this.onSetThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // Shadow color
            spreadRadius: 2, // Spread of the shadow
            blurRadius: 5, // Blur intensity
            offset: const Offset(0, 3), // Offset of the shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              quantity <= (threshold ?? 0)
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: quantity <= (threshold ?? 0) ? Colors.red : Colors.green,
              size: 40.0,
            ),
            const SizedBox(width: 15.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Color(0xFF0B6477),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Stock Level: $quantity',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Threshold: ${threshold ?? 'Not Set'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () async {
                      int? newThreshold = await showDialog<int>(
                        context: context,
                        builder: (context) =>
                            ThresholdDialog(currentThreshold: threshold),
                      );
                      if (newThreshold != null) {
                        try {
                          // Record the threshold to the database
                          onSetThreshold(newThreshold);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Threshold updated to $newThreshold',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating threshold: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Set Threshold'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThresholdDialog extends StatefulWidget {
  final int? currentThreshold;

  const ThresholdDialog({this.currentThreshold});

  @override
  _ThresholdDialogState createState() => _ThresholdDialogState();
}

class _ThresholdDialogState extends State<ThresholdDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentThreshold?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Low Stock Threshold'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: 'Enter threshold value'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            int? value = int.tryParse(_controller.text);
            if (value == null || value < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter a valid threshold value')),
              );
              return;
            }
            Navigator.pop(context, value);
          },
          child: Text('Set'),
        ),
      ],
    );
  }
}
