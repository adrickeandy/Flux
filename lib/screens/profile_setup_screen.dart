import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl  = TextEditingController();
  final _aboutCtrl = TextEditingController(text: 'Hey I use FLUX');
  String? _avatarUrl;
  bool _loading = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _avatarUrl = user.photoURL;
    }
  }

  Future<void> _finish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() { _loading = true; _progress = 10; });
    final user = FirebaseAuth.instance.currentUser!;
    try {
      setState(() => _progress = 80);
      await user.updateDisplayName(_nameCtrl.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': _nameCtrl.text.trim(),
        'about': _aboutCtrl.text.trim(),
        'photoURL': _avatarUrl ?? '',
        'isOnline': true,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'email': user.email ?? '',
      }, SetOptions(merge: true));
      setState(() => _progress = 100);
      if (mounted) context.go('/home');
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
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(children: [
                const Text('Profile Info',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Provide your name and optional profile photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                // Avatar
                GestureDetector(
                  onTap: () async {
                    final img = await ImagePicker().pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (img == null) return;
                    // Upload and set _avatarUrl
                  },
                  child: Stack(children: [
                    Container(
                      width: 128, height: 128,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary.withAlpha(51), width: 2),
                      ),
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? ClipOval(child: Image.network(_avatarUrl!, fit: BoxFit.cover))
                          : Icon(Icons.camera_alt_rounded, size: 40, color: kPrimary.withAlpha(102)),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                            gradient: kGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 36),

                Align(alignment: Alignment.centerLeft,
                  child: Text('DISPLAY NAME',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                          color: kPrimary, letterSpacing: 2))),
                const SizedBox(height: 8),
                TextField(controller: _nameCtrl, autofocus: true,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(hintText: 'Your name')),
                const SizedBox(height: 20),

                Align(alignment: Alignment.centerLeft,
                  child: Text('ABOUT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                          color: Colors.grey.shade500, letterSpacing: 2))),
                const SizedBox(height: 8),
                TextField(controller: _aboutCtrl, maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(hintText: 'About you')),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              children: [
                if (_loading && _progress > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Syncing Profile...',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary)),
                    Text('$_progress%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kPrimary)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress / 100,
                      backgroundColor: kPrimary.withAlpha(25),
                      color: kPrimary,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                GestureDetector(
                  onTap: _loading ? null : _finish,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: kPrimary.withAlpha(102),
                          blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    alignment: Alignment.center,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Continue to FLUX',
                                style: TextStyle(fontWeight: FontWeight.w900,
                                    fontSize: 13, color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}