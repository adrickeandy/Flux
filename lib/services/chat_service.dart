import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _cloudinary = CloudinaryPublic('17c886bc-bd42-4773-9c60-905a759b585d', 'Flux pro', cache: false);

  String get _uid => _auth.currentUser!.uid;

  // Get chat ID for two users
  String chatId(String otherUid) {
    final ids = [_uid, otherUid]..sort();
    return ids.join('_');
  }

  // Stream messages for a chat
  Stream<List<MessageModel>> messagesStream(String chatDocId) {
    return _db
        .collection('chats')
        .doc(chatDocId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  // Stream all private chats for current user
  Stream<QuerySnapshot> chatsStream() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _uid)
        .where('isGroup', isEqualTo: false)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Stream all group chats for current user
  Stream<QuerySnapshot> groupsStream() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _uid)
        .where('isGroup', isEqualTo: true)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage({
    required String chatDocId,
    required String content,
    required String type,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    ReplyInfo? replyTo,
    PollMeta? poll,
    required String otherUserId,
    required bool isGroup,
  }) async {
    final user = _auth.currentUser!;
    final msgRef = _db.collection('chats').doc(chatDocId).collection('messages');

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
      'reactions': [],
      'isStarred': false,
      if (replyTo != null) 'replyTo': replyTo.toMap(),
      if (poll != null) 'meta': poll.toMap(),
    };

    await msgRef.add(msg);

    // Update chat document
    final chatUpdate = {
      'lastMessage': type == 'text' ? content : '📎 $type',
      'lastMessageSenderId': _uid,
      'lastMessageStatus': 'sent',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'participants': isGroup ? FieldValue.arrayUnion([]) : FieldValue.arrayUnion([_uid, otherUserId]),
      'isGroup': isGroup,
    };

    if (!isGroup) {
      chatUpdate['unreadCount.$otherUserId'] = FieldValue.increment(1) as dynamic;
    }

    await _db.collection('chats').doc(chatDocId).set(chatUpdate, SetOptions(merge: true));
  }

  // Mark messages as read
  Future<void> markAsRead(String chatDocId) async {
    final snap = await _db
        .collection('chats')
        .doc(chatDocId)
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

  // Toggle star
  Future<void> toggleStar(String chatDocId, String messageId, bool current) {
    return _db
        .collection('chats')
        .doc(chatDocId)
        .collection('messages')
        .doc(messageId)
        .update({'isStarred': !current});
  }

  // Add reaction
  Future<void> addReaction(String chatDocId, String messageId, String emoji) {
    return _db
        .collection('chats')
        .doc(chatDocId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions': FieldValue.arrayUnion([emoji])});
  }

  // Toggle archive
  Future<void> toggleArchive(String chatDocId, bool isArchived) {
    return _db.collection('chats').doc(chatDocId).update({
      'archivedBy': isArchived
          ? FieldValue.arrayRemove([_uid])
          : FieldValue.arrayUnion([_uid]),
    });
  }

  // Update typing status
  Future<void> setTyping(String chatDocId) {
    return _db.collection('chats').doc(chatDocId).set({
      'typingStatus': {_uid: DateTime.now().millisecondsSinceEpoch}
    }, SetOptions(merge: true));
  }

  // Upload file to Cloudinary
  Future<String> uploadFile(File file) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print(e);
      return '';
    }
  }
}
