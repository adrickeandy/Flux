import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';
import '../services/chat_service.dart';

class NewGroupDetailsScreen extends StatefulWidget {
  final List<String> memberIds;
  const NewGroupDetailsScreen({super.key, required this.memberIds});
  @override
  State<NewGroupDetailsScreen> createState() => _NewGroupDetailsScreenState();
}

class _NewGroupDetailsScreenState extends State<NewGroupDetailsScreen> {
  final _nameCtrl = TextEditingController();
  String? _avatarUrl;
  bool _loading = false;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final docs = await Future.wait(
      widget.memberIds.map((id) =>
          FirebaseFirestore.instance.collection('users').doc(id).get()),
    );
    setState(() {
      _members = docs
          .where((d) => d.exists)
          .map((d) => {'id': d.id, ...d.data()!})
          .toList();
    });
  }

  Future<void> _createGroup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required'),
            behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    try {
      await ChatService().createGroup(
        name: _nameCtrl.text.trim(),
        memberIds: widget.memberIds,
        avatarUrl: _avatarUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_nameCtrl.text.trim()} created!'),
              behavior: SnackBarBehavior.floating));
        context.go('/groups');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                showSearch: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Avatar picker
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final img = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (img == null) return;
                          // Upload and set _avatarUrl
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: kPrimary.withOpacity(0.3), width: 2),
                              ),
                              child: _avatarUrl != null
                                  ? ClipOval(child: Image.network(
                                      _avatarUrl!, fit: BoxFit.cover))
                                  : Icon(Icons.camera_alt_rounded,
                                      size: 36, color: kPrimary.withOpacity(0.4)),
                            ),
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                width: 30, height: 30,
                                decoration: const BoxDecoration(
                                    gradient: kGradient, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Group name
                    const Text('GROUP SUBJECT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: kPrimary, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                          hintText: 'Enter group name...'),
                    ),
                    const SizedBox(height: 28),

                    // Participants
                    Text('PARTICIPANTS: ${_members.length}',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: Colors.grey.shade500, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _members.length,
                      itemBuilder: (_, i) {
                        final m = _members[i];
                        return Column(
                          children: [
                            AvatarWidget(
                              url: m['photoURL'],
                              name: m['displayName'] ?? 'User',
                              size: 54,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (m['displayName'] ?? 'User').toString().split(' ').first,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Create FAB
          Positioned(
            bottom: 32, right: 20,
            child: GestureDetector(
              onTap: _loading ? null : _createGroup,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: kGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5),
                      blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}