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
    Map<String, dynamic>? meta,
    ReplyInfo? replyTo,
  }) onSend;
  final VoidCallback? onTyping;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onTyping,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;
  bool _showEmoji = false;
  bool _isRecording = false;
  bool _isCreatingPoll = false;
  int _recordedSecs = 0;

  // Poll
  final _pollQCtrl = TextEditingController();
  final List<TextEditingController> _pollOptCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  final _picker = ImagePicker();

  static const _emojiCategories = [
    _EmojiCat('Smileys', ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😍','🥰','😘','😋','😛','😜','😎','🤩','🥳','😏','😒','😞','😔','😟','😭','😤','😠','😡','🤬','😱','😨','🤗','🤔','😶','😬','🙄','😮']),
    _EmojiCat('Gestures', ['👋','🤚','✋','👌','✌️','🤞','👍','👎','👏','🙌','🙏','💪','🤝','☝️','👈','👉','👆','👇']),
    _EmojiCat('Nature', ['🐶','🐱','🐭','🐰','🦊','🐻','🐼','🐯','🦁','🐮','🐸','🦋','🌸','🌺','🌻','🌹','🍀','🌴','🌊','⭐','🌙','☀️','❄️','🔥','💧']),
    _EmojiCat('Food', ['🍎','🍊','🍋','🍌','🍉','🍇','🍓','🍒','🥑','🍕','🍔','🍟','🌮','🍜','🍣','🍦','🎂','🍫','☕','🍵','🥤','🍺','🍷']),
    _EmojiCat('Activities', ['⚽','🏀','🎾','🏈','🎱','🏓','🎮','🎲','🏆','🥇','🎭','🎨','🎹','🎸','🥁','🎬']),
    _EmojiCat('Travel', ['🚗','🚌','🚀','✈️','🚢','⛵','🚲','🏔','🏖','🏙','🌋','🗺','🗼','🏰','⛩']),
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
    _pollQCtrl.dispose();
    for (final c in _pollOptCtrls) { c.dispose(); }
    super.dispose();
  }

  void _send() {
    if (_hasText) {
      widget.onSend(_ctrl.text.trim(), 'text');
      _ctrl.clear();
    } else if (!_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  void _startRecording() {
    setState(() { _isRecording = true; _recordedSecs = 0; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return false;
      setState(() => _recordedSecs++);
      return true;
    });
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    widget.onSend('Voice Message', 'audio');
  }

  String _fmtTime(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _pickMedia({bool camera = false}) async {
    final img = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (img == null) return;
    widget.onSend('', 'image', file: File(img.path));
  }

  void _sendPoll() {
    final q = _pollQCtrl.text.trim();
    if (q.isEmpty) return;
    final opts = _pollOptCtrls.map((c) => c.text.trim()).where((o) => o.isNotEmpty).toList();
    if (opts.length < 2) return;
    widget.onSend(q, 'poll', meta: {'options': opts, 'votes': {}});
    _pollQCtrl.clear();
    for (final c in _pollOptCtrls) { c.clear(); }
    setState(() => _isCreatingPoll = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Poll creator
        if (_isCreatingPoll)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? kCardDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kPrimary.withAlpha(51)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      Icon(Icons.bar_chart_rounded, size: 16, color: kPrimary),
                      SizedBox(width: 6),
                      Text('Create Poll',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                              color: kPrimary, letterSpacing: 2)),
                    ]),
                    GestureDetector(
                      onTap: () => setState(() => _isCreatingPoll = false),
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pollQCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ..._pollOptCtrls.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(
                    controller: e.value,
                    decoration: InputDecoration(
                      hintText: 'Option ${e.key + 1}',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                )),
                GestureDetector(
                  onTap: () => setState(() => _pollOptCtrls.add(TextEditingController())),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withAlpha(51), style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Add Option',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                                color: Colors.grey, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _sendPoll,
                  child: Container(
                    width: double.infinity, height: 40,
                    decoration: BoxDecoration(
                      gradient: kGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Share Poll',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                            fontSize: 11, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),

        // Main input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, child) => CustomPaint(
              painter: _GlowPainter(angle: _glowAnim.value, isDark: isDark),
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: (isDark ? kCardDark : Colors.white).withAlpha(242),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment menu
                    if (!_isRecording) ...[
                      _buildAttachBtn(),
                      // Emoji
                      GestureDetector(
                        onTap: () {
                          setState(() => _showEmoji = !_showEmoji);
                          if (_showEmoji) _focus.unfocus();
                          else _focus.requestFocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4, 8),
                          child: Icon(
                            _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_rounded,
                            color: Colors.grey.shade500, size: 22,
                          ),
                        ),
                      ),
                    ],

                    // Text input / recording
                    Expanded(
                      child: _isRecording
                          ? _recordingWidget()
                          : TextField(
                              controller: _ctrl,
                              focusNode: _focus,
                              minLines: 1, maxLines: 5,
                              onChanged: (_) => widget.onTyping?.call(),
                              onTap: () => setState(() => _showEmoji = false),
                              style: const TextStyle(fontSize: 11),
                              decoration: InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400.withAlpha(102), fontSize: 11),
                                border: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 4),
                              ),
                            ),
                    ),

                    // Send / mic button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _send,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(right: 2, bottom: 2),
                        decoration: BoxDecoration(
                          gradient: (_hasText || _isRecording) ? kGradient : null,
                          color: (_hasText || _isRecording) ? null : Colors.grey.withAlpha(25),
                          shape: BoxShape.circle,
                          boxShadow: (_hasText || _isRecording)
                              ? [BoxShadow(color: kPrimary.withAlpha(102), blurRadius: 12)]
                              : [],
                        ),
                        child: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : (_hasText ? Icons.send_rounded : Icons.mic_rounded),
                          color: (_hasText || _isRecording) ? Colors.white : kPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Emoji picker
        if (_showEmoji) _buildEmojiPicker(isDark),
      ],
    );
  }

  Widget _buildAttachBtn() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'gallery') _pickMedia();
        if (val == 'camera') _pickMedia(camera: true);
        if (val == 'poll') setState(() => _isCreatingPoll = true);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'gallery',
            child: Row(children: [
              Icon(Icons.image_rounded, color: Colors.blue, size: 18),
              SizedBox(width: 10),
              Text('Media', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
        const PopupMenuItem(value: 'camera',
            child: Row(children: [
              Icon(Icons.camera_alt_rounded, color: Colors.red, size: 18),
              SizedBox(width: 10),
              Text('Camera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
        const PopupMenuItem(value: 'poll',
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, color: Colors.amber, size: 18),
              SizedBox(width: 10),
              Text('Poll', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 2, 8),
        child: Icon(Icons.add_rounded, color: Colors.grey.shade500, size: 22),
      ),
    );
  }

  Widget _recordingWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('Recording ${_fmtTime(_recordedSecs)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() { _isRecording = false; _recordedSecs = 0; }),
            child: Text('Cancel',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(bool isDark) {
    return DefaultTabController(
      length: _emojiCategories.length,
      child: Container(
        height: 280,
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
              labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              tabs: _emojiCategories.map((c) => Tab(text: c.label)).toList(),
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
                        child: Text(cat.emojis[i], style: const TextStyle(fontSize: 22))),
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(34)),
      Paint()
        ..shader = SweepGradient(
          startAngle: angle, endAngle: angle + 2 * pi,
          colors: const [Color(0xFF833AB4), Color(0xFFfd1d1d), Color(0xFFfcb045), Color(0xFF833AB4)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.angle != angle;
}