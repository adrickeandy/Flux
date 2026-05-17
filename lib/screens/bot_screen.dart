import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_window_header.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final _scrollCtrl = ScrollController();
  List<MessageModel> _messages = [];
  bool _typing = false;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('flux_bot_chat');
    if (saved != null) {
      try {
        final list = (jsonDecode(saved) as List).map((m) => MessageModel(
          id: m['id'] ?? '',
          senderId: m['senderId'] ?? '',
          senderName: m['senderName'],
          content: m['content'] ?? '',
          timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
          type: 'text',
        )).toList();
        setState(() => _messages = list);
      } catch (_) {
        _setWelcome();
      }
    } else {
      _setWelcome();
    }
    _scrollToBottom();
  }

  void _setWelcome() {
    setState(() => _messages = [
      MessageModel(
        id: 'bot-welcome',
        senderId: 'bot',
        senderName: 'PEGASUS',
        senderAvatar: null,
        content: 'I am PEGASUS. High-performance intelligence at your service. How shall we proceed today?',
        timestamp: DateTime.now(),
        type: 'text',
      ),
    ]);
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _messages.map((m) => {
      'id': m.id,
      'senderId': m.senderId,
      'senderName': m.senderName,
      'content': m.content,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    prefs.setString('flux_bot_chat', jsonEncode(list));
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flux_bot_chat');
    setState(() => _messages = []);
    _setWelcome();
  }

  Future<void> _sendMessage(String content, String type,
      {double? audioDuration, ReplyInfo? replyTo}) async {
    if (content.trim().isEmpty) return;

    final userMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      content: content.trim(),
      timestamp: DateTime.now(),
      type: 'text',
      status: 'read',
    );

    setState(() {
      _messages.add(userMsg);
      _typing = true;
    });
    _scrollToBottom();

    try {
      // Build conversation history for context
      final history = _messages
          .where((m) => m.senderId != 'bot' || m.id == 'bot-welcome')
          .take(10)
          .map((m) => m.senderId == 'bot'
              ? Content.model([TextPart(m.content)])
              : Content.text(m.content))
          .toList();

      final responseStream = _model.generateContentStream(
        [Content.text(content.trim())],
      );

      final botReplyId = '${DateTime.now().millisecondsSinceEpoch}_bot';
      var botReplyContent = '';
      var firstChunk = true;

      await for (final chunk in responseStream) {
        botReplyContent += chunk.text ?? '';

        if (firstChunk) {
          final botReply = MessageModel(
            id: botReplyId,
            senderId: 'bot',
            senderName: 'PEGASUS',
            content: botReplyContent,
            timestamp: DateTime.now(),
            type: 'text',
          );
          setState(() {
            _messages.add(botReply);
            _typing = false;
          });
          firstChunk = false;
        } else {
          setState(() {
            final last = _messages.last;
            _messages[_messages.length - 1] = MessageModel(
              id: last.id,
              senderId: last.senderId,
              senderName: last.senderName,
              content: botReplyContent,
              timestamp: last.timestamp,
              type: last.type,
            );
          });
        }
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _typing = false;
        _messages.add(MessageModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          senderId: 'bot',
          senderName: 'PEGASUS',
          content: 'Something went wrong. Please try again.',
          timestamp: DateTime.now(),
          type: 'text',
        ));
      });
    }

    _saveMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // No BottomNav — matches Next.js
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ChatWindowHeader(
          name: 'PEGASUS',
          subtitle: 'AI ASSISTANT',
          id: 'bot',
          actions: [
            GestureDetector(
              onTap: _clearChat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: kPrimary),
                    SizedBox(width: 4),
                    Text('CLEAR',
                      style: TextStyle(
                        fontSize: 9,
                        color: kPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                // Typing indicator
                if (_typing && i == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bot avatar
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                            gradient: kGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A2540)
                                : Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(4),
                            ),
                            border: Border.all(
                                color: kPrimary.withOpacity(0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5, height: 5,
                                decoration: const BoxDecoration(
                                  color: kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'PEGASUS is thinking...',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final msg = _messages[i];
                final isMe = msg.senderId != 'bot';
                final isBot = msg.senderId == 'bot';

                // Show bot avatar on each bot message
                return ChatBubble(
                  message: msg,
                  isMe: isMe,
                  showAvatar: isBot,
                  showTail: true,
                  onReact: (e) {
                    // Bot messages don't need reactions but handle gracefully
                  },
                );
              },
            ),
          ),

          // Message input — no voice recording for bot (text only)
          MessageInput(
            onSend: (content, type, {file, audioDuration, replyTo}) {
              if (content.trim().isNotEmpty) {
                _sendMessage(content, type,
                    audioDuration: audioDuration, replyTo: replyTo);
              }
            },
          ),
        ],
      ),
    );
  }
}