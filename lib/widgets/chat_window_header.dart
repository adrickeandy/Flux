import 'package:flutter/material.dart';

class ChatWindowHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String? avatar;
  final String subtitle;
  final String id;
  final bool isGroup;
  final VoidCallback onToggleSearch;
  final VoidCallback onClearChat;

  const ChatWindowHeader({
    super.key,
    required this.name,
    this.avatar,
    required this.subtitle,
    required this.id,
    this.isGroup = false,
    required this.onToggleSearch,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
            backgroundImage: avatar != null && avatar!.isNotEmpty
                ? NetworkImage(avatar!)
                : null,
            child: avatar == null || avatar!.isEmpty
                ? Icon(isGroup ? Icons.group_rounded : Icons.person_rounded, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11, 
                    color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(180),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: onToggleSearch,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'clear') {
              onClearChat();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
