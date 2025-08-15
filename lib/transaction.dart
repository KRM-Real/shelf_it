// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  // Fetch transactions from Firestore
  Stream<List<TransactionModel>> fetchTransactions() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    var query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true);

    if (_startDate != null && _endDate != null) {
      final adjustedEndDate =
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromDocument(doc))
        .toList());
  }

  // Export transactions to PDF
  Future<void> exportTransactionsToPDF(
      List<TransactionModel> transactions) async {
    try {
      final pdf = pw.Document();
      final font = pw.Font.times();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Transactions',
                    style: pw.TextStyle(font: font, fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'Product Name',
                    'Quantity',
                    'Price',
                    'Date',
                    'Action'
                  ],
                  data: transactions.map((transaction) {
                    return [
                      transaction.productName,
                      transaction.quantity.toString(),
                      '\$${(transaction.amount * transaction.quantity).toStringAsFixed(2)}', // Total Amount
                      transaction.dateFormatted,
                      transaction.action,
                    ];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/transactions.pdf");
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'transactions.pdf');
      print("PDF exported successfully.");
    } catch (e) {
      print("Error exporting PDF: $e");
    }
  }

  // Date range picker
  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF213A57),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            color: Colors.white,
            onPressed: _pickDateRange,
          ),
        ],
      ),
      backgroundColor: Color(0xFFE6F2F0),
      body: StreamBuilder<List<TransactionModel>>(
        stream: fetchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          final transactions = snapshot.data!;

          return Container(
            color: Color(
                0xFFE6F2F0), // Set background color as per your requirement
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10.0), // Rounded corners
                            ),
                            margin: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 15.0), // Card margin
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  10.0), // Padding inside the card
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                            "Quantity: ${transaction.quantity}"),
                                        Text("Action: ${transaction.action}"),
                                        Text(
                                            "Date: ${transaction.dateFormatted}"),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '\$${(transaction.amount * transaction.quantity).toStringAsFixed(2)}', // Total Amount
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: transaction.action == "Restock"
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20, // Position button 20 pixels from the bottom
                  left: 0,
                  right: 0, // Make the button take full width of the screen
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () => exportTransactionsToPDF(transactions),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Black button
                        foregroundColor: Colors.white, // White text
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                      ),
                      child: const Text("Export to PDF"),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TransactionModel {
  final String id;
  final String productName;
  final double amount;
  final int quantity;
  final DateTime timestamp;
  final String action; // "Restock" or "Sold"

  TransactionModel({
    required this.id,
    required this.productName,
    required this.amount,
    required this.quantity,
    required this.timestamp,
    required this.action,
  });

  String get dateFormatted {
    return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
  }

  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      productName: data['product'] ?? 'Unnamed Product',
      amount: (data['price'] != null ? (data['price'] as num).toDouble() : 0.0),
      quantity: (data['quantity'] != null ? data['quantity'] as int : 1),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      action: data['action'] ?? 'Sold', // Default to "Sold" if missing
    );
  }
}
