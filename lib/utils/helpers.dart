import 'package:intl/intl.dart';

String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

String formatChatTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return DateFormat('EEE').format(dt);
  return DateFormat('MM/dd/yy').format(dt);
}

String initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  if (name.isNotEmpty) return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  return '??';
}