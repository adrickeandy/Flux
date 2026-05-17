import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';

class MessageInput extends StatefulWidget {
  final void Function(
    String content,
    String type, {
    File? file,
    double? audioDuration,
    ReplyInfo? replyTo,
  }) onSend;
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

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  bool _hasText      = false;
  bool _showEmoji    = false;
  bool _isRecording  = false;
  bool _isReviewing  = false;
  bool _isPlaying    = false;
  int  _recordedSecs = 0;
  int  _playbackSecs = 0;

  late AnimationController _glowCtrl;
  late Animation<double>   _glowAnim;

  final _picker = ImagePicker();
  int? _recordTimer;
  int? _playTimer;

  static const _emojiCategories = [
    _EmojiCat('Smileys', ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😍','🥰','😘','😋','😛','😜','😎','🤩','🥳','😏','😒','😞','😔','😟','😭','😤','😠','😡','🤬','🤯','😱','😨','😰','🤗','🤔','🤫','😶','😬','🙄','😮','😴','🤐','🤢','🤮','🤧','😷','💩','👍','👎','👏','🙌','🤝','🙏','💪','✌️','🤞','👌','🤏']),
    _EmojiCat('Animals', ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🦍','🐕','🐩','🐺','🦝','🐈','🐅','🐆','🐴','🦄','🦓','🦌','🐘','🦏','🦛','🐁','🐀','🐿️','🦔','🦇','🦥','🦦','🐉','🌵','🌲','🌳','🌴','🌿','🍀','🌷','🌹','🌺','🌸','🌼','🌻']),
    _EmojiCat('Food', ['🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🍆','🥑','🥦','🌽','🥕','🍞','🧀','🥚','🍳','🥓','🥩','🍔','🍟','🍕','🌭','🌮','🌯','🥗','🍜','🍣','🍱','🍦','🎂','🍰','🧁','🍫','🍬','🍭','☕','🍵','🥤','🍺','🍷']),
    _EmojiCat('Activity', ['⚽️','🏀','🏈','⚾️','🎾','🏐','🏉','🎱','🏓','🏸','⛳️','🎯','🎮','🕹','🎲','🧩','🧸','🎭','🎨','🎹','🥁','🎸','🎻','🎺','🎷','🎧','🎤','🎬','🏆','🥇','🥈','🥉','🎗','🎟','🎪','🤸','🏋️','🤼','🤺','🏇','🤾','🏊','🤽','🚣','🧘']),
    _EmojiCat('Travel', ['🚗','🚕','🚙','🚌','🏎','🚓','🚑','🚒','🚐','🚚','🛵','🚲','🛺','⛽️','🚨','🚥','🚦','⚓️','⛵️','🚤','🛳','✈️','🛩','🚁','🚀','🛸','🏔','⛰','🌋','🗻','🏕','🏖','🏜','🏝','🏟','🌅','🌄','🌆','🌇','🌉','🌃','🏙','🗼','🗽','⛩','🌐']),
    _EmojiCat('Objects', ['⌚️','📱','💻','⌨️','🖥','🖨','🖱','💽','💾','💿','📷','📸','📹','🎥','📞','☎️','📺','📻','🧭','⏱','⏰','🔋','🔌','💡','🔦','🕯','💰','💳','💎','🔒','🔓','🔧','🔨','⚒','🛠','⛏','🪚','🔩','⚙️','🧰','🧲','⚗️','🔬','🔭','📡','💊','💉','🧹','🧺','🧻']),
    _EmojiCat('Symbols', ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','☮️','✝️','☪️','🕉','☸️','✡️','☯️','☦️','♈️','♉️','♊️','♋️','♌️','♍️','♎️','♏️','♐️','♑️','♒️','♓️','❌','⭕️','🛑','⛔️','🚫','💯','💢','♻️','✅','❇️','✳️','❎','💠','🌀','🔴','🟠','🟡','🟢','🔵','🟣','⚫️','⚪️']),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.trim().isNotEmpty));
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat();
    _glowAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_glowCtrl);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (_hasText) {
      widget.onSend(
        _ctrl.text.trim(), 'text',
        replyTo: widget.replyingTo != null
            ? ReplyInfo(
                id: widget.replyingTo!.id,
                senderName: widget.replyingTo!.senderName ?? '',
                content: widget.replyingTo!.content,
              )
            : null,
      );
      _ctrl.clear();
      widget.onCancelReply?.call();
    } else if (_isReviewing) {
      widget.onSend('Voice Message', 'audio', audioDuration: _recordedSecs.toDouble());
      _resetReview();
    } else if (!_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  void _startRecording() {
    setState(() { _isRecording = true; _recordedSecs = 0; });
    _recordTimer = null;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;
      setState(() => _recordedSecs++);
      return true;
    });
  }

  void _stopRecording() {
    setState(() { _isRecording = false; _isReviewing = true; _playbackSecs = 0; });
  }

  void _resetReview() {
    setState(() {
      _isReviewing = false;
      _isPlaying = false;
      _playbackSecs = 0;
      _recordedSecs = 0;
    });
  }

  void _togglePlayback() {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
    } else {
      if (_playbackSecs >= _recordedSecs) setState(() => _playbackSecs = 0);
      setState(() => _isPlaying = true);
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isPlaying || !mounted) return false;
        if (_playbackSecs >= _recordedSecs) {
          setState(() => _isPlaying = false);
          return false;
        }
        setState(() => _playbackSecs++);
        return true;
      });
    }
  }

  String _fmtTime(int s) =>
      '${(s ~/ 60)}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _pickImage({bool camera = false}) async {
    final img = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
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
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: kPrimary, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.replyingTo!.senderName ?? '',
                        style: const TextStyle(
                          color: kPrimary, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        widget.replyingTo!.content,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
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

        // Input row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Glow border input
              Expanded(
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, child) => CustomPaint(
                    painter: _GlowPainter(angle: _glowAnim.value, isDark: isDark),
                    child: child,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? kCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!_isRecording && !_isReviewing)
                          GestureDetector(
                            onTap: () {
                              setState(() => _showEmoji = !_showEmoji);
                              if (_showEmoji) _focus.unfocus();
                              else _focus.requestFocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 4, 12),
                              child: Icon(
                                _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_rounded,
                                color: Colors.grey.shade500, size: 22,
                              ),
                            ),
                          ),
                        Expanded(
                          child: _isRecording
                              ? _recordingWidget()
                              : _isReviewing
                                  ? _reviewWidget()
                                  : TextField(
                                      controller: _ctrl,
                                      focusNode: _focus,
                                      minLines: 1,
                                      maxLines: 5,
                                      onChanged: (_) => widget.onTyping?.call(),
                                      onTap: () => setState(() => _showEmoji = false),
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400, fontSize: 13),
                                        border: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 4),
                                      ),
                                    ),
                        ),
                        if (!_isRecording && !_isReviewing) ...[
                          GestureDetector(
                            onTap: () => _pickImage(),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.image_rounded,
                                    size: 18, color: Colors.grey.shade500),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _pickImage(camera: true),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 8, 12),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt_rounded,
                                    size: 18, color: Colors.grey.shade500),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send / Mic button
              GestureDetector(
                onTap: _isRecording ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: (_hasText || _isReviewing) ? kGradient : null,
                    color: (_hasText || _isReviewing) ? null : Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: (_hasText || _isReviewing)
                        ? null
                        : Border.all(color: Colors.grey.withOpacity(0.15)),
                    boxShadow: (_hasText || _isReviewing)
                        ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 16)]
                        : [],
                  ),
                  child: Icon(
                    (_hasText || _isReviewing) ? Icons.send_rounded : Icons.mic_rounded,
                    color: (_hasText || _isReviewing) ? Colors.white : kPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Emoji picker
        if (_showEmoji) _buildEmojiPicker(isDark),
      ],
    );
  }

  Widget _recordingWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _fmtTime(_recordedSecs),
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: kPrimary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _stopRecording,
            child: Row(
              children: [
                Text('Stop',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewWidget() {
    final progress = _recordedSecs > 0 ? _playbackSecs / _recordedSecs : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withOpacity(0.15),
                color: kPrimary,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmtTime(_isPlaying ? _playbackSecs : _recordedSecs),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () { _resetReview(); },
            child: Icon(Icons.delete_rounded, size: 20, color: Colors.red.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(bool isDark) {
    return DefaultTabController(
      length: _emojiCategories.length,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? kCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              indicatorColor: kPrimary,
              labelColor: kPrimary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              tabs: _emojiCategories
                  .map((c) => Tab(text: c.label))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                children: _emojiCategories.map((cat) => GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
                  itemCount: cat.emojis.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _ctrl.text += cat.emojis[i]),
                    child: Center(
                      child: Text(cat.emojis[i], style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCat {
  final String label;
  final List<String> emojis;
  const _EmojiCat(this.label, this.emojis);
}

class _GlowPainter extends CustomPainter {
  final double angle;
  final bool isDark;
  _GlowPainter({required this.angle, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = SweepGradient(
          startAngle: angle,
          endAngle: angle + 2 * pi,
          colors: const [
            Color(0xFF833AB4), Color(0xFFfd1d1d),
            Color(0xFFfcb045), Color(0xFF833AB4),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.angle != angle;
}