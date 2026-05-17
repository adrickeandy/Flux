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
  bool get _isMe => widget.userId == FirebaseAuth.instance.currentUser?.uid;
  bool _isEditing = false;
  bool _loading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _aboutCtrl;
  String? _name;
  String? _about;
  String? _phone;
  String? _avatar;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController();
    _aboutCtrl = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(widget.userId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _name   = data['displayName'] ?? 'User';
      _about  = data['about'] ?? '';
      _phone  = data['phoneNumber'] ?? '';
      _avatar = data['photoURL'];
      _isOnline = data['isOnline'] ?? false;
      _nameCtrl.text  = _name!;
      _aboutCtrl.text = _about!;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'displayName': _nameCtrl.text.trim(),
      'about': _aboutCtrl.text.trim(),
    });
    await FirebaseAuth.instance.currentUser!.updateDisplayName(_nameCtrl.text.trim());
    setState(() {
      _name  = _nameCtrl.text.trim();
      _about = _aboutCtrl.text.trim();
      _isEditing = false;
      _loading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'),
            behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_name == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover photo header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Cover
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    image: _avatar != null
                        ? DecorationImage(
                            image: NetworkImage(_avatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatar == null
                      ? Container(
                          decoration: const BoxDecoration(gradient: kGradient),
                          child: const Center(
                            child: Icon(Icons.person_rounded,
                                size: 80, color: Colors.white54),
                          ),
                        )
                      : null,
                ),
                // Gradient overlay
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0, 0.5, 1],
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
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
                // Name on photo
                Positioned(
                  bottom: 32, left: 28, right: 28,
                  child: _isEditing
                      ? TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              color: Colors.white),
                          decoration: InputDecoration(
                            fillColor: Colors.black.withOpacity(0.3),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: kPrimary.withOpacity(0.5)),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name!,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              _isMe ? 'Your Profile' : (_isOnline ? 'Online' : 'Offline'),
                              style: TextStyle(
                                fontSize: 10,
                                color: _isOnline ? const Color(0xFF22C55E) : kPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
                // Camera button for own profile
                if (_isMe && _isEditing)
                  Positioned(
                    bottom: 32, right: 28,
                    child: GestureDetector(
                      onTap: () async {
                        await ImagePicker().pickImage(source: ImageSource.gallery);
                        // Upload and update avatar URL
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
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.withOpacity(0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone
                    Text('PHONE NUMBER',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: Colors.grey.shade500, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text(_phone ?? '',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400)),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.withOpacity(0.08)),
                    const SizedBox(height: 20),

                    // About
                    Text('ABOUT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                          color: Colors.grey.shade500, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _aboutCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                                hintText: 'Tell us about yourself...'),
                          )
                        : Text('"${_about ?? ''}"',
                            style: const TextStyle(fontSize: 14, height: 1.5,
                                fontStyle: FontStyle.italic)),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (_isMe)
                      Row(children: [
                        if (_isEditing) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: _loading ? null : _save,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: kGradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12)],
                                ),
                                alignment: Alignment.center,
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Row(mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('SAVE CHANGES',
                                            style: TextStyle(color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.5, fontSize: 11)),
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
                                color: Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.red),
                            ),
                          ),
                        ] else
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isEditing = true),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: kPrimary.withOpacity(0.2)),
                                ),
                                alignment: Alignment.center,
                                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_rounded, color: kPrimary, size: 18),
                                    SizedBox(width: 8),
                                    Text('EDIT PROFILE',
                                      style: TextStyle(color: kPrimary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5, fontSize: 11)),
                                  ]),
                              ),
                            ),
                          ),
                      ])
                    else
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/chat/${widget.userId}'),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: kGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12)],
                              ),
                              alignment: Alignment.center,
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('MESSAGE',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2, fontSize: 11)),
                                ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Icon(Icons.phone_rounded,
                              color: Colors.grey.shade500, size: 20),
                        ),
                      ]),
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