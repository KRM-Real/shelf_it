// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<Map<String, dynamic>> productData = []; // Stores aggregated product data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactionData();
  }

  Future<void> fetchTransactionData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .get();

      // Aggregate data by product
      final Map<String, Map<String, dynamic>> productMovements = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final productName = data['product']; // Field for product name
        final quantity = data['quantity']; // Field for quantity moved

        if (productMovements.containsKey(productName)) {
          productMovements[productName]!['movements'] += quantity;
        } else {
          productMovements[productName] = {
            'name': productName,
            'movements': quantity,
          };
        }
      }

      setState(() {
        productData = productMovements.values.toList();
        productData.sort(
          (a, b) => b['movements'].compareTo(a['movements']),
        ); // Sort descending
        isLoading = false;
      });
    } catch (e) {
      // Error fetching transaction data: $e
      setState(() {
        isLoading = false;
      });
    }
  }

  List<BarChartGroupData> getBarChartData() {
    return productData
        .take(5) // Limit to the top 5 products
        .toList() // Convert Iterable to List
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final product = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: product['movements'].toDouble(),
                color: const Color(0xFF1565C0), // Updated color
                width: 20,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Inventory Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8F4FD)],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.white, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Movement Analytics',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Track and analyze inventory movements',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Chart Section
                    if (productData.isNotEmpty) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1565C0,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.bar_chart,
                                      color: Color(0xFF1565C0),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Top Product Movements',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 280,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: getBarChartData(),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 ||
                                                index >= productData.length) {
                                              return const SizedBox();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                productData[index]['name'],
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.shade200,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                '${productData[group.x]['name']}\n${rod.toY.round()} movements',
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Total Products',
                              value: productData.length.toString(),
                              icon: Icons.inventory_2,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Total Movements',
                              value: productData
                                  .fold<int>(
                                    0,
                                    (sum, item) =>
                                        sum + (item['movements'] ?? 0) as int,
                                  )
                                  .toString(),
                              icon: Icons.trending_up,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Product List Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1565C0,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.list_alt,
                                        color: Color(0xFF1565C0),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Product Movement Details',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: productData.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.grey.shade200,
                                  height: 1,
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                itemBuilder: (context, index) {
                                  final product = productData[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF1565C0),
                                                const Color(0xFF42A5F5),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              product['name'][0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Movements: ${product['movements']}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1565C0,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${product['movements']}',
                                            style: const TextStyle(
                                              color: Color(0xFF1565C0),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                    ] else ...[
                      // Empty state
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Analytics Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start making transactions to see analytics data',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
