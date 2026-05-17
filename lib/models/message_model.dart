class MessageModel {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final String status; // sending | sent | delivered | read
  final String type;   // text | image | video | audio | document | poll
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final List<String> reactions;
  final bool isStarred;
  final ReplyInfo? replyTo;
  final PollMeta? poll;

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
    this.reactions = const [],
    this.isStarred = false,
    this.replyTo,
    this.poll,
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
      reactions: List<String>.from(map['reactions'] ?? []),
      isStarred: map['isStarred'] ?? false,
      replyTo: map['replyTo'] != null ? ReplyInfo.fromMap(map['replyTo']) : null,
      poll: map['meta'] != null && map['type'] == 'poll'
          ? PollMeta.fromMap(map['meta'])
          : null,
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
    'mediaUrl': mediaUrl,
    'fileName': fileName,
    'fileSize': fileSize,
    'reactions': reactions,
    'isStarred': isStarred,
    if (replyTo != null) 'replyTo': replyTo!.toMap(),
    if (poll != null) 'meta': poll!.toMap(),
  };

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    String? status,
    String? type,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    List<String>? reactions,
    bool? isStarred,
    ReplyInfo? replyTo,
    PollMeta? poll,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      reactions: reactions ?? this.reactions,
      isStarred: isStarred ?? this.isStarred,
      replyTo: replyTo ?? this.replyTo,
      poll: poll ?? this.poll,
    );
  }
}

class ReplyInfo {
  final String id;
  final String senderName;
  final String content;
  ReplyInfo({required this.id, required this.senderName, required this.content});
  factory ReplyInfo.fromMap(Map m) => ReplyInfo(
    id: m['id'] ?? '', senderName: m['senderName'] ?? '', content: m['content'] ?? '');
  Map<String, dynamic> toMap() => {'id': id, 'senderName': senderName, 'content': content};
}

class PollMeta {
  final List<String> options;
  final Map<String, List<String>> votes;
  PollMeta({required this.options, required this.votes});
  factory PollMeta.fromMap(Map m) {
    final rawVotes = (m['votes'] as Map?) ?? {};
    return PollMeta(
      options: List<String>.from(m['options'] ?? []),
      votes: rawVotes.map((k, v) => MapEntry(k.toString(), List<String>.from(v ?? []))),
    );
  }
  Map<String, dynamic> toMap() => {'options': options, 'votes': votes};
}