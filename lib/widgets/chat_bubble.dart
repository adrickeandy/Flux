import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'status_ticks.dart';
import 'fullscreen_image.dart';
import 'avatar_widget.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showTail;
  final VoidCallback? onReply;
  final VoidCallback? onStar;
  final void Function(String emoji)? onReact;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.showTail = true,
    this.onReply,
    this.onStar,
    this.onReact,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  static const _reactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

  bool _audioPlaying = false;
  double _audioProgress = 0;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reaction emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactions.map((e) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onReact?.call(e);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 26)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBtn(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: () { Navigator.pop(context); widget.onReply?.call(); },
                ),
                _ActionBtn(
                  icon: Icons.star_rounded,
                  label: 'Star',
                  onTap: () { Navigator.pop(context); widget.onStar?.call(); },
                ),
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
    final bubbleColor = widget.isMe
        ? kPrimary
        : (isDark ? const Color(0xFF1A2540) : Colors.white);
    final textColor = widget.isMe
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF111827));

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onLongPress: _showReactionPicker,
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.isMe ? 60 : (widget.showAvatar ? 8 : 12),
              right: widget.isMe ? 12 : 60,
              top: 2, bottom: 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: widget.isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                // Bot/group avatar
                if (!widget.isMe && widget.showAvatar) ...[
                  AvatarWidget(
                    url: widget.message.senderAvatar,
                    name: widget.message.senderName ?? '',
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                ],

                Flexible(
                  child: Column(
                    crossAxisAlignment: widget.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Sender name (group/bot)
                      if (!widget.isMe && widget.message.senderName != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text(
                            widget.message.senderName!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: kPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                      // Reply preview
                      if (widget.message.replyTo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(color: kPrimary, width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.message.replyTo!.senderName,
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message.replyTo!.content,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textColor.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                      // Bubble
                      Container(
                        padding: widget.message.type == 'image'
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.message.type == 'image'
                              ? Colors.transparent
                              : bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(
                                widget.isMe ? 20 : (widget.showTail ? 4 : 20)),
                            bottomRight: Radius.circular(
                                widget.isMe ? (widget.showTail ? 4 : 20) : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildContent(context, textColor),
                      ),

                      // Reactions
                      if (widget.message.reactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.message.reactions.join(' '),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),

                      // Timestamp + status
                      Padding(
                        padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatTime(widget.message.timestamp),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.isMe) ...[
                              const SizedBox(width: 4),
                              StatusTicks(status: widget.message.status),
                            ],
                            if (widget.message.isStarred)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.star_rounded,
                                    size: 11, color: Colors.amber),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (widget.message.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GestureDetector(
            onTap: () => FullscreenImageViewer.show(
                context, widget.message.mediaUrl, widget.message.senderName ?? ''),
            child: CachedNetworkImage(
              imageUrl: widget.message.mediaUrl!,
              width: 220, height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 220, height: 200,
                color: kPrimary.withOpacity(0.1),
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
        );

      case 'audio':
        final duration = widget.message.audioDuration ?? 12;
        final heights = [0.4, 0.7, 0.3, 0.8, 0.5, 0.9,
                         0.4, 0.6, 0.3, 0.7, 0.5, 0.8, 0.4, 0.6, 0.9, 0.3];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _audioPlaying = !_audioPlaying),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Colors.white.withOpacity(0.2)
                      : kPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _audioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.isMe ? Colors.white : kPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 130,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(heights.length, (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        height: 24 * heights[i],
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? (_audioProgress > (i / heights.length)
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3))
                              : (_audioProgress > (i / heights.length)
                                  ? kPrimary
                                  : kPrimary.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.music_note_rounded, size: 10,
                          color: textColor.withOpacity(0.4)),
                      Text(
                        '${(duration / 60).floor()}:${(duration % 60).toStringAsFixed(0).padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      case 'document':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.insert_drive_file_rounded,
                  color: widget.isMe ? Colors.white : kPrimary, size: 22),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.fileName ?? 'Document',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.message.fileSize != null)
                    Text(
                      widget.message.fileSize!,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      default:
        return Text(
          widget.message.content,
          style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
        );
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}