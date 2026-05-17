import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/avatar_widget.dart';

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
          appBar: AppBar(
            leadingWidth: 48,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(children: [
              AvatarWidget(url: groupAvatar, name: groupName, size: 38),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(groupName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                Text('$memberCount members', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ]),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
            ],
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
                        final showTail = i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId;

                        return Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && showTail)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, bottom: 2),
                                child: Text(msg.senderName ?? '',
                                    style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.w800)),
                              ),
                            ChatBubble(
                              message: msg, isMe: isMe, showTail: showTail,
                              onReply: () => setState(() => _replyingTo = msg),
                              onReact: (e) => _chatService.addReaction(widget.groupId, msg.id, e),
                            ),
                          ],
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
                onSend: (content, type, {file, replyTo}) async {
                  String? mediaUrl;
                  if (file != null) {
                    mediaUrl = await _chatService.uploadFile(file);
                  }
                  _chatService.sendMessage(
                    chatDocId: widget.groupId,
                    otherUserId: '',
                    isGroup: true,
                    content: content,
                    type: type,
                    mediaUrl: mediaUrl,
                    replyTo: replyTo,
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