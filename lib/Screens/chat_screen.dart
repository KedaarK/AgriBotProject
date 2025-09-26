import 'package:flutter/material.dart';
import 'package:agribot/Services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  bool _botTyping = false;
  String? _banner; // error/info banner text

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _botTyping) return;

    // Add user message
    final userMsg = ChatMessage.user(text);
    setState(() {
      _messages.insert(0, userMsg); // newest at top (reverse list)
      _controller.clear();
      _botTyping = true;
      _banner = null;
    });
    _scrollToBottom();

    try {
      // Non-streaming call to your Flask /api/chat
      final reply = await ApiService.instance.sendMessage(text, locale: 'en');

      if (!mounted) return;
      setState(() {
        _messages.insert(0, ChatMessage.bot(reply));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _banner = 'Failed to reach server: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _botTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Because list is reversed, "bottom" is maxScrollExtent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0, // 0 because reverse: true, top is latest
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool get _showScrollFAB {
    if (!_scrollController.hasClients) return false;
    // If user scrolled away from top (remember reverse), show FAB
    return _scrollController.offset > 80;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final onBg = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AgriBot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.green,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            if (_banner != null)
              Container(
                width: double.infinity,
                color: Colors.amber.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  _banner!,
                  style: TextStyle(color: Colors.amber.shade900),
                ),
              ),

            // Messages
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true, // newest at the bottom visually
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _messages.length + (_botTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // When typing, inject a typing indicator "message" at index 0
                      if (_botTyping && index == 0) {
                        return const _TypingIndicator();
                      }
                      final msg = _messages[_botTyping ? index - 1 : index];
                      final isUser = msg.role == MessageRole.user;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // keep bubbles readable on large screens too
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.green : bg,
                              border: isUser
                                  ? null
                                  : Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : onBg,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  msg.formattedTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isUser
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Scroll-to-bottom FAB
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: AnimatedOpacity(
                      opacity: _showScrollFAB ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showScrollFAB,
                        child: FloatingActionButton.small(
                          heroTag: 'scrollBottom',
                          backgroundColor: Colors.white,
                          onPressed: _scrollToBottom,
                          child: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                    top: BorderSide(color: Color(0x33000000), width: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  // If you want an attachment button later, uncomment:
                  // IconButton(
                  //   onPressed: _pickFile,
                  //   icon: const Icon(Icons.attach_file, color: Colors.green),
                  // ),

                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _botTyping ? null : _handleSend,
                    icon: const Icon(Icons.send, color: Colors.white),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color?>(
                        (states) => _botTyping ? Colors.grey : Colors.green,
                      ),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                          const CircleBorder()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple message model for UI
enum MessageRole { user, bot }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime time;

  ChatMessage._(this.text, this.role, this.time);

  factory ChatMessage.user(String text) =>
      ChatMessage._(text, MessageRole.user, DateTime.now());
  factory ChatMessage.bot(String text) =>
      ChatMessage._(text, MessageRole.bot, DateTime.now());

  String get formattedTime {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

/// Three-dot typing indicator
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = (int i) => FadeTransition(
          opacity: Tween(begin: 0.2, end: 1.0).animate(
            CurvedAnimation(
                parent: _ac,
                curve: Interval(i * 0.15, 0.7 + i * 0.15,
                    curve: Curves.easeInOut)),
          ),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
                color: Colors.black54, shape: BoxShape.circle),
          ),
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min, children: [dot(0), dot(1), dot(2)]),
      ),
    );
  }
}
