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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0F2F5), // Soft light gray
              const Color(0xFFE8F4FD), // Muted light blue
              const Color(0xFFECEFF1), // Warm light gray
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header Card
              Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  'Stock Levels',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Inventory Monitoring',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _showSortOptions,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.filter_list,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content Area
              Expanded(
                child: _userMode == null
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: StreamBuilder(
                          stream: _getFilteredStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                                child: Text(
                                  'An error occurred: ${snapshot.error}',
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No products available.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }

                            var products = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                var product = products[index];
                                var data =
                                    product.data() as Map<String, dynamic>?;

                                String name =
                                    data != null && data.containsKey('name')
                                    ? data['name']
                                    : 'No Name';
                                int quantity =
                                    data != null && data.containsKey('quantity')
                                    ? int.tryParse(
                                            data['quantity'].toString(),
                                          ) ??
                                          0
                                    : 0;
                                int? threshold =
                                    data != null &&
                                        data.containsKey('threshold')
                                    ? int.tryParse(data['threshold'].toString())
                                    : null;

                                return StockLevelTile(
                                  name: name,
                                  quantity: quantity,
                                  threshold: threshold,
                                  onSetThreshold: (newThreshold) {
                                    product.reference.update({
                                      'threshold': newThreshold,
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
    bool isLowStock = quantity <= (threshold ?? 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? const Color(0xFFFFEBEE) // Light red background
                      : const Color(0xFFE8F5E8), // Light green background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: isLowStock
                      ? const Color(0xFFE57373) // Muted red
                      : const Color(0xFF66BB6A), // Muted green
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Stock Level: $quantity',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Threshold: ${threshold ?? 'Not Set'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8.0),
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
                      child: Text(
                        'Set Threshold',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
