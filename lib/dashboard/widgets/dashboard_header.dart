import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onScanPressed;

  const DashboardHeader({
    super.key,
    required this.scaffoldKey,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                scaffoldKey.currentState?.openDrawer();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Shelf-It',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onScanPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
