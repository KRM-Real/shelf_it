// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, unused_element, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 4;
  String _action = 'Restock';
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
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        setState(() {
          _userMode = userSnapshot['mode'];
          _companyName = userSnapshot['mode'] == 'organization'
              ? userSnapshot['company_name']
              : null;
          _userId = userId;
        });
      } else {
        throw Exception("User data not found.");
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching user data: $e');
    }
  }

  void _placeOrder() async {
    if (_userMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch user mode. Try again later.')),
      );
      return;
    }

    String productName = _productNameController.text.trim();
    int? quantity = int.tryParse(_quantityController.text);

    if (productName.isEmpty || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter a valid product name and quantity.')),
      );
      return;
    }

    try {
      Query productQuery = _firestore
          .collection('Product')
          .where('name', isEqualTo: productName);

      if (_userMode == 'organization') {
        productQuery =
            productQuery.where('company_name', isEqualTo: _companyName);
      } else {
        productQuery = productQuery.where('userId', isEqualTo: _userId);
      }

      QuerySnapshot productSnapshot = await productQuery.get();

      if (productSnapshot.docs.isNotEmpty) {
        DocumentSnapshot productDoc = productSnapshot.docs.first;

        String productId = productDoc.id;
        Map<String, dynamic> productData =
            productDoc.data() as Map<String, dynamic>;

        // Default values for missing fields
        int currentStock = productData['quantity'] ?? 0;
        int currentSold =
            productData.containsKey('sold') ? productData['sold'] : 0;

        if (_action == 'Restock') {
          // Update quantity and lastRestock timestamp
          await _firestore.collection('Product').doc(productId).update({
            'quantity': currentStock + quantity,
            'lastRestock': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$quantity pcs of $productName added.')),
          );
        } else if (_action == 'Sold') {
          if (currentStock >= quantity) {
            // Update quantity and sold count
            await _firestore.collection('Product').doc(productId).update({
              'quantity': currentStock - quantity,
              'sold': currentSold + quantity,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('$quantity pcs of $productName sold successfully.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Insufficient stock to sell $quantity pcs of $productName.')),
            );
            return;
          }
        }

        // Log the transaction
        await _logTransaction(productName, quantity, _action);

        // Clear inputs
        _productNameController.clear();
        _quantityController.clear();
        _noteController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _logTransaction(
      String productName, int quantity, String action) async {
    try {
      // Query the product to fetch the price
      Query productQuery = _firestore
          .collection('Product')
          .where('name', isEqualTo: productName);

      if (_userMode == 'organization') {
        productQuery =
            productQuery.where('company_name', isEqualTo: _companyName);
      } else {
        productQuery = productQuery.where('userId', isEqualTo: _userId);
      }

      QuerySnapshot productSnapshot = await productQuery.get();

      if (productSnapshot.docs.isNotEmpty) {
        DocumentSnapshot productDoc = productSnapshot.docs.first;

        // Get the price field from the product document
        dynamic priceField = productDoc['price'];
        double price = priceField is String
            ? double.tryParse(priceField) ?? 0.0
            : priceField is double
                ? priceField
                : 0.0;

        // Log the transaction with the price
        await _firestore.collection('transactions').add({
          'product': productName,
          'quantity': quantity,
          'price': price, // Write price into the transaction record
          'action': action,
          'note': _noteController.text.trim(),
          'userId': _userId,
          'company_name': _companyName,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _showSuccessSnackbar('Transaction logged successfully.');
      } else {
        _showErrorSnackbar('Product not found. Price could not be logged.');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to log transaction: $e');
    }
  }

  void _clearInputs() {
    _productNameController.clear();
    _quantityController.clear();
    _noteController.clear();
  }

  void _showTransactionHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('transactions')
              .where(_userMode == 'organization' ? 'company_name' : 'userId',
                  isEqualTo:
                      _userMode == 'organization' ? _companyName : _userId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error fetching transactions: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            // If no documents exist, show a message indicating no transactions
            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No Transactions Found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }

            // Otherwise, show the list of transactions
            return ListView(
              children: snapshot.data!.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String product = data['product'];
                int quantity = data['quantity'];
                String action = data['action'];
                Timestamp timestamp = data['timestamp'];
                String formattedDate = timestamp.toDate().toString();

                return ListTile(
                  title: Text('$action: $quantity pcs of $product'),
                  subtitle: Text('Date: $formattedDate'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _deleteTransaction(doc.id, product, quantity, action),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTransaction(String transactionId, String productName,
      int quantity, String action) async {
    try {
      Query productQuery = _firestore
          .collection('Product')
          .where('name', isEqualTo: productName);

      if (_userMode == 'organization') {
        productQuery =
            productQuery.where('company_name', isEqualTo: _companyName);
      } else {
        productQuery = productQuery.where('userId', isEqualTo: _userId);
      }

      QuerySnapshot productSnapshot = await productQuery.get();
      if (productSnapshot.docs.isNotEmpty) {
        DocumentSnapshot productDoc = productSnapshot.docs.first;

        // Decide the adjustment based on the action type
        int adjustment = 0;
        if (action == 'Restock') {
          adjustment = -quantity; // Deduct stock if Restock is deleted
        } else if (action == 'Sold') {
          adjustment = quantity; // Add stock back if Sold is deleted
        }

        await _firestore.collection('Product').doc(productDoc.id).update({
          'quantity': FieldValue.increment(adjustment),
        });

        // Delete the transaction
        await _firestore.collection('transactions').doc(transactionId).delete();

        _showSuccessSnackbar('Transaction deleted and stock adjusted.');
      } else {
        _showErrorSnackbar('Product not found for adjustment.');
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting transaction: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6F2F0),
      appBar: AppBar(
        title: Text('Order Page', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF213A57),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: _showTransactionHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Makes content scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              DropdownSearch<String>(
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: 'Search Product',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                asyncItems: (String filter) async {
                  // Fetch product names from Firestore
                  QuerySnapshot snapshot;
                  if (_userMode == 'organization') {
                    snapshot = await _firestore
                        .collection('Product')
                        .where('company_name', isEqualTo: _companyName)
                        .get();
                  } else {
                    snapshot = await _firestore
                        .collection('Product')
                        .where('userId', isEqualTo: _userId)
                        .get();
                  }
                  return snapshot.docs
                      .map((doc) => doc['name'] as String)
                      .where((name) =>
                          name.toLowerCase().contains(filter.toLowerCase()))
                      .toList();
                },
                onChanged: (value) {
                  setState(() {
                    _productNameController.text = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              // Quantity and Action in one Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _action,
                      items: ['Restock', 'Sold']
                          .map((action) => DropdownMenuItem<String>(
                                value: action,
                                child: Text(action),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _action = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Action',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00b140),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
            ],
          ),
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
              icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_outlined), label: "Stock Levels"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Order"),
        ],
      ),
    );
  }
}
