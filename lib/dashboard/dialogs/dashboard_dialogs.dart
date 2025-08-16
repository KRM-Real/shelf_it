import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardDialogs {
  static Future<Map<String, List<Map<String, dynamic>>>>
  fetchUserSpecificMovementAnalytics(String? userId) async {
    try {
      if (userId == null) return {'mostMovements': [], 'leastMovements': []};

      // Fetch user-specific transactions
      QuerySnapshot transactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      if (transactions.docs.isEmpty) {
        return {'mostMovements': [], 'leastMovements': []};
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

      final sortedEntries = movementCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top3Most = sortedEntries.take(3).map((entry) {
        return {'product': entry.key, 'movementCount': entry.value};
      }).toList();

      final top3Least = sortedEntries.reversed.take(3).map((entry) {
        return {'product': entry.key, 'movementCount': entry.value};
      }).toList();

      return {'mostMovements': top3Most, 'leastMovements': top3Least};
    } catch (e) {
      return {'mostMovements': [], 'leastMovements': []};
    }
  }

  static void showTransactions(
    BuildContext context, {
    String? userMode,
    String? companyName,
    String? userId,
  }) {
    // Query the most recently updated products
    Query query = FirebaseFirestore.instance
        .collection('Product')
        .orderBy('updatedAt', descending: true)
        .limit(3);

    // Filter based on organization or individual mode
    if (userMode == 'organization') {
      query = query.where('company_name', isEqualTo: companyName);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Recent Updates"),
          content: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
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

  static void showItemFlow(BuildContext context) {
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
                return const SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      "No item flow data found.",
                      style: TextStyle(color: Colors.grey),
                    ),
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

  static void showLowStock(
    BuildContext context, {
    String? userMode,
    String? companyName,
    String? userId,
  }) {
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dialogTitle,
                const SizedBox(height: 10.0),
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
                        int threshold =
                            int.tryParse(
                              data['threshold']?.toString() ?? '0',
                            ) ??
                            0;

                        bool isLowStock = quantity <= threshold;

                        // Apply filters based on user mode
                        if (userMode == 'organization') {
                          return isLowStock &&
                              data['company_name'] == companyName;
                        } else if (userMode == 'personal') {
                          return isLowStock && data['userId'] == userId;
                        }
                        return false;
                      }).toList();

                      int lowStockCount = lowStockProducts.length;

                      if (lowStockCount == 0) {
                        return const Center(
                          child: Text(
                            'No low-stock items currently.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Display the first 5 low-stock products
                      var topLowStockProducts = lowStockProducts
                          .take(5)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Products: $lowStockCount',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10.0),
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
                              int quantity =
                                  data != null && data.containsKey('quantity')
                                  ? int.tryParse(data['quantity'].toString()) ??
                                        0
                                  : 0;
                              int? threshold =
                                  data != null && data.containsKey('threshold')
                                  ? int.tryParse(data['threshold'].toString())
                                  : null;

                              return ListTile(
                                title: Text(name),
                                subtitle: Text(
                                  'Stock: $quantity | Threshold: ${threshold ?? 'Not Set'}',
                                ),
                                leading: const Icon(
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
                const SizedBox(height: 10.0),
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

  static void showAnalytics(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> mostMovements,
    List<Map<String, dynamic>> leastMovements,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final hasNoMovements = mostMovements.isEmpty && leastMovements.isEmpty;

        return AlertDialog(
          title: const Text('Movements'),
          content: SingleChildScrollView(
            child: hasNoMovements
                ? const Center(
                    child: Text(
                      "No Product Movements",
                      style: TextStyle(color: Colors.grey),
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
                      ...mostMovements.map(
                        (product) => Text(
                          "${product['product']}: ${product['movementCount']} movements",
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Top 3 Products with Least Movements:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...leastMovements.map(
                        (product) => Text(
                          "${product['product']}: ${product['movementCount']} movements",
                        ),
                      ),
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
}
