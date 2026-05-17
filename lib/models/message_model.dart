class MessageModel {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final String status;
  final String type;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final double? audioDuration;
  final List<String> reactions;
  final bool isStarred;
  final ReplyInfo? replyTo;

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
    this.audioDuration,
    this.reactions = const [],
    this.isStarred = false,
    this.replyTo,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as dynamic).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'sent',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      audioDuration: (map['audioDuration'] as num?)?.toDouble(),
      reactions: List<String>.from(map['reactions'] ?? []),
      isStarred: map['isStarred'] ?? false,
      replyTo: map['replyTo'] != null ? ReplyInfo.fromMap(map['replyTo']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'content': content,
    'timestamp': timestamp,
    'status': status,
    'type': type,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    if (fileName != null) 'fileName': fileName,
    if (fileSize != null) 'fileSize': fileSize,
    if (audioDuration != null) 'audioDuration': audioDuration,
    'reactions': reactions,
    'isStarred': isStarred,
    if (replyTo != null) 'replyTo': replyTo!.toMap(),
  };

  MessageModel copyWith({
    String? status,
    String? content,
    List<String>? reactions,
    bool? isStarred,
  }) => MessageModel(
    id: id,
    senderId: senderId,
    senderName: senderName,
    senderAvatar: senderAvatar,
    content: content ?? this.content,
    timestamp: timestamp,
    status: status ?? this.status,
    type: type,
    mediaUrl: mediaUrl,
    fileName: fileName,
    fileSize: fileSize,
    audioDuration: audioDuration,
    reactions: reactions ?? this.reactions,
    isStarred: isStarred ?? this.isStarred,
    replyTo: replyTo,
  );
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