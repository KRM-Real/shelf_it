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
      final querySnapshot =
          await FirebaseFirestore.instance.collection('transactions').get();

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
        productData.sort((a, b) =>
            b['movements'].compareTo(a['movements'])); // Sort descending
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching transaction data: $e");
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
            color: Colors.green, // Bar color
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Inventory Analytics', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF213A57),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Color(0xFFE6F2F0),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Graph Section
                Container(
                  padding: const EdgeInsets.all(
                      16), // Padding to avoid touching corners
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.grey,
                        width: 1), // Border around the graph
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  child: SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        barGroups: getBarChartData(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
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
                                if (index < 0 || index >= productData.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  productData[index]['name'],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true, // Enables a grid border
                          border: const Border.symmetric(
                            horizontal:
                                BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        barTouchData: BarTouchData(
                          enabled: false, // Disable touch tooltips
                        ),
                      ),
                    ),
                  ),
                ),

                // Display Summary
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard(
                        label: 'Total Products',
                        value: productData.length.toString(),
                        color: const Color.fromARGB(255, 1, 163, 7),
                      ),
                      _buildSummaryCard(
                        label: 'Total Movements',
                        value: productData
                            .fold<int>(
                              0,
                              (sum, item) =>
                                  sum + (item['movements'] ?? 0) as int,
                            )
                            .toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),

                // Product List Section
                Expanded(
                  child: ListView.builder(
                    itemCount: productData.length,
                    itemBuilder: (context, index) {
                      final product = productData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              product['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            product['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Movements: ${product['movements']}"),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
      {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
