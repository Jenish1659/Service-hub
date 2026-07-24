import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  // Chat History
  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Hello! I am your ServiceHub AI Assistant. How can I help you today with your orders, services, or delivery details?'
    }
  ];

  // Tickets State
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoadingTickets = true;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // AI Chat Bot response logic
  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });
    _chatInputController.clear();
    _scrollToBottom();

    // Simulate AI response delay
    Timer(const Duration(milliseconds: 600), () {
      final responseText = _getAiResponse(text);
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': responseText});
        });
        _scrollToBottom();
      }
    });
  }

  String _getAiResponse(String query) {
    final cleanQuery = query.toLowerCase();
    if (cleanQuery.contains('geofence') || cleanQuery.contains('radius') || cleanQuery.contains('km') || cleanQuery.contains('distance')) {
      return 'ServiceHub strictly enforces a 5 km geofence radius from the provider or seller\'s location. This ensures rapid hyperlocal delivery and high service quality.';
    }
    if (cleanQuery.contains('pin') || cleanQuery.contains('verification') || cleanQuery.contains('delivery pin')) {
      return 'All orders require a secure Delivery PIN to be completed. You can find this 4-digit PIN (e.g. 2842) on your Order Track screen. Please share it with your delivery agent only when they arrive with your package!';
    }
    if (cleanQuery.contains('otp') || cleanQuery.contains('service code') || cleanQuery.contains('entrance')) {
      return 'Service bookings use a 2-stage verification system: an Entrance PIN (7429) when the provider arrives at your home, and a Completion OTP (5892) once the service is successfully finished.';
    }
    if (cleanQuery.contains('payment') || cleanQuery.contains('refund') || cleanQuery.contains('charge')) {
      return 'Payments are processed securely via our gateway. For cancellations, refunds are automatically processed back to your original payment method within 3-5 business days.';
    }
    if (cleanQuery.contains('hello') || cleanQuery.contains('hi') || cleanQuery.contains('hey')) {
      return 'Hello there! How can I help you today? You can ask me about delivery zones, verification PINs, service OTPs, or how to submit a support ticket!';
    }
    return 'I hear you! If you have a specific issue or need help from our support team, please click on the "Submit Ticket" tab to open a official ticket. Our admins will resolve it immediately.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Supabase Support Tickets fetching logic
  Future<void> _fetchTickets() async {
    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('tickets')
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tickets = List<Map<String, dynamic>>.from(response);
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  // Create Support Ticket
  Future<void> _createTicket() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('tickets').insert({
        'customer_id': user.id,
        'subject': subject,
        'description': description,
        'status': 'Open',
      });

      _subjectController.clear();
      _descriptionController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _fetchTickets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ticket: ${e.toString()}')),
        );
      }
    }
  }

  void _showCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Support Ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Broken packaging or late delivery',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide details about your query or issue...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createTicket,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & AI Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'AI Chatbot'),
            Tab(icon: Icon(Icons.support_agent), text: 'Support Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: AI CHATBOT SCREEN
          _buildChatTab(),

          // TAB 2: SUPPORT TICKETS LIST
          _buildTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Chat Message List
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isAi = msg['sender'] == 'ai';

              return Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isAi ? const Color(0xfff1f5f9) : AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isAi ? Radius.zero : const Radius.circular(16),
                      bottomRight: isAi ? const Radius.circular(16) : Radius.zero,
                    ),
                  ),
                  child: Text(
                    msg['text']!,
                    style: TextStyle(
                      color: isAi ? AppTheme.textPrimaryColor : Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick FAQ Suggestions Chips
        Container(
          height: 48,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildSuggestionChip('What is the geofence radius?'),
              _buildSuggestionChip('How does PIN verification work?'),
              _buildSuggestionChip('Where is my service OTP?'),
              _buildSuggestionChip('How do I submit a ticket?'),
            ],
          ),
        ),

        // Chat Input Panel
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInputController,
                  onSubmitted: _sendChatMessage,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendChatMessage(_chatInputController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
        backgroundColor: const Color(0xffeff6ff),
        side: BorderSide(color: Colors.blue.shade100),
        onPressed: () => _sendChatMessage(label),
      ),
    );
  }

  Widget _buildTicketsTab() {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Submit New Ticket Banner Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Submit Support Ticket'),
              onPressed: _showCreateTicketSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Tickets List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTickets,
            child: _tickets.isEmpty
                ? const Center(
                    child: Text(
                      'No support tickets submitted yet.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      final status = ticket['status'] ?? 'Open';
                      final isClosed = status == 'Resolved';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            ticket['subject'] ?? 'Untitled Ticket',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                'Status: ',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isClosed ? const Color(0xfff0fdf4) : const Color(0xfffffbeb),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: isClosed ? AppTheme.successColor : const Color(0xffd97706),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ticket['description'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ticket ID: ${ticket['id']}',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
