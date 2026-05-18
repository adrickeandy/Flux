import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_window_header.dart';
import '../widgets/fullscreen_image.dart';
import '../theme/app_theme.dart';

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
  bool _showSearch = false;
  String _searchQuery = '';

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
        final groupAvatar = data?['groupAvatar'] as String?;
        final memberCount = (data?['participants'] as List?)?.length ?? 0;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ChatWindowHeader(
              name: groupName,
              avatar: groupAvatar,
              subtitle: '$memberCount PARTICIPANTS',
              id: widget.groupId,
              isGroup: true,
              onToggleSearch: () => setState(() => _showSearch = !_showSearch),
              onClearChat: () => _chatService.clearChat(widget.groupId),
            ),
          ),
          body: Column(
            children: [
              if (_showSearch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context).cardColor.withAlpha(153),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Search in group...',
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
                  ]),
                ),

              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.messagesStream(widget.groupId),
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
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final msg = filtered[i];
                        final isMe = msg.senderId == _uid;
                        final showTail = i == filtered.length - 1 ||
                            filtered[i + 1].senderId != msg.senderId;

                        return ChatBubble(
                          message: msg, isMe: isMe,
                          showAvatar: !isMe && showTail,
                          showTail: showTail,
                          onReply: () {},
                          onStar: () => _chatService.toggleStar(widget.groupId, msg.id, msg.isStarred),
                          onReact: (e) => _chatService.addReaction(widget.groupId, msg.id, e),
                          onDoubleTap: (id) => _chatService.addReaction(widget.groupId, id, '❤️'),
                          onTapImage: (url, name) => FullscreenImageViewer.show(context, url, name),
                          onTapSender: (senderId) => context.push('/chat/$senderId'),
                          onVote: (id, idx) => _chatService.vote(widget.groupId, id, idx),
                        );
                      },
                    );
                  },
                ),
              ),

              MessageInput(
                onSend: (content, type, {file, meta, replyTo}) async {
                  String? mediaUrl;
                  if (file != null) mediaUrl = await _chatService.uploadFile(file);
                  _chatService.sendMessage(
                    chatDocId: widget.groupId, content: content, type: type,
                    mediaUrl: mediaUrl, meta: meta, replyTo: replyTo,
                    otherUserId: '', isGroup: true,
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
