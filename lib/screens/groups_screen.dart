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
import '../widgets/fullscreen_image.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _chatService = ChatService();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                title: 'Groups',
                onSearch: (v) => setState(() => _search = v),
                searchPlaceholder: 'Search groups...',
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.groupsStream(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = (snap.data?.docs ?? [])
                        .map((d) => ChatModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                        .where((g) => _search.isEmpty ||
                            (g.groupName ?? g.name).toLowerCase().contains(_search.toLowerCase()))
                        .toList();

                    if (groups.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.group_rounded, size: 64, color: kPrimary.withOpacity(0.15)),
                          const SizedBox(height: 16),
                          const Text('NO GROUPS YET',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Text('Create a group to get started',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ]),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        final name = g.groupName ?? g.name;
                        final avatar = g.groupAvatar;
                        final unread = (g.unreadCount is Map)
                            ? ((g.unreadCount as Map)[_uid] ?? 0) as int
                            : (g.unreadCount as int? ?? 0);

                        return GestureDetector(
                          onTap: () => context.push('/group/${g.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.grey.withOpacity(0.08)),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.04), blurRadius: 12)],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => FullscreenImageViewer.show(context, avatar, name),
                                  child: AvatarWidget(url: avatar, name: name, size: 54),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800, fontSize: 14),
                                            overflow: TextOverflow.ellipsis),
                                        ),
                                        Text(formatChatTime(g.lastMessageTimestamp),
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                              color: kPrimary.withOpacity(0.8), letterSpacing: 1)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                if (g.lastMessageSenderName != null)
                                                  TextSpan(
                                                    text: '${g.lastMessageSenderName}: ',
                                                    style: TextStyle(
                                                      fontSize: 12, fontWeight: FontWeight.w700,
                                                      color: kPrimary.withOpacity(0.7)),
                                                  ),
                                                TextSpan(
                                                  text: g.lastMessage,
                                                  style: TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unread > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: kPrimary,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [BoxShadow(
                                                  color: kPrimary.withOpacity(0.4), blurRadius: 8)],
                                            ),
                                            child: Text('$unread',
                                              style: const TextStyle(color: Colors.white,
                                                  fontSize: 9, fontWeight: FontWeight.w900)),
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