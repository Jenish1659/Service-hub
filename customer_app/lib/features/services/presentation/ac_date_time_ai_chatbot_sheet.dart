import 'package:flutter/material.dart';

class ACDateTimeAIChatbotSheet extends StatefulWidget {
  final String? selectedDateText;
  final String? selectedTimeText;

  const ACDateTimeAIChatbotSheet({
    super.key,
    this.selectedDateText,
    this.selectedTimeText,
  });

  static void show(
    BuildContext context, {
    String? selectedDateText,
    String? selectedTimeText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ACDateTimeAIChatbotSheet(
        selectedDateText: selectedDateText,
        selectedTimeText: selectedTimeText,
      ),
    );
  }

  @override
  State<ACDateTimeAIChatbotSheet> createState() => _ACDateTimeAIChatbotSheetState();
}

class _ACDateTimeAIChatbotSheetState extends State<ACDateTimeAIChatbotSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<Map<String, dynamic>> _messages;

  final List<String> _quickSuggestions = [
    'Can I book for Today?',
    'How long does an AC service take?',
    'What is the pricing & raw bill estimate?',
    'How does technician arrival work?',
    'Can I reschedule later?',
  ];

  @override
  void initState() {
    super.initState();
    final dateInfo = widget.selectedDateText != null ? ' (Selected date: ${widget.selectedDateText})' : '';

    _messages = [
      {
        'isUser': false,
        'text':
            "Hello! 👋 I'm your ServiceHub Scheduling Assistant.\n\nI can help you understand our booking dates, dynamic time clock selector, service durations, and billing breakdown.$dateInfo\n\nHow can I help you?",
        'time': 'Just now',
      },
    ];
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text.trim(),
        'time': 'Just now',
      });
    });
    _messageController.clear();
    _scrollToBottom();

    // AI Response Generator tailored for AC Scheduling
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final responseText = _generateAIResponse(text);
      setState(() {
        _messages.add({
          'isUser': false,
          'text': responseText,
          'time': 'Just now',
        });
      });
      _scrollToBottom();
    });
  }

  String _generateAIResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('today') || lower.contains('same day') || lower.contains('now')) {
      return "Yes! Same-day bookings are available.\n\nWhen booking for today, you can select any slot starting 15 minutes from now so our technician can prepare tools and arrive promptly.";
    }

    if (lower.contains('bill') || lower.contains('price') || lower.contains('cost') || lower.contains('charge')) {
      return "ServiceHub provides complete price transparency! You can see the full Raw Bill breakdown before confirming your booking. No advance payment is needed—pay only after satisfactory service.";
    }

    if (lower.contains('duration') || lower.contains('how long') || lower.contains('time take')) {
      return "A standard AC diagnostic and jet cleaning service takes approximately 60 to 90 minutes.\n\nFor major repairs or complete gas refills, the technician may take up to 2 hours.";
    }

    if (lower.contains('arrival') || lower.contains('otp') || lower.contains('pin') || lower.contains('how does')) {
      return "Here is what happens after you book:\n\n1. A verified certified AC technician confirms your slot.\n2. You can track their live location in real time.\n3. Upon arrival, share your Entrance PIN to start the service.\n4. After inspection and testing, verify with your completion OTP.";
    }

    if (lower.contains('reschedule') || lower.contains('cancel') || lower.contains('change')) {
      return "Yes! You can easily reschedule or cancel your visit free of charge from your 'Track Booking' screen up to 2 hours before the scheduled time.";
    }

    return "For your AC service, please choose your preferred date and time on the clock dial.\n\nOur verified technician will arrive punctually at your chosen slot!";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B49DF), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B49DF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ServiceHub Scheduling AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                          SizedBox(width: 5),
                          Text(
                            'Online • Live Availability Assistant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3B49DF) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isUser ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Prompt Chips
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B49DF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _sendMessage(suggestion),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ask about dates, slots or technician arrival...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B49DF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
