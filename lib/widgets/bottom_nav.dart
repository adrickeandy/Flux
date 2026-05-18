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
      _Tab(icon: Icons.chat_bubble_rounded,  label: 'Chats',   route: '/home'),
      _Tab(icon: Icons.group_rounded,         label: 'Groups',  route: '/groups'),
      _Tab(icon: Icons.auto_awesome_rounded,  label: 'PEGASUS', route: '/bot'),
    ];

    return Positioned(
      bottom: 16, left: 16, right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? kCardDark : kCardLight).withAlpha(102),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withAlpha(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(153),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                final isActive = currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tabs[i].route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark ? kCardDark : kCardLight)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: isActive
                            ? [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20)]
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isActive)
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withAlpha(77),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Icon(
                                tabs[i].icon,
                                size: 18,
                                color: isActive ? kPrimary : Colors.grey.shade500,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tabs[i].label,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: isActive ? kPrimary : Colors.grey.shade500,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 24, height: 3,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: kPrimary, blurRadius: 8),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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