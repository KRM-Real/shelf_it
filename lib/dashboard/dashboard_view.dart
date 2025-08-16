import 'package:flutter/material.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stats_cards.dart';
import 'widgets/inventory_health_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_products_widget.dart';
import 'dialogs/dashboard_dialogs.dart';

class DashboardView extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onRefresh;
  final VoidCallback onScanPressed;
  final String? userMode;
  final String? companyName;
  final String? userId;

  const DashboardView({
    super.key,
    required this.scaffoldKey,
    required this.onRefresh,
    required this.onScanPressed,
    this.userMode,
    this.companyName,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0F2F5), // Soft light gray
                Color(0xFFE8F4FD), // Muted light blue
                Color(0xFFECEFF1), // Warm light gray
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Header Card
                  DashboardHeader(
                    scaffoldKey: scaffoldKey,
                    onScanPressed: onScanPressed,
                  ),
                  const SizedBox(height: 20),

                  // Title Section
                  _buildTitleSection(),
                  const SizedBox(height: 24),

                  // Stats Cards Row
                  const StatsCardsRow(),
                  const SizedBox(height: 24),

                  // Inventory Health Card
                  const InventoryHealthCard(),
                  const SizedBox(height: 24),

                  // Quick Actions Grid
                  QuickActionsGrid(
                    userMode: userMode,
                    companyName: companyName,
                    userId: userId,
                    showAnalytics: (title, mostMovements, leastMovements) {
                      DashboardDialogs.showAnalytics(
                        context,
                        title,
                        mostMovements,
                        leastMovements,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Recent Products
                  RecentProductsWidget(
                    userMode: userMode,
                    companyName: companyName,
                    userId: userId,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Overview of your inventory performance",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
