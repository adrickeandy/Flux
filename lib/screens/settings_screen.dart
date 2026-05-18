import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final provider = ThemeProvider.of(context);
    final isDark = provider?.themeMode == ThemeMode.dark ||
        (provider?.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppHeader(title: 'Settings', showSearch: false),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (_, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final name   = data?['displayName'] ?? 'User';
                    final avatar = data?['photoURL'] as String?;
                    final phone  = data?['phoneNumber'] ?? data?['email'] ?? '';
                    final about  = data?['about'] ?? 'Hey I use FLUX';
                    final online = data?['isOnline'] ?? false;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        // Profile card
                        GestureDetector(
                          onTap: () => context.push('/profile/me'),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: Colors.grey.withAlpha(13)),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withAlpha(15), blurRadius: 16)],
                            ),
                            child: Row(children: [
                              Stack(children: [
                                AvatarWidget(url: avatar, name: name, size: 96,
                                    isOnline: online),
                              ]),
                              const SizedBox(width: 16),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 20)),
                                  const SizedBox(height: 4),
                                  Text(phone, style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade500)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(13),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('"$about"',
                                        style: TextStyle(fontSize: 10,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Edit Profile',
                                      style: TextStyle(fontSize: 10, color: kPrimary,
                                          fontWeight: FontWeight.w900, letterSpacing: 2)),
                                ],
                              )),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Appearance
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withAlpha(128),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withAlpha(13)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: kPrimary.withAlpha(25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  color: kPrimary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Appearance',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('Switch themes',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            )),
                            Switch(
                              value: isDark,
                              activeThumbColor: kPrimary,
                              onChanged: (val) {
                                provider?.setTheme(val ? ThemeMode.dark : ThemeMode.light);
                              },
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),

                        // Feedback
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha(128),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withAlpha(13)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: kPrimary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.favorite_rounded,
                                    color: kPrimary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Feedback',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  Text('Send us your suggestions',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ],
                              )),
                              Icon(Icons.chevron_right_rounded,
                                  size: 20, color: Colors.grey.shade400),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Logout
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28)),
                              title: const Text('Log out of FLUX?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w800)),
                              content: const Text(
                                  'You will need to sign in again to access your chats.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await AuthService().signOut();
                                    if (context.mounted) context.go('/login');
                                  },
                                  child: const Text('Log Out',
                                      style: TextStyle(color: Colors.red,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(13),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.withAlpha(25)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.logout_rounded, color: Colors.red, size: 22),
                              SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Log Out',
                                      style: TextStyle(color: Colors.red,
                                          fontWeight: FontWeight.w800, fontSize: 13,
                                          letterSpacing: 1)),
                                  Text('End your session on this device',
                                      style: TextStyle(fontSize: 10,
                                          color: Colors.redAccent)),
                                ],
                              )),
                            ]),
                          ),
                        ),

                        // Footer
                        const SizedBox(height: 40),
                        Column(children: [
                          const Text('Built by ADRICKE ANDY',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                                  color: kPrimary, letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text('© 2026',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                        ]),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          BottomNav(currentIndex: -1),
        ],
      ),
    );
  }
}