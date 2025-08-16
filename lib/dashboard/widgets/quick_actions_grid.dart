import 'package:flutter/material.dart';
import '../dialogs/dashboard_dialogs.dart';

class DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  final String? userMode;
  final String? companyName;
  final String? userId;
  final Function(String, List<Map<String, dynamic>>, List<Map<String, dynamic>>)
  showAnalytics;

  const QuickActionsGrid({
    super.key,
    this.userMode,
    this.companyName,
    this.userId,
    required this.showAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DashboardActionCard(
              icon: Icons.swap_horiz,
              title: "Updates",
              description: "See quantity updates and movements",
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              onTap: () => DashboardDialogs.showTransactions(
                context,
                userMode: userMode,
                companyName: companyName,
                userId: userId,
              ),
            ),
            DashboardActionCard(
              icon: Icons.show_chart,
              title: "Item Flow",
              description: "View all inflows and outflows",
              color: const Color(0xFF607D8B),
              onTap: () => DashboardDialogs.showItemFlow(context),
            ),
            DashboardActionCard(
              icon: Icons.warning,
              title: "Low Stock",
              description: "View Products that are low stock",
              color: const Color(0xFFE57373),
              onTap: () => DashboardDialogs.showLowStock(
                context,
                userMode: userMode,
                companyName: companyName,
                userId: userId,
              ),
            ),
            DashboardActionCard(
              icon: Icons.analytics,
              title: "Movements",
              description: "Show movements of top items",
              color: const Color(0xFF78909C),
              onTap: () => _displayAnalyticsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _displayAnalyticsDialog(BuildContext context) async {
    try {
      final analyticsData =
          await DashboardDialogs.fetchUserSpecificMovementAnalytics(userId);
      final mostMovements = analyticsData['mostMovements']!;
      final leastMovements = analyticsData['leastMovements']!;

      showAnalytics("Analytics", mostMovements, leastMovements);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("An error occurred: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    }
  }
}
