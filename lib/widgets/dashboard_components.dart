import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardComponents {
  // Stats Card Component
  static Widget buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Inventory Health Card Component
  static Widget buildInventoryHealthCard(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 20,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Inventory Health",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildHealthIndicator(
                  "85%",
                  "Healthy",
                  const Color(0xFF4CAF50),
                ),
                _buildHealthIndicator(
                  "12%",
                  "Low Stock",
                  const Color(0xFFFFC107),
                ),
                _buildHealthIndicator(
                  "3%",
                  "Out of Stock",
                  const Color(0xFFF44336),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHealthIndicator(
    String percentage,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                percentage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Dashboard Action Card Component
  static Widget buildDashboardCard(
    IconData icon,
    String title,
    String description,
    Color color,
    BuildContext context,
  ) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Low Stock Card Component
  static Widget buildLowStockCard(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              "Low Stock",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View Products that are low stock",
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Header Component
  static Widget buildModernHeader(
    BuildContext context,
    GlobalKey<ScaffoldState> scaffoldKey,
    VoidCallback onScanTap,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                scaffoldKey.currentState?.openDrawer();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Shelf-It',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onScanTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Products Component
  static Widget buildRecentProducts(
    String? userMode,
    String? companyName,
    String? userId,
  ) {
    Query query = FirebaseFirestore.instance
        .collection('Product')
        .orderBy('addedAt', descending: true)
        .limit(5);

    if (userMode == 'organization') {
      query = query.where('company_name', isEqualTo: companyName);
    } else {
      query = query.where('userId', isEqualTo: userId);
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
          return const Center(
            child: Text(
              "No recent products found",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final recentProducts = snapshot.data!.docs;

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: recentProducts.map((product) {
                final name = product['name'] ?? 'No Name';
                final quantity = product['quantity']?.toString() ?? '0';

                return ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  subtitle: Text(
                    'Quantity: $quantity',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Product Detail Row Helper
  static Widget buildDetailRow(String label, String value) {
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
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
