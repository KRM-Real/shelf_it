import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
}

class StatsCardsRow extends StatelessWidget {
  const StatsCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: "TOTAL ITEMS",
            value: "1,247",
            icon: Icons.inventory_2,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: "LOW STOCK",
            value: "23",
            icon: Icons.warning,
            color: const Color(0xFFF44336),
          ),
        ),
      ],
    );
  }
}
