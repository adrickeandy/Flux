import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    _darkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(title: 'Settings', showSearch: false),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(_uid).get(),
                  builder: (_, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final name   = data?['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
                    final avatar = data?['photoURL'];
                    final about  = data?['about'] ?? 'Hey there! I am using FLUX.';
                    final phone  = data?['phoneNumber'] ?? '';

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        // Profile card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.withOpacity(0.08)),
                          ),
                          child: Row(children: [
                            AvatarWidget(url: avatar, name: name, size: 60),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 3),
                              Text(phone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              const SizedBox(height: 2),
                              Text(about, style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            Icon(Icons.edit_rounded, color: kPrimary.withOpacity(0.6), size: 18),
                          ]),
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel('PREFERENCES'),
                        _tile(context, Icons.dark_mode_rounded, 'Dark Mode',
                            trailing: Switch(
                              value: _darkMode,
                              onChanged: (_) {},  // Wire up ThemeMode provider
                              activeColor: kPrimary,
                            )),
                        _tile(context, Icons.notifications_rounded, 'Notifications',
                            trailing: const Icon(Icons.chevron_right_rounded)),
                        _tile(context, Icons.lock_rounded, 'Privacy',
                            trailing: const Icon(Icons.chevron_right_rounded)),

                        const SizedBox(height: 16),
                        _sectionLabel('ABOUT'),
                        _tile(context, Icons.info_rounded, 'About FLUX',
                            trailing: const Icon(Icons.chevron_right_rounded)),
                        _tile(context, Icons.star_rounded, 'Starred Messages',
                            trailing: const Icon(Icons.chevron_right_rounded)),

                        const SizedBox(height: 16),
                        _sectionLabel('ACCOUNT'),
                        GestureDetector(
                          onTap: () async {
                            await AuthService().signOut();
                            if (context.mounted) context.go('/login');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(children: [
                              const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 14),
                              const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const BottomNav(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 2)),
  );

  Widget _tile(BuildContext context, IconData icon, String label, {required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: kPrimary.withOpacity(0.7)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        trailing,
      ]),
    );
  }
}