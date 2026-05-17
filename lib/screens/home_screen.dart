import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/status_ticks.dart';
import '../widgets/fullscreen_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatService = ChatService();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _showArchived = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                title: 'FLUX',
                onSearch: (v) => setState(() => _search = v),
                searchPlaceholder: 'Search chats...',
                actions: [
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_rounded, size: 20),
                    color: Colors.grey,
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.chatsStream(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var chats = (snap.data?.docs ?? [])
                        .map((d) => ChatModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                        .where((c) => c.archivedBy.contains(_uid) == _showArchived)
                        .where((c) => _search.isEmpty ||
                            c.name.toLowerCase().contains(_search.toLowerCase()))
                        .toList();

                    return chats.isEmpty ? _emptyState() : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12, right: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _showArchived ? 'ARCHIVED' : 'RECENT MESSAGES',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade500, letterSpacing: 2),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showArchived = !_showArchived),
                                child: Text(
                                  _showArchived ? 'INBOX' : 'ARCHIVE',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                                      color: kPrimary, letterSpacing: 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...chats.map((c) => _ChatTile(
                          chat: c, uid: _uid, chatService: _chatService)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // FAB
          if (!_showArchived)
            Positioned(
              bottom: 100, right: 20,
              child: GestureDetector(
                onTap: () => context.push('/new-chat'),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5),
                        blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.mark_chat_read_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),

          BottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.send_rounded, size: 36, color: kPrimary.withOpacity(0.2)),
          ),
          const SizedBox(height: 20),
          Text(_showArchived ? 'NO ARCHIVED CHATS' : 'NO MESSAGES YET',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(_showArchived ? "You haven't archived anything." : 'Start a new conversation.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500), textAlign: TextAlign.center),
          if (!_showArchived) ...[
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push('/new-chat'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 16)],
                ),
                child: const Text('NEW CONVERSATION',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                      fontSize: 10, letterSpacing: 2)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String uid;
  final ChatService chatService;
  const _ChatTile({required this.chat, required this.uid, required this.chatService});

  @override
  Widget build(BuildContext context) {
    final otherUid = chat.participants.firstWhere((p) => p != uid, orElse: () => '');
    final isArchived = chat.archivedBy.contains(uid);

    return FutureBuilder<DocumentSnapshot>(
      future: otherUid.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(otherUid).get()
          : null,
      builder: (_, snap) {
        String name   = chat.name;
        String? avatar = chat.avatar.isNotEmpty ? chat.avatar : null;
        bool isOnline = false;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          name     = data['displayName'] ?? name;
          avatar   = data['photoURL'];
          isOnline = data['isOnline'] ?? false;
        }

        final unread = (chat.unreadCount is Map)
            ? ((chat.unreadCount as Map)[uid] ?? 0) as int
            : (chat.unreadCount as int? ?? 0);

        return GestureDetector(
          onTap: () => context.push('/chat/$otherUid'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.withOpacity(0.06)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => FullscreenImageViewer.show(context, avatar, name),
                  child: AvatarWidget(url: avatar, name: name, size: 54, isOnline: isOnline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                          ),
                          Text(formatChatTime(chat.lastMessageTimestamp),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                color: kPrimary.withOpacity(0.8), letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (chat.lastMessageSenderId == uid && chat.lastMessageStatus != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: StatusTicks(status: chat.lastMessageStatus!, onPrimary: false),
                            ),
                          Expanded(
                            child: Text(chat.lastMessage,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                                  color: unread > 0
                                      ? Theme.of(context).textTheme.bodyMedium?.color
                                      : Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 8)],
                              ),
                              child: Text('$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 9,
                                    fontWeight: FontWeight.w900)),
                            ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => chatService.toggleArchive(chat.id, isArchived),
                            child: Icon(
                              isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                              size: 16, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}