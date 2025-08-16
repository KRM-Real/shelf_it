// ignore_for_file: use_build_context_synchronously, use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_it/profile_page.dart';
import 'package:shelf_it/transaction.dart';
import 'login_screen.dart';
import 'analytics.dart';
import 'company_details_page.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final data =
            userSnapshot.data() as Map<String, dynamic>?; // Cast to Map
        setState(() {
          _userMode = data?['mode'] ?? 'individual';
          _companyName = _userMode == 'organization'
              ? (data != null ? data['company_name'] : null)
              : null;
          _userId = userId;
        });
        // Debug: User mode: $_userMode
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchUserSpecificMovementAnalytics() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Fetch user-specific transactions
      QuerySnapshot transactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId) // Ensure this filters by user
          .get();

      if (transactions.docs.isEmpty) {
        // Debug: No Item Movement
        return {
          'mostMovements': [],
          'leastMovements': [],
        };
      }

      Map<String, int> movementCounts = {};

      for (var doc in transactions.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final product = data['product'];
        final quantity = data['quantity'] as int? ?? 0;

        if (product != null) {
          movementCounts[product] = (movementCounts[product] ?? 0) + quantity;
        }
      }

      // Debug: Aggregated Movements: $movementCounts

      final sortedEntries = movementCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top3Most = sortedEntries.take(3).map((entry) {
        return {
          'product': entry.key,
          'movementCount': entry.value,
        };
      }).toList();

      final top3Least = sortedEntries.reversed.take(3).map((entry) {
        return {
          'product': entry.key,
          'movementCount': entry.value,
        };
      }).toList();

      return {
        'mostMovements': top3Most,
        'leastMovements': top3Least,
      };
    } catch (e) {
      // Error fetching Movement: $e
      return {
        'mostMovements': [],
        'leastMovements': [],
      };
    }
  }

  Widget buildDrawerHeader() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Error loading profile');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final profileImageURL = data?['profileImage'] ?? "";
        final profileName = data?['name'] ?? "Profile Name";
        final email = data?['email'] ?? "";

        return Container(
          color: const Color(0xFF213A57), // Background color
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: profileImageURL.isNotEmpty
                    ? NetworkImage(profileImageURL) as ImageProvider
                    : AssetImage('assets/default_profile.png'),
                child: profileImageURL.isEmpty
                    ? const Icon(
                        Icons.account_circle,
                        size: 50,
                        color: Color(0xFF213A57),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                profileName,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _scanAndFindProduct() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        String scannedBarcode = result.rawContent;
        await _findProductByBarcode(scannedBarcode);
      } else {
        _showDialog("No barcode detected", "Please try scanning again.");
      }
    } catch (e) {
      _showDialog("Error", "An error occurred while scanning: $e");
    }
  }

  Future<void> _findProductByBarcode(String barcode) async {
    try {
      // Create a base query
      Query query = FirebaseFirestore.instance
          .collection('Product')
          .where('barcode', isEqualTo: barcode);

      // Apply additional filtering based on user mode
      if (_userMode == 'organization') {
        query = query.where('company_name', isEqualTo: _companyName);
      } else {
        query = query.where('userId', isEqualTo: _userId);
      }

      // Execute the query
      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        final product = querySnapshot.docs.first.data() as Map<String, dynamic>;
        _showProductDetails(product);
      } else {
        _showDialog("Product Not Found",
            "No product matches the scanned barcode or access denied.");
      }
    } catch (e) {
      _showDialog(
          "Error", "An error occurred while searching for the product: $e");
    }
  }

  Future<void> _displayAnalyticsDialog() async {
    try {
      // Fetch analytics data with user-specific filtering
      final analyticsData = await _fetchUserSpecificMovementAnalytics();
      final mostMovements = analyticsData['mostMovements']!;
      final leastMovements = analyticsData['leastMovements']!;

      // Call the showAnalytics function with filtered data
      showAnalytics("Analytics", mostMovements, leastMovements);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("An error occurred: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    final imageUrl =
        product['imageUrl']; // Get the image URL from the product data

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              product['name'] ?? 'Product Details',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the image if the URL is available
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Center(
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text("Image not available"));
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                // Display the product details with bolded labels
                _buildDetailRow("Name", product['name'] ?? 'N/A'),
                _buildDetailRow(
                    "Quantity", product['quantity']?.toString() ?? 'N/A'),
                _buildDetailRow("Price", "\$${product['price'] ?? 'N/A'}"),
                _buildDetailRow("Description", product['description'] ?? 'N/A'),
                _buildDetailRow(
                    "Threshold", product['threshold']?.toString() ?? 'N/A'),
                _buildDetailRow(
                  "Added At",
                  product['addedAt'] != null
                      ? (product['addedAt'] as Timestamp).toDate().toString()
                      : 'N/A',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget buildDashboardView() {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF213A57), Color(0xFF0AD1C8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Align items on both ends
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          size: 32,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // You can add your menu functionality here
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Shelf-It',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Search Icon on the right
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                        onPressed:
                            _scanAndFindProduct, // Calls the scanning function
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildInventorySummaryCard(),
                  const SizedBox(height: 20),
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      GestureDetector(
                        onTap: () => showTransactions(context),
                        child: buildDashboardCard(
                          Icons.swap_horiz,
                          "Updates",
                          "See quantity updates and movements",
                          const Color.fromARGB(255, 27, 202, 241),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showItemFlow(context),
                        child: buildDashboardCard(
                          Icons.show_chart,
                          "Item Flow",
                          "View all inflows and outflows",
                          const Color(0xFF45DFB1),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showLowStock(context),
                        child: buildLowStockCard(),
                      ),
                      GestureDetector(
                        onTap: () => _displayAnalyticsDialog(),
                        child: buildDashboardCard(
                          Icons.analytics,
                          "Movements",
                          "Show movements of top items",
                          const Color(0xFF80ED99),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Recent Products",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildRecentProducts(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInventorySummaryCard() {
    Query query = FirebaseFirestore.instance.collection('Product');

    if (_userMode == 'organization') {
      query = query.where('company_name', isEqualTo: _companyName);
    } else {
      query = query.where('userId', isEqualTo: _userId);
    }

    return Card(
      color: const Color(0xFF80ED99),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No data available"));
            }

            final products = snapshot.data!.docs;
            int totalItems = products.length;
            int totalQuantity = 0;
            double totalPrice = 0.0;

            for (var product in products) {
              int quantity = int.tryParse(product['quantity'].toString()) ?? 0;
              double price =
                  double.tryParse(product['price'].toString()) ?? 0.0;

              totalQuantity += quantity;
              totalPrice += price * quantity;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory, size: 32, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text(
                      "Inventory Summary",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Items: $totalItems",
                    style: const TextStyle(color: Colors.black)),
                Text("Total Quantity: $totalQuantity",
                    style: const TextStyle(color: Colors.black)),
                Text("Total Value: \$${totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.black)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildRecentProducts() {
    Query query = FirebaseFirestore.instance
        .collection('Product')
        .orderBy('addedAt', descending: true)
        .limit(5);

    if (_userMode == 'organization') {
      query = query.where('company_name', isEqualTo: _companyName);
    } else {
      query = query.where('userId', isEqualTo: _userId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No Products",
            style: TextStyle(color: Colors.white70),
          );
        }

        final recentProducts = snapshot.data!.docs;

        return Column(
          children: recentProducts.map((product) {
            final name = product['name'] ?? 'No Name';
            final quantity = product['quantity']?.toString() ?? '0';

            return ListTile(
              contentPadding: const EdgeInsets.all(0),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Quantity: $quantity',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildDashboardCard(
      IconData icon, String title, String description, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                maxLines: 3, // Limits the text to 3 lines
                overflow:
                    TextOverflow.ellipsis, // Adds "..." if text is too long
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLowStockCard() {
    return Card(
      color: const Color.fromARGB(255, 244, 78, 81),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.warning, size: 32, color: Colors.black),
            SizedBox(height: 8),
            Text(
              "Low Stock",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 8),
            Text("View Products that are low stock",
                style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }

  void showTransactions(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Query the most recently updated products
    Query query = FirebaseFirestore.instance
        .collection('Product')
        .orderBy('updatedAt', descending: true) // Sort by updatedAt
        .limit(3); // Limit to 3 products

    // Filter based on organization or individual mode
    if (_userMode == 'organization') {
      query = query.where('company_name', isEqualTo: _companyName);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Recent Updates"),
          content: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(), // Stream updates from Firestore
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "No recent updates found.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final recentProducts = snapshot.data!.docs;

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recentProducts.length,
                  itemBuilder: (context, index) {
                    final productData =
                        recentProducts[index].data() as Map<String, dynamic>;

                    final name = productData['name'] ?? 'Unnamed Product';
                    final quantity = productData['quantity'] ?? 0;
                    final updatedAt = productData['updatedAt']?.toDate();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Quantity: $quantity',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (updatedAt != null)
                            Text(
                              'Last Updated: ${updatedAt.toLocal()}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void showItemFlow(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (context) {
        Query query = FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(5);

        return AlertDialog(
          title: const Text("Item Flow"),
          content: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SizedBox(
                  height: 50, // Constrain the size of the no-data message
                  child: const Center(
                    child: Text("No item flow data found.,",
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final transactions = snapshot.data!.docs;

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transactionData =
                        transactions[index].data() as Map<String, dynamic>;

                    final action = transactionData['action'] ?? 'unknown';
                    final product = transactionData['product'] ?? 'Unknown';
                    final quantity = transactionData['quantity'] ?? 0;

                    String displayChange;
                    if (action == 'Restock') {
                      displayChange = '+$quantity pcs';
                    } else if (action == 'Sold') {
                      displayChange = '-$quantity pcs';
                    } else {
                      displayChange = 'Invalid Action';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            displayChange,
                            style: TextStyle(
                              color: (action == 'Restock')
                                  ? Colors.green
                                  : (action == 'Sold')
                                      ? Colors.red
                                      : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void showLowStock(BuildContext context) {
    const dialogTitle = Text(
      "Low Stock Items",
      style: TextStyle(fontSize: 24.0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Ensures the dialog doesn't take full screen
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dialogTitle,
                SizedBox(height: 10.0),
                SizedBox(
                  width: double.maxFinite,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('Product')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Text('Error loading low-stock items.');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No products available.');
                      }

                      var products = snapshot.data!.docs;

                      // Filter products based on user mode and low stock
                      var lowStockProducts = products.where((product) {
                        var data = product.data() as Map<String, dynamic>?;

                        if (data == null) return false;

                        int quantity =
                            int.tryParse(data['quantity']?.toString() ?? '0') ??
                                0;
                        int threshold = int.tryParse(
                                data['threshold']?.toString() ?? '0') ??
                            0;

                        bool isLowStock = quantity <= threshold;

                        // Apply filters based on user mode
                        if (_userMode == 'organization') {
                          return isLowStock &&
                              data['company_name'] == _companyName;
                        } else if (_userMode == 'personal') {
                          return isLowStock && data['userId'] == _userId;
                        }
                        return false;
                      }).toList();

                      int lowStockCount = lowStockProducts.length;

                      if (lowStockCount == 0) {
                        return const Center(
                            child: Text('No low-stock items currently.',
                                style: TextStyle(color: Colors.grey)));
                      }

                      // Display the first 5 low-stock products
                      var topLowStockProducts =
                          lowStockProducts.take(5).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Products: $lowStockCount',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10.0),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: topLowStockProducts.length,
                            itemBuilder: (context, index) {
                              var product = topLowStockProducts[index];
                              var data =
                                  product.data() as Map<String, dynamic>?;

                              String name =
                                  data != null && data.containsKey('name')
                                      ? data['name']
                                      : 'Unknown Item';
                              int quantity = data != null &&
                                      data.containsKey('quantity')
                                  ? int.tryParse(data['quantity'].toString()) ??
                                      0
                                  : 0;
                              int? threshold = data != null &&
                                      data.containsKey('threshold')
                                  ? int.tryParse(data['threshold'].toString())
                                  : null;

                              return ListTile(
                                title: Text(name),
                                subtitle: Text(
                                  'Stock: $quantity | Threshold: ${threshold ?? 'Not Set'}',
                                ),
                                leading: Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAnalytics(String title, List<Map<String, dynamic>> mostMovements,
      List<Map<String, dynamic>> leastMovements) {
    showDialog(
      context: context,
      builder: (context) {
        // Check if both mostMovements and leastMovements are empty
        final hasNoMovements = mostMovements.isEmpty && leastMovements.isEmpty;

        return AlertDialog(
          title: Text('Movements'),
          content: SingleChildScrollView(
            child: hasNoMovements
                ? const Center(
                    child: Text(
                      "No Product Movements",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top 3 Products with Most Movements:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...mostMovements.map((product) => Text(
                            "${product['product']}: ${product['movementCount']} movements",
                          )),
                      const SizedBox(height: 16),
                      const Text(
                        "Top 3 Products with Least Movements:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...leastMovements.map((product) => Text(
                            "${product['product']}: ${product['movementCount']} movements",
                          )),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text("Log Out"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required String name,
    required String facebook,
    required String instagram,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.facebook, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(facebook)),
                  child: Text(
                    facebook,
                    style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.camera_alt, size: 16, color: Colors.pink),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(instagram)),
                  child: Text(
                    instagram,
                    style: const TextStyle(
                        color: Colors.pink,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enlarged profile header with StreamBuilder for real-time updates
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: const Color(0xFF213A57),
                      width: double.infinity,
                      height: 150,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return Container(
                      color: const Color(0xFF213A57),
                      width: double.infinity,
                      height: 150,
                      child: const Center(
                        child: Text(
                          'Error loading profile',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final profileImageURL = data?['profileImage'] ?? "";
                  final profileName = data?['name'] ?? "Profile Name";
                  final email = data?['email'] ?? "";

                  return Container(
                    color: const Color(0xFF213A57), // Background color
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: (profileImageURL.isNotEmpty)
                              ? NetworkImage(profileImageURL) as ImageProvider
                              : const AssetImage('assets/profile.png'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profileName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Section 1: User Profile and Company Details
              const SizedBox(height: 16),
              Card(
                color: const Color.fromARGB(255, 208, 248, 225),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Column(
                    children: [
                      DrawerButton(
                        text: 'User Profile',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      if (_userMode == 'organization')
                        DrawerButton(
                          text: 'Company Details',
                          icon: Icons.business,
                          onTap: () {
                            if (_companyName != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => companydetailsPage(
                                      companyName: _companyName!),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Company name not available')),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Section 2: Transactions and Analytics
              Card(
                color: const Color.fromARGB(255, 208, 248, 225),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Column(
                    children: [
                      DrawerButton(
                        text: 'Transactions',
                        icon: Icons.swap_horiz,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TransactionPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      DrawerButton(
                        text: 'Inventory Analytics',
                        icon: Icons.analytics,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AnalyticsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Section 3: About and Contact
              Card(
                color: const Color.fromARGB(255, 208, 248, 225),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Column(
                    children: [
                      DrawerButton(
                        text: 'About Shelf It',
                        icon: Icons.info_outline,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("About Shelf It"),
                              content: const Text(
                                "Shelf-It is a innovative inventory management system designed to help businesses optimize operations and increase efficiency.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      DrawerButton(
                        text: 'Contact Us',
                        icon: Icons.contact_mail,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Contact Us"),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                        "For general inquiries, Contact us at:"),
                                    const Text(
                                      "Team Members",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    _buildContactInfo(
                                      name: "Mark Real",
                                      facebook:
                                          "https://web.facebook.com/real.DEV.mark",
                                      instagram:
                                          "https://instagram.com/krm.real/",
                                    ),
                                    _buildContactInfo(
                                      name: "Raven Moral",
                                      facebook:
                                          "https://web.facebook.com/ravenmarkk",
                                      instagram:
                                          "https://www.instagram.com/koron1s/",
                                    ),
                                    _buildContactInfo(
                                      name: "Jahred Vapor",
                                      facebook:
                                          "https://web.facebook.com/jahred.myidol",
                                      instagram:
                                          "https://www.instagram.com/your__1d0l/",
                                    ),
                                    _buildContactInfo(
                                      name: "Tristan Faicol",
                                      facebook:
                                          "https://web.facebook.com/profile.php?id=100074082160492",
                                      instagram:
                                          "https://www.instagram.com/crpz333/",
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Logout Button
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF213A57),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: _logout,
                  child: const Text(
                    "Log Out",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: buildDashboardView()),
          BottomNavigationBar(
            backgroundColor: const Color(0xFF0B6477),
            selectedItemColor: const Color(0xFF45DFB1),
            unselectedItemColor: Colors.black,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.inventory), label: 'Products'),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_outlined), label: 'Stock Levels'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.assignment), label: 'Order'),
            ],
          )
        ],
      ),
    );
  }
}

class DrawerButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const DrawerButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
