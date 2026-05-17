import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusTicks extends StatelessWidget {
  final String status;
  const StatusTicks({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'sending':
        return const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
        );
      case 'sent':
        return const Icon(Icons.check, size: 13, color: Colors.white54);
      case 'delivered':
        return const Icon(Icons.done_all, size: 13, color: Colors.white54);
      case 'read':
        return Icon(Icons.done_all, size: 13, color: kPrimary.withOpacity(0.9));
      default:
        return const SizedBox.shrink();
    }
  }
}