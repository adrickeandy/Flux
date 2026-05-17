import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';

class MessageInput extends StatefulWidget {
  final void Function(String content, String type, {File? file, ReplyInfo? replyTo}) onSend;
  final VoidCallback? onTyping;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onTyping,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _showEmoji = false;
  bool _hasText = false;
  final _picker = ImagePicker();

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_glowController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (_hasText) {
      widget.onSend(_ctrl.text.trim(), 'text',
          replyTo: widget.replyingTo != null
              ? ReplyInfo(
                  id: widget.replyingTo!.id,
                  senderName: widget.replyingTo!.senderName ?? '',
                  content: widget.replyingTo!.content,
                )
              : null);
      _ctrl.clear();
      widget.onCancelReply?.call();
    }
  }

  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    widget.onSend('', 'image', file: File(img.path));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Reply bar
        if (widget.replyingTo != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: kPrimary, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.replyingTo!.senderName ?? '',
                          style: TextStyle(
                              color: kPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                      Text(widget.replyingTo!.content,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancelReply,
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),

        // Animated glow border + input
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _GlowBorderPainter(
                angle: _glowAnimation.value,
                isDark: isDark,
              ),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              color: isDark ? kCardDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_rounded,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() => _showEmoji = !_showEmoji);
                    if (_showEmoji) _focus.unfocus();
                    else _focus.requestFocus();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (_) => widget.onTyping?.call(),
                    onTap: () => setState(() => _showEmoji = false),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.image_rounded, color: Colors.grey.shade500, size: 22),
                  onPressed: _pickImage,
                ),
                GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _hasText ? kGradient : null,
                      color: _hasText ? null : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: _hasText
                          ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12)]
                          : [],
                    ),
                    child: Icon(
                      _hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: _hasText ? Colors.white : Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Emoji picker
        Offstage(
          offstage: !_showEmoji,
          child: SizedBox(
            height: 280,
            child: EmojiPicker(
              onEmojiSelected: (_, emoji) => _ctrl.text += emoji.emoji,
              config: Config(
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: isDark ? kBgDark : kBgLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double angle;
  final bool isDark;

  _GlowBorderPainter({required this.angle, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final gradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * pi,
      colors: const [
        Color(0xFF833AB4),
        Color(0xFFfd1d1d),
        Color(0xFFfcb045),
        Color(0xFF833AB4),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) => old.angle != angle;
}