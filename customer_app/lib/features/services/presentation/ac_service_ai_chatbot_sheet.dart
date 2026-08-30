import 'package:flutter/material.dart';

class ACServiceAIChatbotSheet extends StatefulWidget {
  const ACServiceAIChatbotSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ACServiceAIChatbotSheet(),
    );
  }

  @override
  State<ACServiceAIChatbotSheet> createState() => _ACServiceAIChatbotSheetState();
}

class _ACServiceAIChatbotSheetState extends State<ACServiceAIChatbotSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          "Hello! 👋 I'm your ServiceHub AC AI Assistant.\n\nI can help you select your AC type, identify your brand, accurately describe any cooling or leakage issues, and advise which photos to upload. How can I assist you with this booking?",
      'time': 'Just now',
    },
  ];

  final List<String> _quickSuggestions = [
    'How do I identify my AC type?',
    'My AC is not cooling, what to write?',
    'What photos should I upload?',
    'What if my brand is not in the list?',
    'Water is leaking from indoor unit',
    'AC is making a strange noise',
  ];

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

    // AI Response Generator tailored specifically for AC Service
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

    if (lower.contains('type') || lower.contains('split') || lower.contains('window') || lower.contains('cassette')) {
      return "Here is a quick guide to AC Types:\n\n• Split AC: Has two parts—a sleek indoor unit mounted on the wall and an outdoor condenser unit.\n• Window AC: A single standalone unit fitted into a window frame or wall cavity.\n• Cassette AC: Square indoor unit embedded flush into the ceiling.\n• Tower/Portable AC: Floor-standing movable unit.\n\nSelect 'Split AC' if your indoor unit is on the wall with pipes going to an outdoor unit!";
    }

    if (lower.contains('cool') || lower.contains('not cooling') || lower.contains('blowing normal air')) {
      return "For cooling problems, you can write:\n\n\"The AC turns on and the fan works, but it only blows normal air instead of cold air. Cooling dropped suddenly over the last few days.\"\n\nTip: Mention whether the outdoor unit fan is spinning or if any error code (like E1, EC) appears on the display.";
    }

    if (lower.contains('photo') || lower.contains('image') || lower.contains('camera')) {
      return "Here are the most helpful photos you can upload (up to 5):\n\n1. Front view of the indoor unit (showing the brand logo & display).\n2. Any error code visible on the digital temperature display.\n3. The exact spot of water leakage or ice buildup on the coils.\n4. The outdoor unit (if safely accessible).\n\nClear photos help our technician arrive with the exact spare parts!";
    }

    if (lower.contains('leak') || lower.contains('water')) {
      return "For water leakage, you can describe:\n\n\"Water is dripping from the right/left corner of the indoor unit onto the wall/floor while running. Seems like a choked drain pipe or frozen coil.\"\n\nUploading a photo of the dripping spot will be very helpful!";
    }

    if (lower.contains('noise') || lower.contains('sound') || lower.contains('vibrat')) {
      return "For noise issues, you can describe:\n\n\"There is a loud buzzing / rattling / whistling sound coming from the indoor/outdoor unit when the compressor kicks in.\"\n\nPlease mention if the noise is continuous or only happens at startup.";
    }

    if (lower.contains('brand') || lower.contains('company') || lower.contains('not listed') || lower.contains('not in the list')) {
      return "If your AC brand (e.g., imported or local brand) is not listed in the searchable dropdown, simply choose 'Other' from the list and mention your brand name inside the problem description!";
    }

    if (lower.contains('age') || lower.contains('old') || lower.contains('year')) {
      return "For AC Age, an approximate estimate is sufficient:\n\n• Less than 1 year (New / under warranty)\n• 1–2 years\n• 3–5 years\n• 6–10 years\n• More than 10 years\n• Not sure (Choose this if you don't know the exact year)";
    }

    return "Thank you for asking! For your AC Service request, make sure to:\n1. Choose your AC Type (e.g. Split or Window)\n2. Select your AC Brand\n3. Describe what happens (cooling, sound, leakage, odor)\n4. Upload 1 to 5 clear photos\n5. Select approximate AC Age\n\nOur verified certified technician will inspect and service your unit thoroughly.";
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
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ServiceHub AC Assistant',
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
                            'Online • AI AC Booking Specialist',
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
                        hintText: 'Ask any question about your AC problem...',
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
