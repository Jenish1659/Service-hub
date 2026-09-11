import 'package:flutter/material.dart';

class AdminSupportView extends StatefulWidget {
  const AdminSupportView({super.key});

  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  final List<Map<String, dynamic>> _tickets = [];

  void _showTicketResolutionModal(Map<String, dynamic> ticket) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ticket #${ticket['id']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('${ticket['user']} (${ticket['role']}) • ${ticket['category']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Text('User Query:\n"${ticket['issue']}"', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 16),
              const Text('Admin Official Response:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: replyController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type resolution message to user...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Send & Resolve Ticket'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        ticket['status'] = 'RESOLVED';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ticket #${ticket['id']} marked as RESOLVED and response sent!'), backgroundColor: const Color(0xFF10B981)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Support & Grievance Desk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text('Live ticket monitoring, customer dispute resolution, partner inquiries, and SLA tracking', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_email_read_rounded, size: 52, color: Colors.blueGrey.shade200),
                          const SizedBox(height: 12),
                          const Text(
                            'No Support Tickets in Queue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Real user and partner tickets will appear here dynamically.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                itemCount: _tickets.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, idx) {
                  final t = _tickets[idx];
                  final isResolved = t['status'] == 'RESOLVED';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                      child: Icon(isResolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: isResolved ? const Color(0xFF059669) : const Color(0xFFD97706)),
                    ),
                    title: Row(
                      children: [
                        Text(t['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Text('• ${t['user']} (${t['role']})', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(t['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? const Color(0xFF059669) : const Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    subtitle: Text('"${t['issue']}"', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, elevation: 0),
                      onPressed: () => _showTicketResolutionModal(t),
                      child: const Text('Resolve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
