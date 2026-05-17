import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_window_header.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});
  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _chatService = ChatService();
  final _scrollCtrl  = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  MessageModel? _replyingTo;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('chats').doc(widget.groupId).get(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final groupName   = data?['groupName'] ?? 'Group';
        final groupAvatar = data?['groupAvatar'];
        final memberCount = (data?['participants'] as List?)?.length ?? 0;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ChatWindowHeader(
              name: groupName,
              avatar: groupAvatar,
              subtitle: '$memberCount MEMBERS',
              id: widget.groupId,
              isGroup: true,
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.messagesStream(widget.groupId),
                  builder: (_, snap) {
                    final msgs = snap.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final msg = msgs[i];
                        final isMe = msg.senderId == _uid;
                        final showTail = i == msgs.length - 1 ||
                            msgs[i + 1].senderId != msg.senderId;
                        return ChatBubble(
                          message: msg, isMe: isMe,
                          showAvatar: !isMe && showTail,
                          showTail: showTail,
                          onReply: () => setState(() => _replyingTo = msg),
                          onReact: (e) => _chatService.addReaction(widget.groupId, msg.id, e),
                        );
                      },
                    );
                  },
                ),
              ),
              MessageInput(
                replyingTo: _replyingTo,
                onCancelReply: () => setState(() => _replyingTo = null),
                onTyping: () => _chatService.setTyping(widget.groupId),
                onSend: (content, type, {file, audioDuration, replyTo}) async {
                  String? mediaUrl;
                  if (file != null) mediaUrl = await _chatService.uploadFile(file);
                  _chatService.sendMessage(
                    chatDocId: widget.groupId, otherUserId: '',
                    isGroup: true, content: content, type: type,
                    mediaUrl: mediaUrl, audioDuration: audioDuration, replyTo: replyTo,
                  );
                  setState(() => _replyingTo = null);
                  _scrollToBottom();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}