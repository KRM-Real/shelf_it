import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class BarcodeScannerService {
  static Future<void> scanAndFindProduct(
    BuildContext context, {
    String? userMode,
    String? companyName,
    String? userId,
  }) async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        String scannedBarcode = result.rawContent;
        await _findProductByBarcode(
          context,
          scannedBarcode,
          userMode: userMode,
          companyName: companyName,
          userId: userId,
        );
      } else {
        _showDialog(
          context,
          "No barcode detected",
          "Please try scanning again.",
        );
      }
    } catch (e) {
      _showDialog(context, "Error", "An error occurred while scanning: $e");
    }
  }

  static Future<void> _findProductByBarcode(
    BuildContext context,
    String barcode, {
    String? userMode,
    String? companyName,
    String? userId,
  }) async {
    try {
      // Create a base query
      Query query = FirebaseFirestore.instance
          .collection('Product')
          .where('barcode', isEqualTo: barcode);

      // Apply additional filtering based on user mode
      if (userMode == 'organization') {
        query = query.where('company_name', isEqualTo: companyName);
      } else {
        query = query.where('userId', isEqualTo: userId);
      }

      // Execute the query
      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        final product = querySnapshot.docs.first.data() as Map<String, dynamic>;
        _showProductDetails(context, product);
      } else {
        _showDialog(
          context,
          "Product Not Found",
          "No product matches the scanned barcode or access denied.",
        );
      }
    } catch (e) {
      _showDialog(
        context,
        "Error",
        "An error occurred while searching for the product: $e",
      );
    }
  }

  static void _showProductDetails(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final imageUrl = product['imageUrl'];

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
                        return const Center(child: CircularProgressIndicator());
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
                  "Quantity",
                  product['quantity']?.toString() ?? 'N/A',
                ),
                _buildDetailRow("Price", "\$${product['price'] ?? 'N/A'}"),
                _buildDetailRow("Description", product['description'] ?? 'N/A'),
                _buildDetailRow(
                  "Threshold",
                  product['threshold']?.toString() ?? 'N/A',
                ),
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

  static Widget _buildDetailRow(String label, String value) {
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

  static void _showDialog(BuildContext context, String title, String content) {
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
}
