import 'package:flutter/material.dart';

/// Custom loading widgets for consistent UX across the app
class CustomLoading {
  /// Shimmer loading effect for cards
  static Widget shimmerCard({double height = 100, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Loading overlay for the entire screen
  static Widget overlay({String message = 'Loading...'}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact loading indicator for buttons
  static Widget button({Color? color}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlignmentTween(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).animate(
          CurvedAnimation(
            parent: AlwaysStoppedAnimation(1.0),
            curve: Curves.linear,
          ),
        ).drive(ColorTween(begin: color ?? Colors.white, end: color ?? Colors.white)),
      ),
    );
  }

  /// List item skeleton loader
  static Widget listItem() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.inventory, color: Colors.grey),
        ),
        title: Container(
          height: 16,
          width: double.infinity,
          color: Colors.grey[300],
        ),
        subtitle: Container(
          height: 12,
          width: 150,
          color: Colors.grey[300],
        ),
        trailing: Container(
          height: 20,
          width: 60,
          color: Colors.grey[300],
        ),
      ),
    );
  }
}

/// Performance-optimized error widget
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
