import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusTicks extends StatelessWidget {
  final String status;
  final bool onPrimary;

  const StatusTicks({super.key, required this.status, this.onPrimary = true});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'sending':
        return SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: onPrimary ? Colors.white54 : Colors.grey,
          ),
        );
      case 'sent':
        return Icon(Icons.check, size: 13,
            color: onPrimary ? Colors.white54 : Colors.grey);
      case 'delivered':
        return Icon(Icons.done_all, size: 13,
            color: onPrimary ? Colors.white54 : Colors.grey);
      case 'read':
        return Icon(Icons.done_all, size: 13,
            color: onPrimary ? Colors.white : kPrimary);
      default:
        return const SizedBox.shrink();
    }
  }
}