import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'avatar_widget.dart';

class ChatWindowHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String? avatar;
  final String subtitle;
  final String id;
  final bool isGroup;
  final List<Widget>? actions;

  const ChatWindowHeader({
    super.key,
    required this.name,
    this.avatar,
    required this.subtitle,
    required this.id,
    this.isGroup = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBot  = id == 'bot';

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? kCardDark : kCardLight).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: Colors.grey.shade500, size: 22),
                ),
              ),
              const SizedBox(width: 10),

              // Avatar + name + subtitle
              Expanded(
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        isBot
                            ? Container(
                                width: 36, height: 36,
                                decoration: const BoxDecoration(
                                  gradient: kGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: Colors.white, size: 18),
                              )
                            : AvatarWidget(url: avatar, name: name, size: 36),
                        // Online dot
                        Positioned(
                          right: -1, bottom: -1,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? kCardDark : kCardLight,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Name + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Container(
                                width: 5, height: 5,
                                decoration: const BoxDecoration(
                                  color: kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Custom actions (e.g. CLEAR button for bot)
              if (actions != null) ...actions!,

              // Eye icon → profile (only for DM chats, not groups or bot)
              if (!isGroup && !isBot) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.push('/profile/$id'),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove_red_eye_rounded,
                        size: 18, color: Colors.grey.shade500),
                  ),
                ),
              ],

              const SizedBox(width: 4),
              Icon(Icons.more_vert_rounded,
                  size: 20, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}