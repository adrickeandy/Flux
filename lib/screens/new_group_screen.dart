import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});
  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final List<String> _selectedIds = [];
  String _query = '';
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                title: 'New Group',
                showSearch: true,
                searchPlaceholder: 'Search contacts...',
                onSearch: (v) => setState(() => _query = v),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Member count bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                ),
                child: Text(
                  '${_selectedIds.length} members selected',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                      color: kPrimary, letterSpacing: 2),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final data = users[i].data() as Map<String, dynamic>;
                        final id     = users[i].id;
                        final name   = data['displayName'] ?? 'User';
                        final avatar = data['photoURL'] as String?;
                        final about  = data['about'] ?? 'Hey there! I am using FLUX.';
                        final selected = _selectedIds.contains(id);

                        return GestureDetector(
                          onTap: () => _toggle(id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? kPrimary.withOpacity(0.08)
                                  : Theme.of(context).cardColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? kPrimary.withOpacity(0.3) : Colors.transparent),
                            ),
                            child: Row(children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AvatarWidget(url: avatar, name: name, size: 48),
                                  if (selected)
                                    Positioned(
                                      right: -2, bottom: -2,
                                      child: Container(
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          color: kPrimary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 12),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(about,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      overflow: TextOverflow.ellipsis),
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

          // Arrow FAB
          if (_selectedIds.isNotEmpty)
            Positioned(
              bottom: 32, right: 20,
              child: GestureDetector(
                onTap: () => context.push(
                  '/new-group/details?members=${_selectedIds.join(',')}'),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5),
                        blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }
}