import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _isMe =>
      widget.userId == 'me' ||
      widget.userId == FirebaseAuth.instance.currentUser?.uid;

  String get _targetId =>
      widget.userId == 'me'
          ? FirebaseAuth.instance.currentUser!.uid
          : widget.userId;

  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _aboutCtrl;

  String? _name;
  String? _about;
  String? _phone;
  String? _avatar;
  bool _isOnline = false;
  int? _lastSeen;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController();
    _aboutCtrl = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(_targetId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _name    = data['displayName'] ?? 'User';
      _about   = data['about'] ?? '';
      _phone   = data['phoneNumber'] ?? data['email'] ?? '';
      _avatar  = data['photoURL'];
      _isOnline = data['isOnline'] ?? false;
      _lastSeen = data['lastSeen'];
      _nameCtrl.text  = _name!;
      _aboutCtrl.text = _about!;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('users').doc(_targetId).update({
      'displayName': _nameCtrl.text.trim(),
      'about': _aboutCtrl.text.trim(),
    });
    await FirebaseAuth.instance.currentUser!
        .updateDisplayName(_nameCtrl.text.trim());
    setState(() {
      _name  = _nameCtrl.text.trim();
      _about = _aboutCtrl.text.trim();
      _isEditing = false;
      _isSaving  = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'),
            behavior: SnackBarBehavior.floating));
    }
  }

  String _lastSeenText() {
    if (_isOnline) return 'Online';
    if (_lastSeen == null) return 'Offline';
    final dt = DateTime.fromMillisecondsSinceEpoch(_lastSeen!);
    return 'Last seen ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_name == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover photo
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: _avatar != null && _avatar!.isNotEmpty
                      ? Image.network(_avatar!, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(gradient: kGradient),
                          child: const Center(
                            child: Icon(Icons.person_rounded,
                                size: 80, color: Colors.white54),
                          ),
                        ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(77),
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: 48, left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(77),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(51)),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
                // Name overlay
                Positioned(
                  bottom: 48, left: 32, right: 32,
                  child: _isEditing
                      ? TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(fontSize: 28,
                              fontWeight: FontWeight.w900, color: Colors.white),
                          decoration: InputDecoration(
                            fillColor: Colors.black.withAlpha(77),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: kPrimary.withAlpha(128)),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name!,
                                style: const TextStyle(fontSize: 28,
                                    fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              _isMe ? 'Your Profile' : _lastSeenText(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _isOnline ? const Color(0xFF22C55E) : kPrimary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
                // Camera button
                if (_isMe && _isEditing)
                  Positioned(
                    bottom: 48, right: 32,
                    child: GestureDetector(
                      onTap: () async {
                        await ImagePicker().pickImage(source: ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                            gradient: kGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.grey.withAlpha(13)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withAlpha(15), blurRadius: 16)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            indicatorColor: kPrimary,
                            labelColor: kPrimary,
                            unselectedLabelColor: Colors.grey.shade500,
                            labelStyle: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                            tabs: [
                              const Tab(text: 'ABOUT'),
                              Tab(text: _isMe ? 'ACTIVITY' : 'MEDIA'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: TabBarView(children: [
                              // About tab
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IDENTITY',
                                      style: TextStyle(fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey.shade500, letterSpacing: 2)),
                                  const SizedBox(height: 6),
                                  Text(_phone ?? '',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade500)),
                                  const SizedBox(height: 20),
                                  Divider(color: Colors.grey.withAlpha(20)),
                                  const SizedBox(height: 20),
                                  Text('ABOUT',
                                      style: TextStyle(fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey.shade500, letterSpacing: 2)),
                                  const SizedBox(height: 8),
                                  _isEditing
                                      ? TextField(
                                          controller: _aboutCtrl, maxLines: 3,
                                          decoration: const InputDecoration(
                                              hintText: 'Tell us about yourself...'))
                                      : Text('"${_about ?? ''}"',
                                          style: const TextStyle(
                                              fontSize: 14, height: 1.5,
                                              fontStyle: FontStyle.italic)),
                                  const SizedBox(height: 24),
                                  // Action buttons
                                  if (_isMe)
                                    _isEditing
                                        ? Row(children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: _isSaving ? null : _save,
                                                child: Container(
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: kPrimary,
                                                    borderRadius: BorderRadius.circular(18),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: _isSaving
                                                      ? const SizedBox(width: 20, height: 20,
                                                          child: CircularProgressIndicator(
                                                              color: Colors.white, strokeWidth: 2))
                                                      : const Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.save_rounded,
                                                                color: Colors.white, size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Save Changes',
                                                                style: TextStyle(color: Colors.white,
                                                                    fontWeight: FontWeight.w900,
                                                                    fontSize: 12)),
                                                          ]),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: () => setState(() => _isEditing = false),
                                              child: Container(
                                                width: 52, height: 52,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                child: const Icon(Icons.close_rounded,
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ])
                                        : GestureDetector(
                                            onTap: () => setState(() => _isEditing = true),
                                            child: Container(
                                              height: 52,
                                              decoration: BoxDecoration(
                                                color: kPrimary.withAlpha(20),
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(color: kPrimary.withAlpha(51)),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.edit_rounded, color: kPrimary, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit Profile',
                                                      style: TextStyle(color: kPrimary,
                                                          fontWeight: FontWeight.w900, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          )
                                  else
                                    Column(children: [
                                      Row(children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => context.push('/chat/${widget.userId}'),
                                            child: Container(
                                              height: 52,
                                              decoration: BoxDecoration(
                                                color: kPrimary,
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.chat_rounded,
                                                      color: Colors.white, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Message',
                                                      style: TextStyle(color: Colors.white,
                                                          fontWeight: FontWeight.w900, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 52, height: 52,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(20),
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: Icon(Icons.phone_rounded,
                                              color: Colors.grey.shade500, size: 20),
                                        ),
                                      ]),
                                      const SizedBox(height: 10),
                                      Container(
                                        height: 52, width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withAlpha(25),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.red.withAlpha(51)),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.flag_rounded, color: Colors.red, size: 18),
                                            SizedBox(width: 8),
                                            Text('Report User',
                                                style: TextStyle(color: Colors.red,
                                                    fontWeight: FontWeight.w900, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ]),
                                ],
                              ),

                              // Media/Activity tab
                              Center(
                                child: Text(
                                  _isMe
                                      ? 'Recent interactions will appear here'
                                      : 'No shared media',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}