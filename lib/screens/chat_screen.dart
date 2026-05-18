import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_window_header.dart';
import '../theme/app_theme.dart';
import '../widgets/fullscreen_image.dart';

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
  bool _showSearch = false;
  String _searchQuery = '';
  bool _otherTyping = false;
  late final String _chatDocId;

  @override
  void initState() {
    super.initState();
    _chatDocId = _chatService.chatId(widget.userId);
    _chatService.markAsRead(_chatDocId);
    _listenTyping();
  }

  void _listenTyping() {
    FirebaseFirestore.instance
        .collection('chats').doc(_chatDocId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data?['typingStatus'] != null) {
        final ts = data!['typingStatus'][widget.userId];
        if (ts != null) {
          final isTyping = DateTime.now().millisecondsSinceEpoch - ts < 5000;
          setState(() => _otherTyping = isTyping);
        } else {
          setState(() => _otherTyping = false);
        }
      }
    });
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

        final subtitle = _otherTyping
            ? 'Typing...'
            : (other?.isOnline == true ? 'Online' : 'Offline');

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ChatWindowHeader(
              name: other?.displayName ?? '...',
              avatar: other?.photoURL,
              subtitle: subtitle,
              id: widget.userId,
              isGroup: false,
              onToggleSearch: () => setState(() => _showSearch = !_showSearch),
              onClearChat: () => _chatService.clearChat(_chatDocId),
            ),
          ),
          body: Column(
            children: [
              if (_showSearch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context).cardColor.withAlpha(153),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontSize: 11),
                          decoration: InputDecoration(
                            hintText: 'Search messages...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _showSearch = false; _searchQuery = '';
                        }),
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary)),
                      ),
                    ],
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

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: filtered.length + (_otherTyping ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_otherTyping && i == filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: kPrimary.withAlpha(13),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kPrimary.withAlpha(51)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 4, height: 4,
                                    decoration: const BoxDecoration(
                                        color: kPrimary, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  '${other?.displayName?.split(' ').first ?? 'Someone'} is typing...',
                                  style: const TextStyle(fontSize: 9, color: kPrimary,
                                      fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ]),
                            ),
                          );
                        }

                        final msg = filtered[i];
                        final isMe = msg.senderId == _uid;
                        final showTail = i == filtered.length - 1 ||
                            filtered[i + 1].senderId != msg.senderId;

                        return ChatBubble(
                          message: msg, isMe: isMe, showTail: showTail,
                          onReply: () {},
                          onStar: () => _chatService.toggleStar(_chatDocId, msg.id, msg.isStarred),
                          onReact: (e) => _chatService.addReaction(_chatDocId, msg.id, e),
                          onDoubleTap: (id) => _chatService.addReaction(_chatDocId, id, '❤️'),
                          onTapImage: (url, name) => FullscreenImageViewer.show(context, url, name),
                          onVote: (id, idx) => _chatService.vote(_chatDocId, id, idx),
                        );
                      },
                    );
                  },
                ),
              ),

              MessageInput(
                onTyping: () => _chatService.setTyping(_chatDocId),
                onSend: (content, type, {file, meta, replyTo}) async {
                  String? mediaUrl;
                  if (file != null) mediaUrl = await _chatService.uploadFile(file);
                  _chatService.sendMessage(
                    chatDocId: _chatDocId, content: content, type: type,
                    mediaUrl: mediaUrl, meta: meta, replyTo: replyTo,
                    otherUserId: widget.userId, isGroup: false,
                  );
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
