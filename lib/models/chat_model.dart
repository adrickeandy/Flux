class ChatModel {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageStatus;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final bool isGroup;
  final List<String> participants;
  final String? groupName;
  final String? groupAvatar;
  final List<String> archivedBy;

  ChatModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    this.lastMessageSenderId,
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
    final rawUnread = map['unreadCount'];
    int unread = 0;
    if (rawUnread is int) unread = rawUnread;

    DateTime? ts;
    if (map['lastMessageTimestamp'] != null) {
      try { ts = (map['lastMessageTimestamp'] as dynamic).toDate(); } catch (_) {}
    }

    return ChatModel(
      id: id,
      name: map['groupName'] ?? map['name'] ?? '',
      avatar: map['groupAvatar'] ?? map['avatar'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageStatus: map['lastMessageStatus'],
      lastMessageTimestamp: ts,
      unreadCount: unread,
      isGroup: map['isGroup'] ?? false,
      participants: List<String>.from(map['participants'] ?? []),
      groupName: map['groupName'],
      groupAvatar: map['groupAvatar'],
      archivedBy: List<String>.from(map['archivedBy'] ?? []),
    );
  }
}