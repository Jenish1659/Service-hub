import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/booking_chat_service.dart';
import '../../../../core/services/phone_launcher_service.dart';

class PartnerChatScreen extends StatefulWidget {
  final String bookingId;
  final String? initialCustomerName;
  final String? initialCustomerPhone;
  final String? initialServiceName;

  const PartnerChatScreen({
    super.key,
    required this.bookingId,
    this.initialCustomerName,
    this.initialCustomerPhone,
    this.initialServiceName,
  });

  @override
  State<PartnerChatScreen> createState() => _PartnerChatScreenState();
}

class _PartnerChatScreenState extends State<PartnerChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color _primaryIndigo = Color(0xFF4F46E5);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  String _customerName = 'Customer';
  String _customerPhone = '';
  String _serviceName = 'Active Service';
  String _partnerName = 'Partner';
  String _partnerPhone = '';

  @override
  void initState() {
    super.initState();
    _customerName = widget.initialCustomerName ?? 'Customer';
    _customerPhone = widget.initialCustomerPhone ?? '';
    _serviceName = widget.initialServiceName ?? 'Active Service';
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    LiveBookingSyncService.instance.reloadAllFromDisk();
    final b = LiveBookingSyncService.instance.getBooking(widget.bookingId);
    if (b != null) {
      _applyBooking(b);
    } else {
      final all = LiveBookingSyncService.instance.getAllBookings();
      for (final item in all) {
        if ((item['booking_id'] ?? item['id'] ?? '').toString() == widget.bookingId) {
          _applyBooking(item);
          break;
        }
      }
    }
  }

  void _applyBooking(Map<String, dynamic> b) {
    setState(() {
      final cName = (b['customer_name'] ?? b['name'] ?? b['patient_name'] ?? '').toString().trim();
      if (cName.isNotEmpty) _customerName = cName;

      final cPhone = (b['customer_phone'] ?? b['phone'] ?? b['contact_phone'] ?? '').toString().trim();
      if (cPhone.isNotEmpty) _customerPhone = cPhone;

      final sName = (b['service_name'] ?? b['category_name'] ?? b['service_title'] ?? '').toString().trim();
      if (sName.isNotEmpty) _serviceName = sName;

      _partnerName = (b['partner_name'] ?? b['provider_name'] ?? 'Partner').toString().trim();
      _partnerPhone = (b['partner_phone'] ?? '').toString().trim();
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    BookingChatService.instance.closeChatStream(widget.bookingId);
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    BookingChatService.instance.sendMessage(
      bookingId: widget.bookingId,
      text: text,
      senderRole: 'partner',
      senderName: _partnerName,
      senderPhone: _partnerPhone,
    );

    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? rawTs) {
    if (rawTs == null || rawTs.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(rawTs).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return 'Just now';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_customerName);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: _primaryIndigo.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  color: _primaryIndigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _customerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '$_serviceName • Customer',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: _primaryIndigo),
            tooltip: 'Call Customer',
            onPressed: () {
              PhoneLauncherService.makePhoneCall(context, _customerPhone);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Live Message Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: BookingChatService.instance.streamMessages(widget.bookingId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? BookingChatService.instance.getCachedMessages(widget.bookingId);

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _primaryIndigo.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: _primaryIndigo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Direct Chat with $_customerName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Coordinate arrival specifics, location landmarks, or service access directly with the customer.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textMuted,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final msg = messages[index];
                    final isMe = (msg['sender_role'] ?? '').toString().toLowerCase() == 'partner';
                    final text = (msg['text'] ?? '').toString();
                    final timeStr = _formatTime(msg['timestamp'] ?? msg['created_at']);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? _primaryIndigo : const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                          ),
                          border: isMe ? null : Border.all(color: const Color(0xffe2e8f0)),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                _customerName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryIndigo,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : _textDark,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : const Color(0xff94a3b8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffe2e8f0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xfff8fafc),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: TextField(
                        controller: _msgController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type message for $_customerName...',
                          hintStyle: const TextStyle(color: Color(0xff94a3b8), fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
