import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/bottom_nav.dart';

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

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('flux_bot_chat');
    if (saved != null) {
      final list = (jsonDecode(saved) as List).map((m) => MessageModel(
        id: m['id'], senderId: m['senderId'],
        senderName: m['senderName'], content: m['content'],
        timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
        type: 'text',
      )).toList();
      setState(() => _messages = list);
    } else {
      setState(() => _messages = [
        MessageModel(
          id: 'bot-1', senderId: 'bot', senderName: 'PEGASUS',
          content: 'I am PEGASUS. High-performance intelligence at your service. How shall we proceed today?',
          timestamp: DateTime.now(), type: 'text',
        ),
      ]);
    }
    _scrollToBottom();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _messages.map((m) => {
      'id': m.id, 'senderId': m.senderId, 'senderName': m.senderName,
      'content': m.content, 'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    prefs.setString('flux_bot_chat', jsonEncode(list));
  }

  Future<void> _sendMessage(String content, String type, {ReplyInfo? replyTo}) async {
    final userMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me', content: content,
      timestamp: DateTime.now(), type: 'text', status: 'read',
    );
    setState(() { _messages.add(userMsg); _typing = true; });
    _scrollToBottom();

    final history = _messages.map((m) => Content.model([TextPart(m.content)])).toList();
    final responseStream = _model.generateContentStream([Content.text(content), ...history]);

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
          final lastMessage = _messages.last;
          _messages.last = MessageModel(
            id: lastMessage.id,
            senderId: lastMessage.senderId,
            senderName: lastMessage.senderName,
            content: botReplyContent,
            timestamp: lastMessage.timestamp,
            type: lastMessage.type,
          );
        });
      }
      _scrollToBottom();
    }
    _saveMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.06 * 255).round()), blurRadius: 16)],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('PEGASUS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                        Text('AI Assistant', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ]),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          setState(() => _messages = []);
                          final prefs = await SharedPreferences.getInstance();
                          prefs.remove('flux_bot_chat');
                          _loadMessages();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 14, color: kPrimary),
                        label: const Text('CLEAR', style: TextStyle(fontSize: 9, color: kPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ]),
                  ),
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_typing && i == _messages.length) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: kPrimary.withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (j) =>
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 400 + j * 150),
                                builder: (_, v, __) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withAlpha(((0.3 + v * 0.7) * 255).round()),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )),
                          ),
                        ]),
                      );
                    }
                    final msg = _messages[i];
                    return ChatBubble(message: msg, isMe: msg.senderId != 'bot');
                  },
                ),
              ),

              MessageInput(
                onSend: (content, type, {file, replyTo}) {
                  _sendMessage(content, type, replyTo: replyTo);
                },
              ),
            ],
          ),
          const BottomNav(currentIndex: 2),
        ],
      ),
    );
  }
}
