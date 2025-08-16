import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch user mode and company information
  static Future<Map<String, dynamic>?> fetchUserMode() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final userSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        final data = userSnapshot.data();
        return {
          'userMode': data?['mode'] ?? 'individual',
          'companyName': data?['company_name'],
          'userId': userId,
        };
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
    return null;
  }

  // Fetch user-specific movement analytics
  static Future<Map<String, List<Map<String, dynamic>>>>
  fetchUserSpecificMovementAnalytics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {'mostMovements': [], 'leastMovements': []};

      final transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      if (transactions.docs.isEmpty) {
        return {'mostMovements': [], 'leastMovements': []};
      }

      Map<String, int> movementCounts = {};

      for (var doc in transactions.docs) {
        final data = doc.data();
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

  // Find product by barcode
  static Future<Map<String, dynamic>?> findProductByBarcode(
    String barcode,
    String? userMode,
    String? companyName,
    String? userId,
  ) async {
    try {
      Query query = _firestore
          .collection('Product')
          .where('barcode', isEqualTo: barcode);

      if (userMode == 'organization') {
        query = query.where('company_name', isEqualTo: companyName);
      } else {
        query = query.where('userId', isEqualTo: userId);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      throw Exception('Error searching for product: $e');
    }
    return null;
  }

  // Get inventory summary
  static Stream<Map<String, dynamic>> getInventorySummary(
    String? userMode,
    String? companyName,
    String? userId,
  ) {
    Query query = _firestore.collection('Product');

    if (userMode == 'organization') {
      query = query.where('company_name', isEqualTo: companyName);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return {'totalItems': 0, 'totalQuantity': 0, 'totalValue': 0.0};
      }

      int totalItems = snapshot.docs.length;
      int totalQuantity = 0;
      double totalValue = 0.0;

      for (var product in snapshot.docs) {
        final data = product.data() as Map<String, dynamic>;
        int quantity = int.tryParse(data['quantity'].toString()) ?? 0;
        double price = double.tryParse(data['price'].toString()) ?? 0.0;

        totalQuantity += quantity;
        totalValue += price * quantity;
      }

      return {
        'totalItems': totalItems,
        'totalQuantity': totalQuantity,
        'totalValue': totalValue,
      };
    });
  }

  // Get recent transactions for item flow
  static Stream<QuerySnapshot> getRecentTransactions(String? userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  // Get recently updated products
  static Stream<QuerySnapshot> getRecentUpdatedProducts(
    String? userMode,
    String? companyName,
    String? userId,
  ) {
    Query query = _firestore
        .collection('Product')
        .orderBy('updatedAt', descending: true)
        .limit(3);

    if (userMode == 'organization') {
      query = query.where('company_name', isEqualTo: companyName);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots();
  }

  // Get low stock products
  static Stream<List<QueryDocumentSnapshot>> getLowStockProducts(
    String? userMode,
    String? companyName,
    String? userId,
  ) {
    return _firestore.collection('Product').snapshots().map((snapshot) {
      return snapshot.docs.where((product) {
        final data = product.data() as Map<String, dynamic>?;
        if (data == null) return false;

        int quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
        int threshold = int.tryParse(data['threshold']?.toString() ?? '0') ?? 0;
        bool isLowStock = quantity <= threshold;

        if (userMode == 'organization') {
          return isLowStock && data['company_name'] == companyName;
        } else {
          return isLowStock && data['userId'] == userId;
        }
      }).toList();
    });
  }
}
