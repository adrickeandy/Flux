import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusTicks extends StatelessWidget {
  final String status;

  const StatusTicks({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'sending':
        return const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey);
      case 'sent':
        return const Icon(Icons.check_rounded, size: 12, color: Colors.grey);
      case 'delivered':
        return const Icon(Icons.done_all_rounded, size: 12, color: Colors.grey);
      case 'read':
        return const Icon(Icons.done_all_rounded, size: 12, color: Colors.white);
      default:
        return const SizedBox.shrink();
    }
  }
}