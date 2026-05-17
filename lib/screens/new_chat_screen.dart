import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (_, snap) {
          final users = (snap.data?.docs ?? [])
              .where((d) => d.id != _uid)
              .where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['displayName'] ?? '').toString().toLowerCase();
                return _query.isEmpty || name.contains(_query.toLowerCase());
              })
              .toList();

          if (users.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_search_rounded, size: 52, color: kPrimary.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text('No users found', style: TextStyle(color: Colors.grey.shade500)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final data = users[i].data() as Map<String, dynamic>;
              final name   = data['displayName'] ?? 'User';
              final avatar = data['photoURL'];
              final phone  = data['phoneNumber'] ?? '';
              final online = data['isOnline'] ?? false;

              return GestureDetector(
                onTap: () => context.go('/chat/${users[i].id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.08)),
                  ),
                  child: Row(children: [
                    AvatarWidget(url: avatar, name: name, size: 46, isOnline: online),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(phone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}