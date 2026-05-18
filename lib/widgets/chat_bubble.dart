import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
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
  final void Function(String msgId)? onDoubleTap;
  final void Function(String url, String name)? onTapImage;
  final void Function(String msgId, int optionIndex)? onVote;
  final void Function(String senderId)? onTapSender;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.showTail = true,
    this.onReply,
    this.onStar,
    this.onReact,
    this.onDoubleTap,
    this.onTapImage,
    this.onVote,
    this.onTapSender,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  static const _reactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
  bool _audioPlaying = false;
  double _slideOffset = 0;
  int _lastTap = 0;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
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

  void _showReactions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
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
                onTap: () {
                  Navigator.pop(context);
                  widget.onReact?.call(e);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBtn(icon: Icons.reply_rounded, label: 'Reply',
                    onTap: () { Navigator.pop(context); widget.onReply?.call(); }),
                if (widget.onStar != null)
                  _ActionBtn(icon: Icons.star_rounded, label: 'Star',
                      onTap: () { Navigator.pop(context); widget.onStar?.call(); }),
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
          onLongPress: _showReactions,
          onTap: () {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastTap < 300) widget.onDoubleTap?.call(widget.message.id);
            _lastTap = now;
          },
          child: Transform.translate(
            offset: Offset(_slideOffset, 0),
            child: Padding(
              padding: EdgeInsets.only(
                left: widget.isMe ? 60 : (widget.showAvatar ? 8 : 12),
                right: widget.isMe ? 12 : 60,
                top: 1, bottom: 1,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: widget.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!widget.isMe && widget.showAvatar) ...[
                    GestureDetector(
                      onTap: () => widget.onTapSender?.call(widget.message.senderId),
                      child: AvatarWidget(
                        url: widget.message.senderAvatar,
                        name: widget.message.senderName ?? '',
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else if (!widget.isMe)
                    const SizedBox(width: 34),

                  Flexible(
                    child: Column(
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!widget.isMe && widget.message.senderName != null && widget.showTail)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 2),
                            child: Text(
                              widget.message.senderName!,
                              style: const TextStyle(
                                fontSize: 8, color: kPrimary,
                                fontWeight: FontWeight.w900, letterSpacing: 0.5,
                              ),
                            ),
                          ),

                        if (widget.message.replyTo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(left: BorderSide(color: kPrimary, width: 3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message.replyTo!.senderName,
                                  style: const TextStyle(color: kPrimary, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message.replyTo!.content,
                                  style: TextStyle(fontSize: 10, color: textColor.withAlpha(179)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                        // Main bubble
                        Container(
                          padding: widget.message.type == 'image'
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.message.type == 'image'
                                ? Colors.transparent : bubbleColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(
                                  widget.isMe ? 18 : (widget.showTail ? 4 : 18)),
                              bottomRight: Radius.circular(
                                  widget.isMe ? (widget.showTail ? 4 : 18) : 18),
                            ),
                            border: widget.isMe ? null : Border.all(
                                color: Colors.grey.withAlpha(13)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 8, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildContent(context, textColor),
                        ),

                        // Reactions
                        if (widget.message.reactions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withAlpha(25)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
                              ],
                            ),
                            child: Text(
                              widget.message.reactions.join(' '),
                              style: const TextStyle(fontSize: 12),
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
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (widget.message.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GestureDetector(
            onTap: () => widget.onTapImage?.call(
                widget.message.mediaUrl!, widget.message.fileName ?? 'Image'),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.message.mediaUrl!,
                  width: 220, height: 200, fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 6, right: 8,
                  child: Row(
                    children: [
                      Text(widget.message.timestamp,
                          style: const TextStyle(fontSize: 7, color: Colors.white,
                              fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 4)])),
                      if (widget.isMe) ...[
                        const SizedBox(width: 3),
                        StatusTicks(status: widget.message.status),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case 'audio':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _audioPlaying = !_audioPlaying),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: widget.isMe ? Colors.white.withAlpha(51) : kPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _audioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.isMe ? Colors.white : Colors.white, size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(12, (i) {
                    final heights = [0.4, 0.7, 0.3, 0.9, 0.5, 0.8, 0.4, 0.6, 0.3, 0.7, 0.5, 0.8];
                    return Container(
                      width: 3, height: 24 * heights[i],
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.white.withAlpha(179) : kPrimary.withAlpha(179),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                _timestampRow(textColor),
              ],
            ),
          ],
        );

      case 'document':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white.withAlpha(51) : kPrimary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.insert_drive_file_rounded,
                  color: widget.isMe ? Colors.white : kPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.message.fileName ?? 'Document',
                      style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  if (widget.message.fileSize != null)
                    Text(widget.message.fileSize!,
                        style: TextStyle(color: textColor.withAlpha(153), fontSize: 9)),
                  _timestampRow(textColor),
                ],
              ),
            ),
          ],
        );

      case 'poll':
        final meta = widget.message.meta;
        final options = List<String>.from(meta?['options'] ?? []);
        final votes = Map<String, dynamic>.from(meta?['votes'] ?? {});
        final totalVotes = votes.values.fold<int>(
            0, (acc, v) => acc + (v is List ? v.length : 0));

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          constraints: const BoxConstraints(minWidth: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.bar_chart_rounded, size: 12, color: kPrimary),
                const SizedBox(width: 4),
                const Text('LIVE POLL',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                        color: kPrimary, letterSpacing: 2)),
              ]),
              const SizedBox(height: 8),
              Text(widget.message.content,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 8),
              ...options.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                final optVotes = List.from(votes['$idx'] ?? []);
                final count = optVotes.length;
                final pct = totalVotes > 0 ? count / totalVotes : 0.0;

                return GestureDetector(
                  onTap: () => widget.onVote?.call(widget.message.id, idx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(13)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(color: kPrimary.withAlpha(51)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(opt,
                                  style: const TextStyle(fontSize: 10,
                                      color: Colors.white, fontWeight: FontWeight.w600)),
                              Text('${(pct * 100).round()}%',
                                  style: const TextStyle(fontSize: 9,
                                      color: kPrimary, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Text('$totalVotes TOTAL VOTES',
                  style: TextStyle(fontSize: 7, color: Colors.white.withAlpha(102),
                      fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 4),
              _timestampRow(Colors.white),
            ],
          ),
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.message.content,
                style: TextStyle(color: textColor, fontSize: 11, height: 1.4)),
            const SizedBox(height: 2),
            _timestampRow(textColor),
          ],
        );
    }
  }

  Widget _timestampRow(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.message.timestamp,
            style: TextStyle(
                fontSize: 7, color: textColor.withAlpha(179), fontWeight: FontWeight.w700)),
        if (widget.isMe) ...[
          const SizedBox(width: 3),
          StatusTicks(status: widget.message.status),
        ],
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kPrimary.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}