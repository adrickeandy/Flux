import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/fullscreen_image.dart';

class ChatWindowHeader extends StatefulWidget implements PreferredSizeWidget {
  final String name;
  final String? avatar;
  final String subtitle;
  final String id;
  final bool isGroup;
  final List<Widget>? actions;
  final VoidCallback? onClearChat;
  final VoidCallback? onToggleSearch;

  const ChatWindowHeader({
    super.key,
    required this.name,
    this.avatar,
    required this.subtitle,
    required this.id,
    this.isGroup = false,
    this.actions,
    this.onClearChat,
    this.onToggleSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<ChatWindowHeader> createState() => _ChatWindowHeaderState();
}

class _ChatWindowHeaderState extends State<ChatWindowHeader> {
  bool _showFullAvatar = false;
  bool _showClearConfirm = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBot = widget.id == 'bot';
    final profileRoute = widget.isGroup
        ? '/group/${widget.id}/info'
        : isBot ? null : '/profile/${widget.id}';

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? kCardDark : kCardLight).withAlpha(242),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withAlpha(25)),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      size: 20, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar + name + subtitle
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showFullAvatar = true),
                          child: isBot
                              ? Container(
                                  width: 32, height: 32,
                                  decoration: const BoxDecoration(
                                    gradient: kGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded,
                                      color: Colors.white, size: 16),
                                )
                              : CircleAvatar(
                                  radius: 16,
                                  backgroundImage: widget.avatar != null
                                      ? NetworkImage(widget.avatar!)
                                      : null,
                                  child: widget.avatar == null
                                      ? Text(widget.name.substring(0, 1),
                                          style: const TextStyle(fontSize: 12))
                                      : null,
                                ),
                        ),
                        Positioned(
                          right: -1, bottom: -1,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isDark ? kCardDark : kCardLight,
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withAlpha(128),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Container(
                                width: 4, height: 4,
                                decoration: const BoxDecoration(
                                  color: kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.subtitle,
                                  style: const TextStyle(
                                    fontSize: 8,
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

              // Custom actions
              if (widget.actions != null) ...widget.actions!,

              // Eye icon → profile
              if (profileRoute != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.push(profileRoute),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove_red_eye_rounded,
                        size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ],

              // More menu
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showMenu(context),
                child: Icon(Icons.more_vert_rounded,
                    size: 20, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onToggleSearch != null)
              _MenuItem(
                icon: Icons.search_rounded,
                label: 'Search in chat',
                onTap: () {
                  Navigator.pop(context);
                  widget.onToggleSearch?.call();
                },
              ),
            _MenuItem(
              icon: Icons.delete_rounded,
              label: 'Clear chat',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmClear(context);
              },
            ),
            _MenuItem(
              icon: Icons.flag_rounded,
              label: 'Report',
              color: Colors.red,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    // Show full avatar viewer
    if (_showFullAvatar) {
      FullscreenImageViewer.show(context, widget.avatar, widget.name);
      setState(() => _showFullAvatar = false);
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Clear this chat?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'This will permanently delete all messages. This cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onClearChat?.call();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade600, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}