import 'package:flutter/material.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperDocumentsScreen extends StatelessWidget {
  final ShopkeeperProfileController controller;

  const ShopkeeperDocumentsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const emeraldColor = Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Store Documents & KYC',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: emeraldColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Store Verification Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46))),
                        const SizedBox(height: 2),
                        Text(
                          'Your business license and identity documents are verified by Admin.',
                          style: TextStyle(fontSize: 11.5, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'REGISTERED STORE DOCUMENTS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            _buildDocCard(
              title: 'Shop & Establishment License',
              sub: 'License No: ${controller.shopLicenseNumber}',
              status: 'VERIFIED',
              icon: Icons.store_mall_directory_rounded,
              color: emeraldColor,
            ),
            _buildDocCard(
              title: 'Owner Aadhaar Card',
              sub: 'UID: ${controller.aadhaarNumber}',
              status: 'VERIFIED',
              icon: Icons.credit_card_rounded,
              color: const Color(0xFF2563EB),
            ),
            _buildDocCard(
              title: 'Business PAN Card',
              sub: 'PAN: ${controller.panNumber}',
              status: 'VERIFIED',
              icon: Icons.badge_rounded,
              color: const Color(0xFFD97706),
            ),
            _buildDocCard(
              title: 'Storefront & Premises Photo',
              sub: 'Physical verification photo submitted during registration',
              status: 'VERIFIED',
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFF9333EA),
            ),
            _buildDocCard(
              title: 'Settlement Bank Account',
              sub: '${controller.bankName} • Acc: ${controller.accountNumber} (IFSC: ${controller.ifscCode})',
              status: 'ACTIVE',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF0D9488),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required String sub,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(sub, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                const SizedBox(width: 4),
                Text(status, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
