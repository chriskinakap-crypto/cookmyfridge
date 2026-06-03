import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme.dart';
import '../services/app_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Hi! I\'m your AI chef. Ask me anything about cooking, ingredient substitutions, techniques, or nutrition!'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Center(child: Icon(Icons.restaurant, color: Colors.white, size: 18))),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Chef', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('Always available', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_sending ? 1 : 0),
          itemBuilder: (_, i) {
            if (_sending && i == _messages.length) return _typingBubble();
            final m = _messages[i];
            final isUser = m['role'] == 'user';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isUser) ...[
                    Container(width: 28, height: 28, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle), child: const Icon(Icons.restaurant, color: Colors.white, size: 14)),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(m['content']!, style: TextStyle(fontSize: 14, color: isUser ? Colors.white : Colors.black87, height: 1.4)),
                  )),
                  if (isUser) const SizedBox(width: 8),
                ],
              ),
            );
          },
        )),
        _suggestions(),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(hintText: 'Ask your chef...', hintStyle: TextStyle(fontSize: 14)),
              onSubmitted: (_) => _send(context),
            )),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sending ? null : () => _send(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48), padding: EdgeInsets.zero),
              child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _typingBubble() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 28, height: 28, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle), child: const Icon(Icons.restaurant, color: Colors.white, size: 14)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 400 + i * 150),
          builder: (_, v, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(width: 6, height: 6 + v * 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(3))),
          ),
        ))),
      ),
    ]),
  );

  Widget _suggestions() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      'How do I substitute eggs?', 'Make chicken crispier?', 'Reheat pasta properly?', 'What is al dente?',
    ].map((s) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () { _ctrl.text = s; _send(context); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0997B))),
          child: Text(s, style: const TextStyle(fontSize: 12, color: kPrimaryDark)),
        ),
      ),
    )).toList()),
  );

  Future<void> _send(BuildContext context) async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() { _messages.add({'role': 'user', 'content': msg}); _sending = true; });
    _scrollDown();
    final state = context.read<AppState>();
    final reply = await state.sendChat(msg);
    setState(() { _messages.add({'role': 'assistant', 'content': reply}); _sending = false; });
    _scrollDown();
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.ease);
  });
}
