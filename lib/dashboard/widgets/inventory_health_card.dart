import 'package:flutter/material.dart';

class InventoryHealthCard extends StatelessWidget {
  const InventoryHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 20,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Inventory Health",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthIndicator(
                    "85%",
                    "Healthy",
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildHealthIndicator(
                    "12%",
                    "Low Stock",
                    const Color(0xFFFFC107),
                  ),
                ),
                Expanded(
                  child: _buildHealthIndicator(
                    "3%",
                    "Out of Stock",
                    const Color(0xFFF44336),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String percentage, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              percentage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
