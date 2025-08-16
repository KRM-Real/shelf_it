import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentProductsWidget extends StatelessWidget {
  final String? userMode;
  final String? companyName;
  final String? userId;

  const RecentProductsWidget({
    super.key,
    this.userMode,
    this.companyName,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('Product')
        .orderBy('addedAt', descending: true)
        .limit(5);

    if (userMode == 'organization') {
      query = query.where('company_name', isEqualTo: companyName);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Products",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
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
                style: TextStyle(color: Colors.grey),
              );
            }

            final recentProducts = snapshot.data!.docs;

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: Theme.of(
                context,
              ).colorScheme.shadow.withOpacity(0.1),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
