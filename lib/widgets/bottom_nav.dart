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
      _Tab(icon: Icons.chat_bubble_rounded, label: 'CHATS', route: '/home'),
      _Tab(icon: Icons.group_rounded,       label: 'GROUPS', route: '/groups'),
      _Tab(icon: Icons.auto_awesome,        label: 'PEGASUS', route: '/bot'),
    ];

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDark ? kCardDark : kCardLight).withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tabs[i].route),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? (isDark ? kCardDark : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: active
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)]
                          : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tabs[i].icon,
                            size: 18,
                            color: active ? kPrimary : Colors.grey.shade500),
                        const SizedBox(height: 4),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: active ? kPrimary : Colors.grey.shade500,
                          ),
                        ),
                        if (active)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.6), blurRadius: 8)],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
  _Tab({required this.icon, required this.label, required this.route});
}