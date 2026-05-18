class ChatModel {
  final String id;
  final String lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final String? lastMessageStatus;
  final dynamic lastMessageTimestamp;
  final dynamic unreadCount;
  final bool isGroup;
  final List<String> participants;
  final String? groupName;
  final String? groupAvatar;
  final List<String> archivedBy;

  ChatModel({
    required this.id,
    required this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageStatus,
    this.lastMessageTimestamp,
    this.unreadCount = 0,
    this.isGroup = false,
    required this.participants,
    this.groupName,
    this.groupAvatar,
    this.archivedBy = const [],
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageSenderName: map['lastMessageSenderName'],
      lastMessageStatus: map['lastMessageStatus'],
      lastMessageTimestamp: map['lastMessageTimestamp'],
      unreadCount: map['unreadCount'] ?? 0,
      isGroup: map['isGroup'] ?? false,
      participants: List<String>.from(map['participants'] ?? []),
      groupName: map['groupName'],
      groupAvatar: map['groupAvatar'],
      archivedBy: List<String>.from(map['archivedBy'] ?? []),
    );
  }

  String formattedTime() {
    if (lastMessageTimestamp == null) return '';
    try {
      final dt = (lastMessageTimestamp as dynamic).toDate() as DateTime;
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      }
      return '${dt.month}/${dt.day}/${dt.year.toString().substring(2)}';
    } catch (_) {
      return '';
    }
  }
}