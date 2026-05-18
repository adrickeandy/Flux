import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/message_model.dart';
import 'cloudinary_service.dart';

class ChatService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  String get _displayName => _auth.currentUser!.displayName ?? 'User';
  String? get _photoURL => _auth.currentUser!.photoURL;

  String chatId(String otherUid) {
    final ids = [_uid, otherUid]..sort();
    return ids.join('_');
  }

  Stream<List<MessageModel>> messagesStream(String chatDocId) {
    return _db
        .collection('chats').doc(chatDocId).collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<QuerySnapshot> chatsStream() => _db
      .collection('chats')
      .where('participants', arrayContains: _uid)
      .where('isGroup', isEqualTo: false)
      .orderBy('lastMessageTimestamp', descending: true)
      .snapshots();

  Stream<QuerySnapshot> groupsStream() => _db
      .collection('chats')
      .where('participants', arrayContains: _uid)
      .where('isGroup', isEqualTo: true)
      .orderBy('lastMessageTimestamp', descending: true)
      .snapshots();

  Future<void> sendMessage({
    required String chatDocId,
    required String content,
    required String type,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    String? mimeType,
    Map<String, dynamic>? meta,
    ReplyInfo? replyTo,
    required String otherUserId,
    required bool isGroup,
  }) async {
    final msg = {
      'senderId': _uid,
      'senderName': _displayName,
      'senderAvatar': _photoURL,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (meta != null) 'meta': meta,
      'reactions': [],
      'isStarred': false,
      if (replyTo != null) 'replyTo': replyTo.toMap(),
    };

    await _db.collection('chats').doc(chatDocId)
        .collection('messages').add(msg);

    final chatUpdate = {
      'lastMessage': type == 'text' ? content : 'Sent a $type',
      'lastMessageSenderId': _uid,
      'lastMessageSenderName': _displayName,
      'lastMessageStatus': 'sent',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'isGroup': isGroup,
      'participants': FieldValue.arrayUnion([_uid, if (!isGroup) otherUserId]),
    };

    if (!isGroup) {
      await _db.collection('chats').doc(chatDocId).set({
        ...chatUpdate,
        'unreadCount.$otherUserId': FieldValue.increment(1),
        'unreadCount.$_uid': 0,
        'typingStatus.$_uid': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await _db.collection('chats').doc(chatDocId)
          .update(chatUpdate);
    }
  }

  Future<void> markAsRead(String chatDocId) async {
    try {
      await _db.collection('chats').doc(chatDocId).update({
        'unreadCount.$_uid': 0,
      });
      final unread = await _db.collection('chats').doc(chatDocId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _uid)
          .where('status', isNotEqualTo: 'read')
          .get();
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> setTyping(String chatDocId) async {
    try {
      await _db.collection('chats').doc(chatDocId).set({
        'typingStatus': {_uid: DateTime.now().millisecondsSinceEpoch}
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> toggleStar(String chatDocId, String msgId, bool current) =>
      _db.collection('chats').doc(chatDocId).collection('messages').doc(msgId)
          .update({'isStarred': !current});

  Future<void> addReaction(String chatDocId, String msgId, String emoji) =>
      _db.collection('chats').doc(chatDocId).collection('messages').doc(msgId)
          .update({'reactions': FieldValue.arrayUnion([emoji])});

  Future<void> toggleArchive(String chatDocId, bool isArchived) =>
      _db.collection('chats').doc(chatDocId).update({
        'archivedBy': isArchived
            ? FieldValue.arrayRemove([_uid])
            : FieldValue.arrayUnion([_uid]),
      });

  Future<void> clearChat(String chatDocId) async {
    final msgs = await _db.collection('chats').doc(chatDocId)
        .collection('messages').get();
    final batch = _db.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> vote(String chatDocId, String msgId, int optionIndex) =>
      _db.collection('chats').doc(chatDocId).collection('messages').doc(msgId)
          .update({'meta.votes.$optionIndex': FieldValue.arrayUnion([_uid])});

  Future<String> uploadFile(File file) async {
    return await CloudinaryService.uploadFile(file);
  }

  Future<void> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    await _db.collection('chats').add({
      'groupName': name,
      'groupAvatar': avatarUrl ?? 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200',
      'isGroup': true,
      'participants': [...memberIds, _uid],
      'lastMessage': 'Group created',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'archivedBy': [],
    });
  }
}
