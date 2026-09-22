import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperInfoScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperInfoScreen({super.key, this.controller});

  @override
  State<ShopkeeperInfoScreen> createState() => _ShopkeeperInfoScreenState();
}

class _ShopkeeperInfoScreenState extends State<ShopkeeperInfoScreen> {
  late final ShopkeeperProfileController _controller;
  bool _createdInternally = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ShopkeeperProfileController();
      _createdInternally = true;
      _controller.loadShopkeeperProfile();
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_createdInternally) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF047857);
    const emeraldDark = Color(0xFF065F46);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.pop();
            }
          },
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Information',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'View and manage your shop details',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: _controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: emeraldPrimary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Status Badge Card
                    () {
                      final bool isVerified = _controller.isVerified ||
                          (_controller.aadhaarNumber.trim().isNotEmpty &&
                              _controller.panNumber.trim().isNotEmpty &&
                              _controller.shopRegistrationNo.trim().isNotEmpty);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isVerified ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                color: isVerified ? emeraldPrimary : const Color(0xFFD97706),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isVerified ? 'Registered Merchant Partner' : 'Verification In Progress',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isVerified ? emeraldDark : const Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isVerified
                                        ? 'Your identity & legal documents are verified'
                                        : 'Upload required documents to complete verification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isVerified ? emeraldPrimary : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }(),
                    const SizedBox(height: 20),

                    // Read-only Details Cards
                    _buildInfoCard(
                      icon: Icons.storefront_rounded,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: emeraldPrimary,
                      label: 'Shop Name',
                      value: _controller.shopName.trim().isNotEmpty ? _controller.shopName.trim() : 'Not set',
                    ),
                    _buildInfoCard(
                      icon: Icons.category_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      label: 'Shop Type',
                      value: _controller.category.trim().isNotEmpty ? _controller.category.trim() : 'Not set',
                    ),
                    _buildInfoCard(
                      icon: Icons.receipt_long_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      label: 'GST Number',
                      value: _controller.gstNumber.trim().isNotEmpty ? _controller.gstNumber.trim() : 'Not Provided',
                      canCopy: _controller.gstNumber.trim().isNotEmpty,
                    ),
                    _buildInfoCard(
                      icon: Icons.badge_rounded,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      label: 'Shop Registration No.',
                      value: _controller.shopRegistrationNo.trim().isNotEmpty ? _controller.shopRegistrationNo.trim() : 'Not Provided',
                      canCopy: _controller.shopRegistrationNo.trim().isNotEmpty,
                    ),
                    _buildInfoCard(
                      icon: Icons.history_rounded,
                      iconBg: const Color(0xFFCCFBF1),
                      iconColor: const Color(0xFF0D9488),
                      label: 'Years in Business',
                      value: _controller.yearsInBusiness.trim().isNotEmpty ? _controller.yearsInBusiness.trim() : 'Not set',
                    ),
                    _buildInfoCard(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFE0E7FF),
                      iconColor: const Color(0xFF4F46E5),
                      label: 'Owner Name',
                      value: _controller.ownerName.trim().isNotEmpty ? _controller.ownerName.trim() : 'Not set',
                    ),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      label: 'Email',
                      value: _controller.email.trim().isNotEmpty ? _controller.email.trim() : 'Not set',
                      canCopy: _controller.email.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 28),

                    // Edit Information Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          context.push('/profile/shopkeeper/edit', extra: _controller);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: const Text(
                          'Edit Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () => _copyToClipboard(value, label),
              tooltip: 'Copy $label',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
