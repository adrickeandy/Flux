import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_window_header.dart';
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

  static const _botAvatar = 'https://picsum.photos/seed/pegasus/200/200';

  @override
  void initState() {
    super.initState();
    _model =
        FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash');
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
        final list = (jsonDecode(saved) as List)
            .map((m) => MessageModel(
                  id: m['id'] ?? '',
                  senderId: m['senderId'] ?? '',
                  senderName: m['senderName'],
                  senderAvatar: m['senderAvatar'],
                  content: m['content'] ?? '',
                  timestamp: m['timestamp'] ?? '',
                  type: 'text',
                ))
            .toList();
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
    final now = DateTime.now();
    setState(() => _messages = [
          MessageModel(
            id: 'bot-1',
            senderId: 'bot',
            senderName: 'PEGASUS',
            senderAvatar: _botAvatar,
            content:
                'I am PEGASUS. High-performance intelligence at your service. How shall we proceed today?',
            timestamp:
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            type: 'text',
          ),
        ]);
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'flux_bot_chat',
        jsonEncode(_messages
            .map((m) => {
                  'id': m.id,
                  'senderId': m.senderId,
                  'senderName': m.senderName,
                  'senderAvatar': m.senderAvatar,
                  'content': m.content,
                  'timestamp': m.timestamp,
                })
            .toList()));
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flux_bot_chat');
    setState(() => _messages = []);
    _setWelcome();
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(MessageModel(
        id: '${now.millisecondsSinceEpoch}',
        senderId: 'me',
        content: content,
        timestamp: ts,
        type: 'text',
      ));
      _typing = true;
    });
    _scrollToBottom();

    try {
      final stream = _model.generateContentStream([Content.text(content)]);
      final botId = '${now.millisecondsSinceEpoch}_bot';
      var botContent = '';
      var first = true;

      await for (final chunk in stream) {
        botContent += chunk.text ?? '';
        final botNow = DateTime.now();
        final botTs =
            '${botNow.hour.toString().padLeft(2, '0')}:${botNow.minute.toString().padLeft(2, '0')}';
        if (first) {
          setState(() {
            _messages.add(MessageModel(
              id: botId,
              senderId: 'bot',
              senderName: 'PEGASUS',
              senderAvatar: _botAvatar,
              content: botContent,
              timestamp: botTs,
              type: 'text',
            ));
            _typing = false;
          });
          first = false;
        } else {
          setState(() {
            final last = _messages.last;
            _messages[_messages.length - 1] = MessageModel(
              id: last.id,
              senderId: last.senderId,
              senderName: last.senderName,
              senderAvatar: last.senderAvatar,
              content: botContent,
              timestamp: last.timestamp,
              type: last.type,
            );
          });
        }
        _scrollToBottom();
      }
    } catch (_) {
      final now2 = DateTime.now();
      setState(() {
        _typing = false;
        _messages.add(MessageModel(
          id: '${now2.millisecondsSinceEpoch}_err',
          senderId: 'bot',
          senderName: 'PEGASUS',
          senderAvatar: _botAvatar,
          content:
              'Pegasus is temporarily offline. Please try again in a moment.',
          timestamp:
              '${now2.hour.toString().padLeft(2, '0')}:${now2.minute.toString().padLeft(2, '0')}',
          type: 'text',
          ));
      });
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ChatWindowHeader(
          name: 'PEGASUS',
          avatar: _botAvatar,
          subtitle: 'LEGENDARY ASSISTANT',
          id: 'bot',
          isGroup: false,
          onToggleSearch: () {
            // Optional: Implement internal search logic if needed later
          },
          onClearChat: _clearChat,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(13),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryColor.withAlpha(51)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              ...List.generate(
                                  3,
                                  (index) => Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                      )),
                              const SizedBox(width: 8),
                              Text('PEGASUS is thinking',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2)),
                            ]),
                          ),
                        ]),
                      );
                    }

                    final msg = _messages[i];
                    final isBot = msg.senderId == 'bot';
                    final isLastInGroup = i == _messages.length - 1 ||
                        _messages[i + 1].senderId != msg.senderId;

                    return ChatBubble(
                      message: msg,
                      isMe: !isBot,
                      showAvatar: isBot && isLastInGroup,
                      showTail: isLastInGroup,
                    );
                  },
                ),
              ),
              MessageInput(
                onSend: (content, type, {file, meta, replyTo}) {
                  if (content.isNotEmpty) _sendMessage(content);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
          BottomNav(currentIndex: 2),
        ],
      ),
    );
  }
}
