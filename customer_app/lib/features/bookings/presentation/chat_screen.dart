import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/booking_chat_service.dart';
import '../../../../core/services/phone_launcher_service.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  const ChatScreen({super.key, required this.bookingId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _partnerName = '';
  String _partnerPhone = '';
  String _partnerCategory = '';
  String _customerName = 'Customer';
  String _customerPhone = '';

  @override
  void initState() {
    super.initState();
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
      _partnerName = (b['partner_name'] ?? b['provider_name'] ?? b['specialist_name'] ?? '').toString().trim();
      if (_partnerName.isEmpty) {
        _partnerName = 'Assigned Specialist';
      }
      _partnerPhone = (b['partner_phone'] ?? b['provider_phone'] ?? b['specialist_phone'] ?? '').toString().trim();
      _partnerCategory = (b['category_name'] ?? b['service_name'] ?? b['category'] ?? 'Service Specialist').toString().trim();
      _customerName = (b['customer_name'] ?? 'Customer').toString().trim();
      _customerPhone = (b['customer_phone'] ?? '').toString().trim();
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
      senderRole: 'customer',
      senderName: _customerName,
      senderPhone: _customerPhone,
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
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _partnerName.isNotEmpty ? _partnerName : 'Assigned Specialist';
    final initials = _getInitials(displayName);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/orders');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/orders');
              }
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
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
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
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
                            '$_partnerCategory • Active Booking',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
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
              icon: const Icon(Icons.phone_rounded, color: AppTheme.primaryColor),
              tooltip: 'Call Assigned Specialist',
              onPressed: () {
                PhoneLauncherService.makePhoneCall(context, _partnerPhone);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Live Real-Time Message Stream
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
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 36,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Direct Chat with $displayName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Send a message to coordinate service specifics, entrance directions, or timing directly.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
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
                      final isMe = (msg['sender_role'] ?? '').toString().toLowerCase() == 'customer';
                      final text = (msg['text'] ?? '').toString();
                      final timeStr = _formatTime(msg['timestamp'] ?? msg['created_at']);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primaryColor : const Color(0xfff1f5f9),
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
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : AppTheme.textPrimaryColor,
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
                border: Border(top: BorderSide(color: AppTheme.borderCol)),
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
                            hintText: 'Type message for $displayName...',
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
                        backgroundColor: AppTheme.primaryColor,
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
      ),
    );
  }
}
