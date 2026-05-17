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
  final _aboutCtrl = TextEditingController(text: 'Hey there! I am using FLUX.');
  String? _avatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _avatarUrl = user.photoURL;
    }
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    // TODO: upload to Firebase Storage, set _avatarUrl to the download URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload image to Firebase Storage and set URL'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _finish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser!;
    await user.updateDisplayName(_nameCtrl.text.trim());
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': _nameCtrl.text.trim(),
      'about': _aboutCtrl.text.trim(),
      'photoURL': _avatarUrl,
      'isOnline': true,
    }, SetOptions(merge: true));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => kGradient.createShader(b),
                child: const Text('SETUP PROFILE',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 2)),
              ),
              const SizedBox(height: 8),
              Text('Almost there! Set up your profile.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 40),

              // Avatar picker
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: kPrimary.withOpacity(0.1),
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Icon(Icons.person_rounded, size: 48, color: kPrimary.withOpacity(0.4))
                          : null,
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              _label('DISPLAY NAME'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              const SizedBox(height: 20),

              _label('ABOUT'),
              const SizedBox(height: 6),
              TextField(
                controller: _aboutCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(hintText: 'Something about you'),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: _loading ? null : _finish,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('FINISH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 2)),
  );
}