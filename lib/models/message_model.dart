class MessageModel {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final String timestamp;
  final String status;
  final String type;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final String? mimeType;
  final List<String> reactions;
  final bool isStarred;
  final ReplyInfo? replyTo;
  final Map<String, dynamic>? meta;

  MessageModel({
    required this.id,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.status = 'sent',
    this.type = 'text',
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.reactions = const [],
    this.isStarred = false,
    this.replyTo,
    this.meta,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    String timestamp = 'Sending...';
    if (map['timestamp'] != null) {
      try {
        final dt = (map['timestamp'] as dynamic).toDate() as DateTime;
        timestamp = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      timestamp: timestamp,
      status: map['status'] ?? 'sent',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      mimeType: map['mimeType'],
      reactions: List<String>.from(map['reactions'] ?? []),
      isStarred: map['isStarred'] ?? false,
      replyTo: map['replyTo'] != null ? ReplyInfo.fromMap(map['replyTo']) : null,
      meta: map['meta'],
    );
  }
}

class ReplyInfo {
  final String id;
  final String senderName;
  final String content;

  ReplyInfo({required this.id, required this.senderName, required this.content});

  factory ReplyInfo.fromMap(Map m) => ReplyInfo(
    id: m['id'] ?? '',
    senderName: m['senderName'] ?? '',
    content: m['content'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderName': senderName,
    'content': content,
  };
}