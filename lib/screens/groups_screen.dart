import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
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
                searchPlaceholder: 'Search groups...',
                onSearch: (v) => setState(() => _search = v),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.groupsStream(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = (snap.data?.docs ?? [])
                        .map((d) => ChatModel.fromMap(
                            d.data() as Map<String, dynamic>, d.id))
                        .where((g) => _search.isEmpty ||
                            (g.groupName ?? '').toLowerCase()
                                .contains(_search.toLowerCase()))
                        .toList();

                    if (groups.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.group_rounded, size: 64, color: kPrimary.withAlpha(38)),
                          const SizedBox(height: 16),
                          const Text('NO GROUPS YET',
                              style: TextStyle(fontWeight: FontWeight.w900,
                                  fontSize: 11, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Text('Create a group to get started',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ]),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        final name   = g.groupName ?? 'Group';
                        final avatar = g.groupAvatar;

                        return GestureDetector(
                          onTap: () => context.push('/group/${g.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha(102),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withAlpha(13)),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withAlpha(10), blurRadius: 12)],
                            ),
                            child: Row(children: [
                              GestureDetector(
                                onTap: () => FullscreenImageViewer.show(context, avatar, name),
                                child: AvatarWidget(url: avatar, name: name, size: 44),
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
                                                fontWeight: FontWeight.w700, fontSize: 13),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      Text(g.formattedTime(),
                                          style: TextStyle(fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: kPrimary.withAlpha(204), letterSpacing: 1)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text(
                                      g.lastMessage.isEmpty ? 'No messages yet' : g.lastMessage,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ]),
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