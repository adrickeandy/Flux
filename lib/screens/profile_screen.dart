import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text('User not found'));

          final name   = data['displayName'] ?? 'User';
          final avatar = data['photoURL'];
          final about  = data['about'] ?? 'Hey there! I am using FLUX.';
          final phone  = data['phoneNumber'] ?? '';
          final online = data['isOnline'] ?? false;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary.withOpacity(0.8), const Color(0xFF833AB4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48),
                            AvatarWidget(url: avatar, name: name, size: 90, isOnline: online),
                            const SizedBox(height: 14),
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ABOUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(about, style: const TextStyle(fontSize: 14, height: 1.5)),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: kGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            onPressed: () => context.push('/chat/$userId'),
                            icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                            label: const Text('SEND MESSAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}