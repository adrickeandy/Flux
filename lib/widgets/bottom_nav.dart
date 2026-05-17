import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      _Tab(icon: Icons.chat_bubble_rounded, label: 'Chats',  route: '/home'),
      _Tab(icon: Icons.group_rounded,       label: 'Groups', route: '/groups'),
      _Tab(icon: Icons.auto_awesome,        label: 'My Bot', route: '/bot'),
    ];

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? kCardDark : kCardLight).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top:  BorderSide(color: Colors.grey.withOpacity(0.08)),
            left: BorderSide(color: Colors.grey.withOpacity(0.08)),
            right:BorderSide(color: Colors.grey.withOpacity(0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (i) {
                final isActive = currentIndex == i;
                return GestureDetector(
                  onTap: () => context.go(tabs[i].route),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tabs[i].icon,
                          size: 18,
                          color: isActive ? kPrimary : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: isActive ? kPrimary : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 4 : 0,
                          height: isActive ? 4 : 0,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [BoxShadow(color: kPrimary, blurRadius: 8)]
                                : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final String route;
  const _Tab({required this.icon, required this.label, required this.route});
}