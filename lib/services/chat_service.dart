import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/message_model.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ChatService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _cloudinary = CloudinaryPublic(
    'YOUR_CLOUD_NAME', 'YOUR_UPLOAD_PRESET', cache: false);

  String get _uid => _auth.currentUser!.uid;

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
    double? audioDuration,
    ReplyInfo? replyTo,
    required String otherUserId,
    required bool isGroup,
  }) async {
    final user = _auth.currentUser!;
    final msg = {
      'senderId': _uid,
      'senderName': user.displayName,
      'senderAvatar': user.photoURL,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (audioDuration != null) 'audioDuration': audioDuration,
      'reactions': [],
      'isStarred': false,
      if (replyTo != null) 'replyTo': replyTo.toMap(),
    };
    await _db.collection('chats').doc(chatDocId).collection('messages').add(msg);
    final chatUpdate = {
      'lastMessage': type == 'text' ? content : '📎 $type',
      'lastMessageSenderId': _uid,
      'lastMessageSenderName': user.displayName,
      'lastMessageStatus': 'sent',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'isGroup': isGroup,
    };
    if (!isGroup) {
      chatUpdate['unreadCount.$otherUserId'] = FieldValue.increment(1) as dynamic;
      chatUpdate['participants'] = FieldValue.arrayUnion([_uid, otherUserId]) as dynamic;
    }
    await _db.collection('chats').doc(chatDocId).set(chatUpdate, SetOptions(merge: true));
  }

  Future<void> markAsRead(String chatDocId) async {
    final snap = await _db.collection('chats').doc(chatDocId)
        .collection('messages')
        .where('senderId', isNotEqualTo: _uid)
        .where('status', isNotEqualTo: 'read')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    batch.update(_db.collection('chats').doc(chatDocId), {
      'unreadCount.$_uid': 0,
      'lastMessageStatus': 'read',
    });
    await batch.commit();
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

  Future<void> setTyping(String chatDocId) =>
      _db.collection('chats').doc(chatDocId).set({
        'typingStatus': {_uid: DateTime.now().millisecondsSinceEpoch}
      }, SetOptions(merge: true));

  Future<String> uploadFile(File file) async {
    try {
      final res = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Auto),
      );
      return res.secureUrl;
    } catch (e) {
      return '';
    }
  }

  Future<void> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    final participants = [...memberIds, _uid];
    await _db.collection('chats').add({
      'groupName': name,
      'groupAvatar': avatarUrl,
      'isGroup': true,
      'participants': participants,
      'lastMessage': 'Group created',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'archivedBy': [],
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}