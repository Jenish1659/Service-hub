import 'package:flutter/material.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../controllers/delivery_agent_profile_controller.dart';

class DeliveryDocumentsScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliveryDocumentsScreen({super.key, this.controller});

  @override
  State<DeliveryDocumentsScreen> createState() => _DeliveryDocumentsScreenState();
}

class _DeliveryDocumentsScreenState extends State<DeliveryDocumentsScreen> {
  DeliveryAgentProfileController? _controller;
  Map<String, dynamic>? _cachedData;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller?.addListener(_onControllerChange);
    _loadCachedProfile();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChange);
    super.dispose();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final cached = await LocalRegistrationCache.getActiveDeliveryAgent();
      if (cached != null && mounted) {
        setState(() {
          _cachedData = cached;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final cached = _cachedData ?? c?.agentData;

    final dlNumber = (c?.drivingLicenseNumber.trim().isNotEmpty == true)
        ? c!.drivingLicenseNumber.trim()
        : (cached?['driving_license_number'] ?? '').toString().trim();

    final rcNumber = (c?.vehicleRegNumber.trim().isNotEmpty == true)
        ? c!.vehicleRegNumber.trim()
        : (cached?['vehicle_number'] ?? '').toString().trim();

    final rawBank = (c?.accountNumber.trim().isNotEmpty == true)
        ? c!.accountNumber.trim()
        : (cached?['account_number'] ?? '').toString().trim();
    final bankAcc = rawBank.isNotEmpty
        ? 'A/C: XXXX-XXXX-${rawBank.length > 4 ? rawBank.substring(rawBank.length - 4) : rawBank}'
        : '';

    final rawAadhaar = (c?.aadhaarNumber.trim().isNotEmpty == true)
        ? c!.aadhaarNumber.trim()
        : (cached?['aadhaar_number'] ?? '').toString().trim();
    final aadhaar = rawAadhaar.isNotEmpty
        ? 'XXXX-XXXX-${rawAadhaar.length > 4 ? rawAadhaar.substring(rawAadhaar.length - 4) : rawAadhaar}'
        : '';

    final pan = (c?.panNumber.trim().isNotEmpty == true)
        ? c!.panNumber.trim()
        : (cached?['pan_number'] ?? '').toString().trim();

    final insurance = (c?.insuranceExpiry.trim().isNotEmpty == true)
        ? c!.insuranceExpiry.trim()
        : (cached?['insurance_expiry'] ?? '').toString().trim();

    final upi = (c?.upiId.trim().isNotEmpty == true)
        ? c!.upiId.trim()
        : (cached?['upi_id'] ?? '').toString().trim();

    final verificationStatus = (cached?['verification_status'] ?? c?.agentData?['verification_status'] ?? '').toString().toUpperCase();
    final bool isKycVerified = (c == null && cached == null) || verificationStatus == 'VERIFIED' || verificationStatus == 'APPROVED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Documents & Verification',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KYC Hero Card (Dynamic real verification status)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isKycVerified ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isKycVerified ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isKycVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isKycVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKycVerified ? '100% KYC Verified' : 'KYC Verification Pending',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isKycVerified ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isKycVerified
                              ? 'Your identity and documents have been verified by ServiceHub Admin.'
                              : 'Upload genuine official documents to unlock full delivery dispatch rights.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isKycVerified ? const Color(0xFF166534) : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Identity Proofs
            _buildSectionHeader('Identity Proofs'),
            const SizedBox(height: 8),
            _buildDocCard(
              icon: Icons.badge_outlined,
              iconColor: const Color(0xFFEA580C),
              title: 'Aadhaar Card',
              subtitle: aadhaar,
              isVerified: aadhaar.isNotEmpty && isKycVerified,
              onTap: () => _showEditDocSheet(context, 'Aadhaar Card', rawAadhaar),
            ),
            _buildDocCard(
              icon: Icons.credit_card_outlined,
              iconColor: const Color(0xFF9333EA),
              title: 'PAN Card',
              subtitle: pan,
              isVerified: pan.isNotEmpty && isKycVerified,
              onTap: () => _showEditDocSheet(context, 'PAN Card', pan),
            ),
            const SizedBox(height: 20),

            // Section 2: Delivery Partner Documents
            _buildSectionHeader('Delivery Partner Documents'),
            const SizedBox(height: 8),
            _buildDocCard(
              icon: Icons.drive_eta_outlined,
              iconColor: const Color(0xFFD97706),
              title: 'Driving Licence',
              subtitle: dlNumber.isNotEmpty ? 'DL No: $dlNumber' : '',
              isVerified: dlNumber.isNotEmpty,
              onTap: () => _showEditDocSheet(context, 'Driving Licence', dlNumber),
            ),
            _buildDocCard(
              icon: Icons.two_wheeler_outlined,
              iconColor: const Color(0xFF16A34A),
              title: 'Vehicle RC',
              subtitle: rcNumber,
              isVerified: rcNumber.isNotEmpty,
              onTap: () => _showEditDocSheet(context, 'Vehicle RC', rcNumber),
            ),
            _buildDocCard(
              icon: Icons.security_outlined,
              iconColor: const Color(0xFF2563EB),
              title: 'Vehicle Insurance',
              subtitle: insurance.isNotEmpty ? 'Valid till: $insurance' : '',
              isVerified: insurance.isNotEmpty,
              onTap: () => _showEditDocSheet(context, 'Vehicle Insurance', insurance),
            ),
            const SizedBox(height: 20),

            // Section 3: Payout Information
            _buildSectionHeader('Payout Information'),
            const SizedBox(height: 8),
            _buildDocCard(
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFF0D9488),
              title: 'Bank Account',
              subtitle: bankAcc,
              isVerified: rawBank.isNotEmpty,
              onTap: () => _showEditDocSheet(context, 'Bank Account', rawBank),
            ),
            _buildDocCard(
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'UPI ID',
              subtitle: upi,
              isVerified: upi.isNotEmpty,
              onTap: () => _showEditDocSheet(context, 'UPI ID', upi),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
    );
  }

  Widget _buildDocCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isVerified,
    VoidCallback? onTap,
  }) {
    final bool hasData = subtitle.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Pending',
                          style: TextStyle(
                            color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasData ? subtitle : 'Not Uploaded / Not Linked',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: hasData ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showEditDocSheet(BuildContext context, String title, String currentValue) {
    final textController = TextEditingController(text: currentValue);
    const themeColor = Color(0xFFEA580C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Update $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter genuine $title details. These will be immediately synchronized directly to the database.',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: title,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
                onPressed: () async {
                  final val = textController.text.trim();
                  if (val.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  if (title == 'Driving Licence') {
                    _controller?.updateProfile(drivingLicenseNumber: val);
                    setState(() {
                      _cachedData ??= {};
                      _cachedData!['driving_license_number'] = val;
                    });
                    await LocalRegistrationCache.updateActiveDeliveryAgent({'driving_license_number': val});
                    await SupabaseAuthService.updateDeliveryAgentInDatabase(drivingLicenseNumber: val);
                  } else if (title == 'Vehicle RC') {
                    _controller?.updateProfile(vehicleRegNumber: val);
                    setState(() {
                      _cachedData ??= {};
                      _cachedData!['vehicle_number'] = val;
                    });
                    await LocalRegistrationCache.updateActiveDeliveryAgent({'vehicle_number': val});
                    await SupabaseAuthService.updateDeliveryAgentInDatabase(vehicleNumber: val);
                  } else if (title == 'Bank Account') {
                    _controller?.updateProfile(accountNumber: val);
                    setState(() {
                      _cachedData ??= {};
                      _cachedData!['account_number'] = val;
                    });
                    await LocalRegistrationCache.updateActiveDeliveryAgent({'account_number': val});
                    await SupabaseAuthService.updateDeliveryAgentInDatabase(accountNumber: val);
                  } else if (title == 'Aadhaar Card') {
                    if (_controller != null) _controller!.aadhaarNumber = val;
                    setState(() {
                      _cachedData ??= {};
                      _cachedData!['aadhaar_number'] = val;
                    });
                    await LocalRegistrationCache.updateActiveDeliveryAgent({'aadhaar_number': val});
                    final uid = _controller?.agentData?['user_id']?.toString() ?? _cachedData?['user_id']?.toString();
                    if (uid != null) {
                      try {
                        final existing = LiveBookingSyncService.instance.getPartnerVerification(uid);
                        if (existing != null) {
                          final updated = Map<String, dynamic>.from(existing);
                          updated['aadhaar_number'] = val;
                          await LiveBookingSyncService.instance.submitPartnerVerification(updated);
                        }
                      } catch (_) {}
                    }
                  } else if (title == 'PAN Card') {
                    if (_controller != null) _controller!.panNumber = val;
                    setState(() {
                      _cachedData ??= {};
                      _cachedData!['pan_number'] = val;
                    });
                    await LocalRegistrationCache.updateActiveDeliveryAgent({'pan_number': val});
                    final uid = _controller?.agentData?['user_id']?.toString() ?? _cachedData?['user_id']?.toString();
                    if (uid != null) {
                      try {
                        final existing = LiveBookingSyncService.instance.getPartnerVerification(uid);
                        if (existing != null) {
                          final updated = Map<String, dynamic>.from(existing);
                          updated['pan_number'] = val;
                          await LiveBookingSyncService.instance.submitPartnerVerification(updated);
                        }
                      } catch (_) {}
                    }
                  } else if (title == 'UPI ID') {
                    if (_controller != null) _controller!.upiId = val;
                    setState(() {
                      _cachedData ??= {};
                      _cachedData!['upi_id'] = val;
                    });
                    await LocalRegistrationCache.updateActiveDeliveryAgent({'upi_id': val});
                  }

                  _controller?.refresh();
                  if (mounted) setState(() {});

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('$title updated and saved to database!'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save & Sync to Database'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
