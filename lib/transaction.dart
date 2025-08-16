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
      final adjustedEndDate = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      query = query
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate),
          );
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromDocument(doc))
          .toList(),
    );
  }

  // Export transactions to PDF
  Future<void> exportTransactionsToPDF(
    List<TransactionModel> transactions,
  ) async {
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
                pw.Text(
                  'Transactions Report',
                  style: pw.TextStyle(font: font, fontSize: 24),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'Product Name',
                    'Quantity',
                    'Price',
                    'Date',
                    'Action',
                  ],
                  data: transactions.map((transaction) {
                    return [
                      transaction.productName,
                      transaction.quantity.toString(),
                      '\$${(transaction.amount * transaction.quantity).toStringAsFixed(2)}',
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
        bytes: await pdf.save(),
        filename: 'transactions.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Transactions',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: _pickDateRange,
            tooltip: 'Filter by date range',
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearDateFilter,
              tooltip: 'Clear date filter',
            ),
        ],
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
        child: StreamBuilder<List<TransactionModel>>(
          stream: fetchTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Transactions Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _startDate != null || _endDate != null
                              ? 'No transactions found for the selected date range'
                              : 'Start making transactions to see them here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_startDate != null || _endDate != null) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _clearDateFilter,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Filter'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            final transactions = snapshot.data!;

            return Column(
              children: [
                // Date filter indicator
                if (_startDate != null && _endDate != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1565C0).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          color: Color(0xFF1565C0),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtered: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF1565C0),
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                // Transaction summary
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(20),
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transaction Summary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transactions.length} transactions found',
                              style: const TextStyle(
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

                // Transaction list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final isRestock = transaction.action == "Restock";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Transaction type indicator
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isRestock
                                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                                      : const Color(
                                          0xFFF44336,
                                        ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isRestock ? Icons.add : Icons.remove,
                                  color: isRestock
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFF44336),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Transaction details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isRestock
                                                ? const Color(
                                                    0xFF4CAF50,
                                                  ).withOpacity(0.1)
                                                : const Color(
                                                    0xFFF44336,
                                                  ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            transaction.action,
                                            style: TextStyle(
                                              color: isRestock
                                                  ? const Color(0xFF4CAF50)
                                                  : const Color(0xFFF44336),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Qty: ${transaction.quantity}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      transaction.dateFormatted,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${(transaction.amount * transaction.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isRestock
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFF44336),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${transaction.amount.toStringAsFixed(2)}/unit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
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
            );
          },
        ),
      ),

      // Floating action button for PDF export
      floatingActionButton: StreamBuilder<List<TransactionModel>>(
        stream: fetchTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox();
          }

          return FloatingActionButton.extended(
            onPressed: () => exportTransactionsToPDF(snapshot.data!),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.file_download),
            label: const Text(
              'Export PDF',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
