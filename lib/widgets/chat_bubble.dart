import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'status_ticks.dart';
import 'fullscreen_image.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onReply;
  final VoidCallback? onStar;
  final void Function(String emoji)? onReact;
  final VoidCallback? onTapSender;
  final bool showTail;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.onReply,
    this.onStar,
    this.onReact,
    this.onTapSender,
    this.showTail = true,
  });

  static const _reactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactions.map((e) => GestureDetector(
                onTap: () { Navigator.pop(context); onReact?.call(e); },
                child: Text(e, style: const TextStyle(fontSize: 30)),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OptionBtn(icon: Icons.reply_rounded, label: 'Reply', onTap: () { Navigator.pop(context); onReply?.call(); }),
                _OptionBtn(icon: Icons.star_rounded, label: 'Star', onTap: () { Navigator.pop(context); onStar?.call(); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMe
        ? kPrimary
        : (isDark ? const Color(0xFF1A2540) : const Color(0xFFF1F3FA));
    final textColor = isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827));

    return GestureDetector(
      onLongPress: () => _showReactionPicker(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          top: 2,
          bottom: 2,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Reply preview
            if (message.replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: kPrimary, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.replyTo!.senderName,
                        style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(message.replyTo!.content,
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

            // Bubble
            Container(
              padding: message.type == 'image'
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.type == 'image' ? Colors.transparent : bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : (showTail ? 4 : 20)),
                  bottomRight: Radius.circular(isMe ? (showTail ? 4 : 20) : 20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: _buildContent(context, textColor),
            ),

            // Reactions
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2540) : const Color(0xFFF1F3FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(message.reactions.join(' '), style: const TextStyle(fontSize: 13)),
                ),
              ),

            // Timestamp + status
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTime(message.timestamp),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    StatusTicks(status: message.status),
                  ],
                  if (message.isStarred)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GestureDetector(
            onTap: () => FullscreenImageViewer.show(context, message.mediaUrl!, message.senderName ?? ''),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl!,
              width: 220,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 220, height: 200,
                color: kPrimary.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
        );
      case 'audio':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120, height: 3,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 6),
                Text('Voice message', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10)),
              ],
            ),
          ],
        );
      case 'document':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: Colors.white70, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.fileName ?? 'Document',
                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  if (message.fileSize != null)
                    Text(message.fileSize!, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
        );
    }
  }
}

class _OptionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}