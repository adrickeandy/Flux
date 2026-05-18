import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
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
                searchPlaceholder: 'Search chats...',
                onSearch: (v) => setState(() => _search = v),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.chatsStream(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var chats = (snap.data?.docs ?? [])
                        .map((d) => ChatModel.fromMap(
                            d.data() as Map<String, dynamic>, d.id))
                        .where((c) => c.archivedBy.contains(_uid) == _showArchived)
                        .where((c) => _search.isEmpty ||
                            c.lastMessage.toLowerCase().contains(_search.toLowerCase()))
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _showArchived ? 'ARCHIVED' : 'RECENT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade500, letterSpacing: 2),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showArchived = !_showArchived),
                                child: Row(children: [
                                  Icon(
                                    _showArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                                    size: 12, color: kPrimary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showArchived ? 'Inbox' : 'Archived',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                                        color: kPrimary, letterSpacing: 1)),
                                ]),
                              ),
                            ],
                          ),
                        ),

                        if (chats.isEmpty)
                          _emptyState()
                        else
                          ...chats.map((c) => _ChatTile(
                            chat: c, uid: _uid, chatService: _chatService,
                            showArchived: _showArchived,
                          )),
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
              bottom: 96, right: 24,
              child: GestureDetector(
                onTap: () => context.push('/new-chat'),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kPrimary.withAlpha(102),
                          blurRadius: 50, offset: const Offset(0, 20)),
                    ],
                  ),
                  child: const Icon(Icons.mark_chat_read_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
            ),

          BottomNav(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.only(top: 80),
    child: Column(
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: kPrimary.withAlpha(13),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: kPrimary.withAlpha(25)),
          ),
          child: Icon(Icons.send_rounded, size: 40, color: kPrimary.withAlpha(51)),
        ),
        const SizedBox(height: 24),
        Text(
          _showArchived ? 'No Archived Messages' : 'No Messages',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _showArchived
              ? "You haven't archived any conversations yet."
              : 'Start a new conversation to see it here.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
        if (!_showArchived) ...[
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.push('/new-chat'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: kPrimary.withAlpha(102), blurRadius: 20)],
              ),
              alignment: Alignment.center,
              child: const Text('New Conversation',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                      fontSize: 11, letterSpacing: 2)),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String uid;
  final ChatService chatService;
  final bool showArchived;

  const _ChatTile({
    required this.chat,
    required this.uid,
    required this.chatService,
    required this.showArchived,
  });

  @override
  Widget build(BuildContext context) {
    final otherUid = chat.participants.firstWhere((p) => p != uid, orElse: () => '');
    final isArchived = chat.archivedBy.contains(uid);

    return FutureBuilder<DocumentSnapshot>(
      future: otherUid.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(otherUid).get()
          : null,
      builder: (_, snap) {
        String name   = 'User';
        String? avatar;
        bool isOnline = false;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data, otherUid);
          name     = user.displayName;
          avatar   = user.photoURL;
          isOnline = user.isOnline;
        }

        final unread = (chat.unreadCount is Map)
            ? ((chat.unreadCount as Map)[uid] ?? 0) as int
            : (chat.unreadCount as int? ?? 0);

        return GestureDetector(
          onTap: () => context.push('/chat/$otherUid'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withAlpha(102),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withAlpha(13)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12)],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => FullscreenImageViewer.show(context, avatar, name),
                  child: Stack(children: [
                    AvatarWidget(url: avatar, name: name, size: 44, isOnline: isOnline),
                  ]),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(chat.formattedTime(),
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                                  color: kPrimary.withAlpha(204), letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (chat.lastMessageSenderId == uid &&
                              chat.lastMessageStatus != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: StatusTicks(status: chat.lastMessageStatus!),
                            ),
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                                color: unread > 0
                                    ? Theme.of(context).textTheme.bodyMedium?.color
                                    : Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: kPrimary.withAlpha(77), blurRadius: 8),
                                ],
                              ),
                              child: Text('$unread',
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 9, fontWeight: FontWeight.w900)),
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