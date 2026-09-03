import 'package:flutter/material.dart';

class AdminFinanceView extends StatelessWidget {
  final double totalRevenue;
  final Function(String id, String type, String name) onSettlePayout;

  const AdminFinanceView({super.key, required this.totalRevenue, required this.onSettlePayout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Finance, Payouts & Commission Settlements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Direct IMPS bank settlements, partner payout approvals, and commission ledgers', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text('Total Gross Revenue: ₹${totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView(
                children: [
                  _buildPayoutRow('PAY-101', 'Ravi Technician', 'HDFC Bank (A/C: **5489)', '₹18,540.00', '10% (₹1,854)', '₹16,686.00', false),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildPayoutRow('PAY-102', 'CoolFix Experts', 'SBI (A/C: **1290)', '₹15,320.00', '10% (₹1,532)', '₹13,788.00', false),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildPayoutRow('PAY-103', 'AC Master Service', 'ICICI Bank (A/C: **7741)', '₹13,860.00', '10% (₹1,386)', '₹12,474.00', true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutRow(String id, String partner, String bank, String gross, String comm, String net, bool isPaid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12))),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(bank, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(gross, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
          Expanded(flex: 2, child: Text(comm, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
          Expanded(flex: 2, child: Text(net, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid ? const Color(0xFFF1F5F9) : const Color(0xFF10B981),
              foregroundColor: isPaid ? const Color(0xFF64748B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isPaid ? null : () => onSettlePayout(id, 'PROVIDER', partner),
            child: Text(isPaid ? 'Settled ✓' : 'Instant Payout', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
