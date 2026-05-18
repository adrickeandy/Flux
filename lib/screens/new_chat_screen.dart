import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/fullscreen_image.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  String _query = '';
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Select Contact',
            showSearch: true,
            searchPlaceholder: 'Search contacts...',
            onSearch: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = (snap.data?.docs ?? [])
                    .where((d) => d.id != _uid)
                    .where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = (data['displayName'] ?? '').toString().toLowerCase();
                      return _query.isEmpty || name.contains(_query.toLowerCase());
                    })
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // New Group tile
                    GestureDetector(
                      onTap: () => context.push('/new-group'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? kCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.grey.withAlpha(13)),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withAlpha(20), blurRadius: 20)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(
                                color: kPrimary, shape: BoxShape.circle),
                            child: const Icon(Icons.group_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Group',
                                  style: TextStyle(fontWeight: FontWeight.w800,
                                      fontSize: 13, letterSpacing: 0.5)),
                              Text('Create a community',
                                  style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          )),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: kPrimary.withAlpha(153)),
                        ]),
                      ),
                    ),

                    // Contacts on FLUX
                    if (users.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Row(children: [
                          Container(width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: kPrimary, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('CONTACTS ON FLUX',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                                  color: kPrimary, letterSpacing: 2)),
                        ]),
                      ),
                      ...users.map((u) {
                        final data = u.data() as Map<String, dynamic>;
                        final name   = data['displayName'] ?? 'User';
                        final avatar = data['photoURL'] as String?;
                        final about  = data['about'] ?? 'Hey I use FLUX';
                        final online = data['isOnline'] ?? false;

                        return GestureDetector(
                          onTap: () => context.go('/chat/${u.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha(102),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.grey.withAlpha(13)),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withAlpha(10), blurRadius: 8)],
                            ),
                            child: Row(children: [
                              GestureDetector(
                                onTap: () => FullscreenImageViewer.show(context, avatar, name),
                                child: AvatarWidget(
                                    url: avatar, name: name, size: 56, isOnline: online),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(about,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey.shade500),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              )),
                            ]),
                          ),
                        );
                      }),
                    ],

                    if (users.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.person_search_rounded, size: 52,
                              color: kPrimary.withAlpha(51)),
                          const SizedBox(height: 12),
                          Text('No users found',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ])),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}