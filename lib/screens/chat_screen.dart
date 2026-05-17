import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_window_header.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  const ChatScreen({super.key, required this.userId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _scrollCtrl  = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  MessageModel? _replyingTo;
  bool _showSearch = false;
  String _searchQuery = '';
  late final String _chatDocId;

  @override
  void initState() {
    super.initState();
    _chatDocId = _chatService.chatId(widget.userId);
    _chatService.markAsRead(_chatDocId);
  }

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
      future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      builder: (_, userSnap) {
        UserModel? other;
        if (userSnap.hasData && userSnap.data!.exists) {
          other = UserModel.fromMap(
              userSnap.data!.data() as Map<String, dynamic>, widget.userId);
        }

        final subtitle = other?.isOnline == true ? 'ONLINE' : (other?.about ?? '');

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ChatWindowHeader(
              name: other?.displayName ?? '...',
              avatar: other?.photoURL,
              subtitle: subtitle,
              id: widget.userId,
            ),
          ),
          body: Column(
            children: [
              if (_showSearch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _showSearch = false; _searchQuery = '';
                        }),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.messagesStream(_chatDocId),
                  builder: (_, snap) {
                    final msgs = snap.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? msgs
                        : msgs.where((m) => m.content.toLowerCase()
                            .contains(_searchQuery.toLowerCase())).toList();
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Say hello 👋',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        ]),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final msg = filtered[i];
                        final isMe = msg.senderId == _uid;
                        final showTail = i == filtered.length - 1 ||
                            filtered[i + 1].senderId != msg.senderId;

                        return ChatBubble(
                          message: msg, isMe: isMe, showTail: showTail,
                          onReply: () => setState(() => _replyingTo = msg),
                          onStar: () => _chatService.toggleStar(
                              _chatDocId, msg.id, msg.isStarred),
                          onReact: (e) => _chatService.addReaction(_chatDocId, msg.id, e),
                        );
                      },
                    );
                  },
                ),
              ),

              MessageInput(
                replyingTo: _replyingTo,
                onCancelReply: () => setState(() => _replyingTo = null),
                onTyping: () => _chatService.setTyping(_chatDocId),
                onSend: (content, type, {file, audioDuration, replyTo}) async {
                  String? mediaUrl;
                  if (file != null) mediaUrl = await _chatService.uploadFile(file);
                  _chatService.sendMessage(
                    chatDocId: _chatDocId, content: content, type: type,
                    mediaUrl: mediaUrl, audioDuration: audioDuration,
                    replyTo: replyTo, otherUserId: widget.userId, isGroup: false,
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