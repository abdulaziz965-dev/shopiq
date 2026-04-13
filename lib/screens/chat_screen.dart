import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(
      text: "Hey! I'm ShopIQ AI 🛍️ I can help you find the best deals, compare products, detect fake reviews, and give personalized recommendations. What are you shopping for today?",
      isUser: false,
    ),
  ];
  bool _loading = false;
  final List<Map<String, String>> _history = [];

  static const _suggestions = [
    '🎧 Best earphones under ₹3000',
    '📱 iPhone vs Samsung flagship',
    '🤔 Is Sony WH-1000XM5 worth it?',
    '💻 Student laptop under ₹50000',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    final userText = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(_ChatMsg(text: userText, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    final priorHistory = List<Map<String, String>>.from(_history);

    try {
      final reply = await context.read<AIService>().chat(
        priorHistory,
        userText,
      );
      _history.add({'role': 'user', 'content': userText});
      _history.add({'role': 'assistant', 'content': reply});
      if (mounted) {
        setState(() {
          _messages.add(_ChatMsg(text: reply, isUser: false));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMsg(
            text: 'Sorry, I\'m having trouble connecting right now. Please check your API key and try again! 🔧',
            isUser: false,
          ));
          _loading = false;
        });
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages()),
            _buildSuggestions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border2, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ShopIQ AI', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Online · Powered by Claude', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.green)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTyping();
        return _buildMessage(_messages[i]);
      },
    );
  }

  Widget _buildMessage(_ChatMsg msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.accent : AppColors.card2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                border: msg.isUser ? null : Border.all(color: AppColors.border2, width: 0.5),
              ),
              child: Text(msg.text, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card2,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.border2, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _PulseDot(delay: i * 150)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(_suggestions[i].substring(2)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Center(
              child: Text(_suggestions[i],
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border2, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border2, width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: _send,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask about any product...',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _loading ? AppColors.bg4 : AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _loading ? AppColors.textMuted : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}

class _PulseDot extends StatefulWidget {
  final int delay;
  const _PulseDot({required this.delay});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: FadeTransition(
      opacity: _anim,
      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
    ),
  );
}
