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

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(title: 'Groups', showSearch: true, searchPlaceholder: 'Search groups...'),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.groupsStream(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = (snap.data?.docs ?? [])
                        .map((d) => ChatModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                        .toList();

                    if (groups.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.group_rounded, size: 64, color: kPrimary.withOpacity(0.15)),
                          const SizedBox(height: 16),
                          const Text('NO GROUPS YET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Text('Create a group to get started', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ]),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        final unread = (g.unreadCount is Map)
                            ? ((g.unreadCount as Map)[uid] ?? 0) as int
                            : g.unreadCount;

                        return GestureDetector(
                          onTap: () => context.push('/group/${g.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                AvatarWidget(
                                  url: g.groupAvatar ?? 'https://picsum.photos/seed/${g.id}/200/200',
                                  name: g.groupName ?? g.name,
                                  size: 46,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(g.groupName ?? g.name,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                            overflow: TextOverflow.ellipsis)),
                                        Text(formatChatTime(g.lastMessageTimestamp),
                                            style: TextStyle(fontSize: 9, color: kPrimary.withOpacity(0.8),
                                                fontWeight: FontWeight.w800, letterSpacing: 1)),
                                      ]),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Expanded(child: Text(g.lastMessage,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            overflow: TextOverflow.ellipsis)),
                                        if (unread > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                          ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          BottomNav(currentIndex: 1),
        ],
      ),
    );
  }
}