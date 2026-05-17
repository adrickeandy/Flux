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
                title: _showArchived ? 'Archived' : 'FLUX',
                onSearch: (v) => setState(() => _search = v),
                searchPlaceholder: 'Search chats...',
                actions: [
                  TextButton.icon(
                    onPressed: () => setState(() => _showArchived = !_showArchived),
                    icon: Icon(_showArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                        size: 14, color: kPrimary),
                    label: Text(_showArchived ? 'INBOX' : 'ARCHIVED',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                            letterSpacing: 2, color: kPrimary)),
                  ),
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
                        .where((c) {
                          final archived = c.archivedBy.contains(_uid);
                          return archived == _showArchived;
                        })
                        .where((c) => _search.isEmpty ||
                            c.name.toLowerCase().contains(_search.toLowerCase()))
                        .toList();

                    if (chats.isEmpty) return _emptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: chats.length,
                      itemBuilder: (_, i) => _ChatTile(chat: chats[i], uid: _uid, chatService: _chatService),
                    );
                  },
                ),
              ),
            ],
          ),

          // FAB
          if (!_showArchived)
            Positioned(
              bottom: 100,
              right: 20,
              child: GestureDetector(
                onTap: () => context.push('/new-chat'),
                child: Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
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
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.send_rounded, size: 36, color: kPrimary.withOpacity(0.2)),
          ),
          const SizedBox(height: 20),
          Text(_showArchived ? 'NO ARCHIVED CHATS' : 'NO MESSAGES YET',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(_showArchived ? 'You haven\'t archived anything.' : 'Start a new conversation.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500), textAlign: TextAlign.center),
          if (!_showArchived) ...[
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push('/new-chat'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 16)]),
                child: const Text('NEW CONVERSATION',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
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
        String name = chat.name;
        String avatar = chat.avatar;
        bool isOnline = false;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          name = data['displayName'] ?? name;
          avatar = data['photoURL'] ?? avatar;
          isOnline = data['isOnline'] ?? false;
        }

        final unread = (chat.unreadCount is Map)
            ? ((chat.unreadCount as Map)[uid] ?? 0) as int
            : chat.unreadCount;

        return GestureDetector(
          onTap: () => context.push('/chat/$otherUid'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Row(
              children: [
                AvatarWidget(url: avatar, name: name, size: 46, isOnline: isOnline,
                    onTap: () {}),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              overflow: TextOverflow.ellipsis)),
                          Text(formatChatTime(chat.lastMessageTimestamp),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                  color: kPrimary.withOpacity(0.8), letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (chat.lastMessageSenderId == uid && chat.lastMessageStatus != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: StatusTicks(status: chat.lastMessageStatus!),
                            ),
                          Expanded(
                            child: Text(chat.lastMessage,
                                style: TextStyle(fontSize: 11,
                                    fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                                    color: unread > 0
                                        ? Theme.of(context).textTheme.bodyMedium?.color
                                        : Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 8)],
                              ),
                              child: Text('$unread',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => chatService.toggleArchive(chat.id, isArchived),
                            child: Icon(isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
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