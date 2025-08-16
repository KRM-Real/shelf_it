import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dashboard_service.dart';
import '../widgets/dashboard_components.dart';

class DashboardDialogs {
  // Show product details dialog
  static void showProductDetails(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final imageUrl = product['imageUrl'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                // Display the image if available
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text("Image not available"),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Product details
                DashboardComponents.buildDetailRow(
                  "Name",
                  product['name'] ?? 'N/A',
                ),
                DashboardComponents.buildDetailRow(
                  "Quantity",
                  product['quantity']?.toString() ?? 'N/A',
                ),
                DashboardComponents.buildDetailRow(
                  "Price",
                  "\$${product['price'] ?? 'N/A'}",
                ),
                DashboardComponents.buildDetailRow(
                  "Description",
                  product['description'] ?? 'N/A',
                ),
                DashboardComponents.buildDetailRow(
                  "Threshold",
                  product['threshold']?.toString() ?? 'N/A',
                ),
                DashboardComponents.buildDetailRow(
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Show analytics dialog
  static void showAnalyticsDialog(BuildContext context) async {
    try {
      final analyticsData =
          await DashboardService.fetchUserSpecificMovementAnalytics();
      final mostMovements = analyticsData['mostMovements']!;
      final leastMovements = analyticsData['leastMovements']!;

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          final hasNoMovements =
              mostMovements.isEmpty && leastMovements.isEmpty;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Product Movements',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: hasNoMovements
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "No Product Movements",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mostMovements.isNotEmpty) ...[
                          const Text(
                            "Top 3 Products with Most Movements:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...mostMovements.map(
                            (product) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Text(
                                "• ${product['product']}: ${product['movementCount']} movements",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (leastMovements.isNotEmpty) ...[
                          const Text(
                            "Top 3 Products with Least Movements:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...leastMovements.map(
                            (product) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Text(
                                "• ${product['product']}: ${product['movementCount']} movements",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                ),
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, "Error", "An error occurred: $e");
    }
  }

  // Show recent transactions dialog
  static void showTransactionsDialog(
    BuildContext context,
    String? userMode,
    String? companyName,
    String? userId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Recent Updates",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StreamBuilder<QuerySnapshot>(
            stream: DashboardService.getRecentUpdatedProducts(
              userMode,
              companyName,
              userId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      "No recent updates found.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final recentProducts = snapshot.data!.docs;

              return SizedBox(
                width: double.maxFinite,
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recentProducts.length,
                  itemBuilder: (context, index) {
                    final productData =
                        recentProducts[index].data() as Map<String, dynamic>;
                    final name = productData['name'] ?? 'Unnamed Product';
                    final quantity = productData['quantity'] ?? 0;
                    final updatedAt = productData['updatedAt']?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: $quantity'),
                            if (updatedAt != null)
                              Text(
                                'Updated: ${updatedAt.toLocal().toString().split('.')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Show item flow dialog
  static void showItemFlowDialog(BuildContext context, String? userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Item Flow",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StreamBuilder<QuerySnapshot>(
            stream: DashboardService.getRecentTransactions(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(
                  height: 100,
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
                height: 200,
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
                    Color changeColor;
                    IconData changeIcon;

                    if (action == 'Restock') {
                      displayChange = '+$quantity pcs';
                      changeColor = Colors.green;
                      changeIcon = Icons.add;
                    } else if (action == 'Sold') {
                      displayChange = '-$quantity pcs';
                      changeColor = Colors.red;
                      changeIcon = Icons.remove;
                    } else {
                      displayChange = 'Invalid Action';
                      changeColor = Colors.grey;
                      changeIcon = Icons.help;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: Icon(changeIcon, color: changeColor),
                        title: Text(
                          product,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          displayChange,
                          style: TextStyle(
                            color: changeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Show low stock dialog
  static void showLowStockDialog(
    BuildContext context,
    String? userMode,
    String? companyName,
    String? userId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Low Stock Items",
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: DashboardService.getLowStockProducts(
                      userMode,
                      companyName,
                      userId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading low-stock items.'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No low-stock items currently.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final lowStockProducts = snapshot.data!;
                      final displayProducts = lowStockProducts
                          .take(10)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Products: ${lowStockProducts.length}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: displayProducts.length,
                              itemBuilder: (context, index) {
                                final product = displayProducts[index];
                                final data =
                                    product.data() as Map<String, dynamic>;

                                final name = data['name'] ?? 'Unknown Item';
                                final quantity =
                                    int.tryParse(data['quantity'].toString()) ??
                                    0;
                                final threshold = int.tryParse(
                                  data['threshold'].toString(),
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
                                    title: Text(name),
                                    subtitle: Text(
                                      'Stock: $quantity | Threshold: ${threshold ?? 'Not Set'}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                    ),
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

  // Generic error dialog
  static void _showErrorDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Generic info dialog
  static void showInfoDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    _showErrorDialog(context, title, content);
  }
}
