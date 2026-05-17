import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
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
      body: Column(
        children: [
          const AppHeader(title: 'Settings', showSearch: false),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (_, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final name   = data?['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
                final avatar = data?['photoURL'] as String?;
                final about  = data?['about'] ?? 'Hey there! I am using FLUX.';
                final phone  = data?['phoneNumber'] ?? '';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // Profile card — tappable → profile screen
                    GestureDetector(
                      onTap: () => context.push('/profile/${FirebaseAuth.instance.currentUser!.uid}'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.grey.withOpacity(0.06)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)],
                        ),
                        child: Row(children: [
                          AvatarWidget(url: avatar, name: name, size: 70),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                              const SizedBox(height: 3),
                              Text(phone, style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              Text('"$about"',
                                style: TextStyle(fontSize: 11, color: kPrimary,
                                    fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 22, color: Colors.grey.shade400),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Appearance (dark mode toggle)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.06)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: kPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Appearance',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('Switch between light and dark themes',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ),
                        Switch(
                          value: isDark,
                          activeColor: kPrimary,
                          onChanged: (val) {
                            provider?.setTheme(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 40),

                    // Sign out
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
                        child: const Row(children: [
                          Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 14),
                          Text('Sign Out',
                              style: TextStyle(color: Colors.red,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
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
    );
  }
}