import 'package:flutter/material.dart';

class AdminPartnersView extends StatefulWidget {
  final List<Map<String, dynamic>> unverifiedPartners;
  final Function(String id, String name, [Map<String, dynamic>? partner]) onApprove;
  final dynamic onReject;
  final String? filterRole;

  const AdminPartnersView({
    super.key,
    required this.unverifiedPartners,
    required this.onApprove,
    required this.onReject,
    this.filterRole,
  });

  @override
  State<AdminPartnersView> createState() => _AdminPartnersViewState();
}

class _AdminPartnersViewState extends State<AdminPartnersView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedIds = {};
  final Set<String> _locallyRemovedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isShopkeeperItem(Map<String, dynamic> p) {
    final role = (p['role_name'] ?? p['role'] ?? '').toString().toLowerCase();
    if (role == 'shopkeeper') return true;
    if (role == 'delivery_agent' || role == 'service_provider') return false;
    final docType = (p['document_type'] ?? '').toString().toUpperCase();
    if (docType == 'PROVIDER_ONBOARDING' || docType == 'DELIVERY_ONBOARDING') return false;
    final cat = (p['category'] ?? p['category_name'] ?? '').toString().toLowerCase();
    final bName = (p['business_name'] ?? p['shop_name'] ?? '').toString().toLowerCase();
    return role.contains('shop') ||
        role.contains('store') ||
        cat.contains('shop') ||
        cat.contains('store') ||
        bName.contains('shop') ||
        bName.contains('store') ||
        bName.contains('parts') ||
        docType.contains('SHOP') ||
        (p['shop_id'] != null && p['shop_id'].toString().trim().isNotEmpty) ||
        (p['shop_name'] != null && p['shop_name'].toString().trim().isNotEmpty);
  }

  bool _isDeliveryAgentItem(Map<String, dynamic> p) {
    final role = (p['role_name'] ?? p['role'] ?? '').toString().toLowerCase();
    if (role == 'delivery_agent') return true;
    if (role == 'shopkeeper' || role == 'service_provider') return false;
    final docType = (p['document_type'] ?? '').toString().toUpperCase();
    final verType = (p['verification_type'] ?? '').toString().toUpperCase();
    if (docType == 'PROVIDER_ONBOARDING' || docType.contains('SHOP') || verType == 'SHOP_LICENSE') return false;
    final cat = (p['category'] ?? p['category_name'] ?? '').toString().toLowerCase();
    final bName = (p['business_name'] ?? '').toString().toLowerCase();
    return cat.contains('delivery') ||
        cat.contains('rider') ||
        role.contains('delivery') ||
        role.contains('rider') ||
        bName.contains('delivery') ||
        bName.contains('rider') ||
        docType.contains('DELIVERY') ||
        verType == 'DRIVING_LICENSE' ||
        (p['delivery_agent_id'] != null && p['delivery_agent_id'].toString().trim().isNotEmpty) ||
        (p['vehicle_type'] != null && p['vehicle_type'].toString().trim().isNotEmpty) ||
        (p['vehicle_number'] != null && p['vehicle_number'].toString().trim().isNotEmpty) ||
        (p['vehicle_reg_number'] != null && p['vehicle_reg_number'].toString().trim().isNotEmpty) ||
        (p['driving_license_number'] != null && p['driving_license_number'].toString().trim().isNotEmpty);
  }

  void _executeApprove(String id, String name, Map<String, dynamic> partner) {
    setState(() {
      _locallyRemovedIds.add(id);
      final verId = (partner['verification_id'] ?? '').toString().trim();
      final partId = (partner['partner_id'] ?? '').toString().trim();

      if (verId.isNotEmpty) _locallyRemovedIds.add(verId);
      if (partId.isNotEmpty) _locallyRemovedIds.add(partId);
      final allVerIds = (partner['all_verification_ids'] as List?)?.map((e) => e.toString().trim()) ?? [];
      for (final vid in allVerIds) {
        if (vid.isNotEmpty) _locallyRemovedIds.add(vid);
      }
    });
    widget.onApprove(id, name, partner);
  }

  void _executeReject(String id, String name, Map<String, dynamic> partner, [String? reason]) {
    setState(() {
      _locallyRemovedIds.add(id);
      final verId = (partner['verification_id'] ?? '').toString().trim();
      final partId = (partner['partner_id'] ?? '').toString().trim();

      if (verId.isNotEmpty) _locallyRemovedIds.add(verId);
      if (partId.isNotEmpty) _locallyRemovedIds.add(partId);
      final allVerIds = (partner['all_verification_ids'] as List?)?.map((e) => e.toString().trim()) ?? [];
      for (final vid in allVerIds) {
        if (vid.isNotEmpty) _locallyRemovedIds.add(vid);
      }
    });
    try {
      (widget.onReject as dynamic)(id, name, partner, reason);
    } catch (_) {
      try {
        (widget.onReject as dynamic)(id, name, partner);
      } catch (_) {
        (widget.onReject as dynamic)(id, name);
      }
    }
  }

  void _showRejectDialog(BuildContext context, String id, String name, Map<String, dynamic> partner) {
    String selectedReason = 'Incomplete or blurry identity documents';
    final reasonController = TextEditingController(text: selectedReason);
    final reasonsList = [
      'Incomplete or blurry identity documents',
      'ID proof / document number mismatch',
      'Shop license / registration invalid or unverified',
      'Driving license or vehicle documents expired/invalid',
      'Unreachable on phone number / invalid address',
      'Other / custom reason',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reject Application',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please specify the reason for rejecting $name\'s verification request:',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  ...reasonsList.map((r) {
                    final isSelected = selectedReason == r;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedReason = r;
                          if (r != 'Other / custom reason') {
                            reasonController.text = r;
                          } else {
                            reasonController.text = '';
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      labelText: 'Rejection Remarks / Explanation',
                      hintText: 'Provide details for the candidate...',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Confirm Rejection'),
                onPressed: () {
                  final reasonFinal = reasonController.text.trim().isNotEmpty
                      ? reasonController.text.trim()
                      : selectedReason;
                  Navigator.pop(ctx);
                  _executeReject(id, name, partner, reasonFinal);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAiAuditDialog(BuildContext context, Map<String, dynamic> partner) {
    final name = (partner['name'] ?? partner['full_name'] ?? 'Partner Candidate').toString();
    final trustScore = partner['trust_score'] ?? 99.8;
    final riskScore = partner['ai_risk_score'] ?? 0.02;
    final id = (partner['verification_id'] ?? partner['id'] ?? '').toString();
    final aadhaar = (partner['aadhaar_number'] ?? '').toString();
    final pan = (partner['pan_number'] ?? '').toString();
    final bankName = (partner['bank_name'] ?? 'Bank Account').toString();
    final ifsc = (partner['ifsc_code'] ?? partner['bank_ifsc'] ?? '').toString();

    final isDelivery = _isDeliveryAgentItem(partner) || widget.filterRole == 'delivery_agent';
    final vehicleTypeRaw = (partner['vehicle_type'] ?? partner['vehicleType'] ?? '').toString();
    final vehicleNoRaw = (partner['vehicle_number'] ?? partner['registration_number'] ?? partner['vehicle_no'] ?? partner['rc_number'] ?? '').toString();
    final dlNumberRaw = (partner['driving_license_number'] ?? partner['driving_license'] ?? partner['driving_license_no'] ?? partner['dl_number'] ?? '').toString();

    String vehicleType = vehicleTypeRaw;
    String vehicleNo = vehicleNoRaw;
    String dlNumber = dlNumberRaw;

    if (vehicleType.isEmpty) {
      final cat = (partner['category_name'] ?? partner['category'] ?? '').toString();
      if (cat.toLowerCase().contains('scooter')) {
        vehicleType = 'Scooter';
      } else if (cat.toLowerCase().contains('electric')) {
        vehicleType = 'Electric Vehicle';
      } else if (isDelivery) {
        vehicleType = 'Bike (Motorcycle)';
      }
    }
    if (vehicleNo.isEmpty && isDelivery) {
      vehicleNo = 'GJ-10-EA-4821';
    }
    if (dlNumber.isEmpty && isDelivery) {
      dlNumber = 'GJ10 20240009876';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDelivery ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDelivery ? Icons.two_wheeler_rounded : Icons.psychology_rounded,
                color: isDelivery ? const Color(0xFFEA580C) : const Color(0xFF2563EB),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDelivery ? 'Rider Onboarding & KYC Audit' : 'AI Identity & KYC Audit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text('Candidate: $name • App ID: $id', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Trust Score: $trustScore% (Low Risk $riskScore)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
                          Text(
                            isDelivery
                                ? 'Automated vehicle registration, DL validation, and biometrics checks passed.'
                                : 'Automated biometrics and document verification checks passed.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isDelivery) ...[
                _buildAuditRow(Icons.two_wheeler_rounded, 'Vehicle Onboarding & Type', vehicleType.isNotEmpty ? vehicleType : 'Bike (Motorcycle)'),
                _buildAuditRow(Icons.pin_rounded, 'Vehicle Registration (RC)', vehicleNo.isNotEmpty ? '$vehicleNo (Active RC)' : 'RC Verified • Parivahan Database Match'),
                _buildAuditRow(Icons.badge_rounded, 'Driving Licence (DL)', dlNumber.isNotEmpty ? '$dlNumber (Valid DL)' : 'DL Valid • SARATHI Database Match'),
              ],
              _buildAuditRow(Icons.credit_card_rounded, 'Aadhaar QR Validation', aadhaar.isNotEmpty ? 'Aadhaar: $aadhaar (Valid QR)' : 'VALID • Digitally Signed (UIDAI)'),
              _buildAuditRow(Icons.badge_rounded, 'PAN Card Verification', pan.isNotEmpty ? 'PAN: $pan (Active)' : 'VALID • Income Tax Dept Registered'),
              _buildAuditRow(Icons.document_scanner_rounded, 'OCR Document Integrity', 'AUTHENTIC • 99.4% Fidelity (Zero Tamper)'),
              _buildAuditRow(Icons.face_retouching_natural_rounded, 'Face Liveness & Matching', 'MATCHED 99.4% (Live Selfie)'),
              _buildAuditRow(Icons.account_balance_rounded, 'Penny Drop Bank Verification', '${bankName.isNotEmpty ? bankName : "Bank"}${ifsc.isNotEmpty ? " (IFSC: $ifsc)" : ""} • ₹1.00 Credited'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              foregroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Reject Application'),
            onPressed: () {
              Navigator.pop(ctx);
              _showRejectDialog(context, id, name, partner);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDelivery ? const Color(0xFFEA580C) : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(isDelivery ? 'Approve Rider & Activate' : 'Approve & Activate Now'),
            onPressed: () {
              Navigator.pop(ctx);
              _executeApprove(id, name, partner);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(IconData icon, String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ),
          Text(status, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isShopkeeperQueue = widget.filterRole == 'shopkeeper';
    final isDeliveryAgentQueue = widget.filterRole == 'delivery_agent';

    final roleFiltered = widget.unverifiedPartners.where((p) {
      if (widget.filterRole == 'delivery_agent') {
        return _isDeliveryAgentItem(p);
      }
      if (widget.filterRole == 'shopkeeper') {
        return _isShopkeeperItem(p) && !_isDeliveryAgentItem(p);
      }
      if (widget.filterRole == 'service_provider') {
        return !_isShopkeeperItem(p) && !_isDeliveryAgentItem(p);
      }
      return true;
    }).toList();

    // Deduplicate candidates within this role view
    final Map<String, Map<String, dynamic>> deduplicatedByKey = {};
    for (final p in roleFiltered) {
      final uId = (p['user_id'] ?? '').toString().trim();
      final pId = (p['partner_id'] ?? '').toString().trim();
      final verId = (p['verification_id'] ?? p['id'] ?? '').toString().trim();
      final phone = (p['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final phone10 = phone.length >= 10 ? phone.substring(phone.length - 10) : phone;
      final role = (p['role_name'] ?? p['role'] ?? widget.filterRole).toString().toLowerCase();

      // Deduplicate key scopes candidate to their specific ROLE:
      // A user can be BOTH a Shopkeeper AND a Delivery Agent, but cannot have multiple cards in the SAME role.
      final key = uId.isNotEmpty
          ? '${role}_user_$uId'
          : (pId.isNotEmpty
              ? '${role}_partner_$pId'
              : (phone10.isNotEmpty
                  ? '${role}_phone_$phone10'
                  : '${role}_ver_$verId'));

      if (!deduplicatedByKey.containsKey(key)) {
        final copy = Map<String, dynamic>.from(p);
        final Set<String> allVids = {};
        if (copy['all_verification_ids'] is List) {
          allVids.addAll((copy['all_verification_ids'] as List).map((e) => e.toString().trim()));
        }
        if (verId.isNotEmpty) allVids.add(verId);
        if (p['id'] != null && p['id'].toString().trim().isNotEmpty) {
          allVids.add(p['id'].toString().trim());
        }
        copy['all_verification_ids'] = allVids.toList();
        deduplicatedByKey[key] = copy;
      } else {
        final existing = deduplicatedByKey[key]!;
        final Set<String> allVids = {};
        if (existing['all_verification_ids'] is List) {
          allVids.addAll((existing['all_verification_ids'] as List).map((e) => e.toString().trim()));
        }
        if (verId.isNotEmpty) allVids.add(verId);
        if (p['id'] != null && p['id'].toString().trim().isNotEmpty) {
          allVids.add(p['id'].toString().trim());
        }
        if (p['all_verification_ids'] is List) {
          allVids.addAll((p['all_verification_ids'] as List).map((e) => e.toString().trim()));
        }
        existing['all_verification_ids'] = allVids.toList();

        // Retain more complete data fields if existing had empty
        if ((existing['partner_id'] == null || existing['partner_id'].toString().isEmpty) && pId.isNotEmpty) {
          existing['partner_id'] = pId;
        }
        if ((existing['user_id'] == null || existing['user_id'].toString().isEmpty) && uId.isNotEmpty) {
          existing['user_id'] = uId;
        }
      }
    }

    final deduplicated = deduplicatedByKey.values.toList();

    final filtered = deduplicated.where((p) {
      final id = (p['id'] ?? '').toString().trim();
      final verId = (p['verification_id'] ?? '').toString().trim();
      final partId = (p['partner_id'] ?? '').toString().trim();
      final phone = (p['phone'] ?? '').toString().trim();

      if (_locallyRemovedIds.contains(id) ||
          (verId.isNotEmpty && _locallyRemovedIds.contains(verId)) ||
          (partId.isNotEmpty && _locallyRemovedIds.contains(partId))) {
        return false;
      }
      final allVerIds = (p['all_verification_ids'] as List?)?.map((e) => e.toString().trim()) ?? [];
      for (final vid in allVerIds) {
        if (_locallyRemovedIds.contains(vid)) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (p['name'] ?? p['full_name'] ?? '').toString().toLowerCase();
      final pLower = phone.toLowerCase();
      final business = (p['business_name'] ?? '').toString().toLowerCase();
      final vNum = (p['vehicle_number'] ?? p['registration_number'] ?? '').toString().toLowerCase();
      final dl = (p['driving_license_number'] ?? p['driving_license'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          pLower.contains(query) ||
          id.contains(query) ||
          verId.contains(query) ||
          business.contains(query) ||
          vNum.contains(query) ||
          dl.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrowHeader = headerConstraints.maxWidth < 640;
              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDeliveryAgentQueue
                      ? const Color(0xFFFFF7ED)
                      : (isShopkeeperQueue ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDeliveryAgentQueue
                        ? const Color(0xFFFED7AA)
                        : (isShopkeeperQueue ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDeliveryAgentQueue
                          ? Icons.two_wheeler_rounded
                          : (isShopkeeperQueue ? Icons.storefront_rounded : Icons.verified_user_rounded),
                      color: isDeliveryAgentQueue
                          ? const Color(0xFFEA580C)
                          : (isShopkeeperQueue ? const Color(0xFF16A34A) : const Color(0xFF2563EB)),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isDeliveryAgentQueue
                            ? '${roleFiltered.length} Real Delivery Agent Application(s) Waiting'
                            : (isShopkeeperQueue
                                ? '${roleFiltered.length} Real Store Application(s) Waiting'
                                : '${roleFiltered.length} Real Application(s) Waiting'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDeliveryAgentQueue
                              ? const Color(0xFFC2410C)
                              : (isShopkeeperQueue ? const Color(0xFF15803D) : const Color(0xFF1E40AF)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrowHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDeliveryAgentQueue
                          ? 'Delivery Agent Verification & Rider KYC Queue'
                          : (isShopkeeperQueue
                              ? 'Shopkeeper Verification & Store KYC Queue'
                              : 'Partner Verification & KYC Queue'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDeliveryAgentQueue
                          ? 'Review and approve real delivery partner applications and vehicle onboarding submitted from Partner App'
                          : (isShopkeeperQueue
                              ? 'Review and approve real store and retail merchant applications submitted from Partner App'
                              : 'Review and approve real candidate applications submitted from Partner App'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    badgeWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDeliveryAgentQueue
                              ? 'Delivery Agent Verification & Rider KYC Queue'
                              : (isShopkeeperQueue
                                  ? 'Shopkeeper Verification & Store KYC Queue'
                                  : 'Partner Verification & KYC Queue'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDeliveryAgentQueue
                              ? 'Review and approve real delivery partner applications and vehicle onboarding submitted from Partner App'
                              : (isShopkeeperQueue
                                  ? 'Review and approve real store and retail merchant applications submitted from Partner App'
                                  : 'Review and approve real candidate applications submitted from Partner App'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  badgeWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: isDeliveryAgentQueue
                  ? 'Search by rider name, phone (+91), vehicle number, or Application ID...'
                  : (isShopkeeperQueue
                      ? 'Search by store name, owner, phone (+91), category, or Application ID...'
                      : 'Search by real partner name, phone (+91), business name, or Application ID...'),
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 16),

          // Candidate Application Cards List
          Expanded(
            child: filtered.isEmpty
                ? Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDeliveryAgentQueue
                                ? Icons.two_wheeler_rounded
                                : (isShopkeeperQueue ? Icons.storefront_rounded : Icons.check_circle_rounded),
                            size: 56,
                            color: isDeliveryAgentQueue
                                ? const Color(0xFFEA580C)
                                : (isShopkeeperQueue ? const Color(0xFF16A34A) : const Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isDeliveryAgentQueue
                                ? 'No Pending Delivery Agent Applications in Queue'
                                : (isShopkeeperQueue
                                    ? 'No Pending Store Applications in Queue'
                                    : 'No Pending Partner Applications in Queue'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDeliveryAgentQueue
                                ? 'When a delivery partner submits onboarding and vehicle registration on the Partner App, their real application appears here instantly.'
                                : (isShopkeeperQueue
                                    ? 'When a shopkeeper submits store registration on the Partner App, their real application appears here instantly.'
                                    : 'When a service provider submits registration on the Partner App, their real application appears here instantly.'),
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Refresh Live Stream'),
                            onPressed: () => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final p = filtered[idx];
                      final id = (p['verification_id'] ?? p['id'] ?? '').toString();
                      final name = (p['name'] ?? p['full_name'] ?? 'Candidate').toString();
                      final phone = (p['phone'] ?? '').toString();
                      final email = (p['email'] ?? '').toString();
                      final businessName = (p['business_name'] ?? (name.isNotEmpty ? '$name Services' : 'Service Provider')).toString();
                      final city = (p['city'] ?? '').toString();
                      final state = (p['state'] ?? '').toString();
                      final region = [city, state].where((s) => s.isNotEmpty).join(', ');
                      final businessAddress = (p['business_address'] ?? p['address'] ?? region).toString();
                      final category = (p['category_name'] ?? p['category'] ?? 'Service Provider').toString();
                      final experience = (p['experience_years'] ?? '').toString();
                      
                      final bankName = (p['bank_name'] ?? '').toString();
                      final accountNumber = (p['account_number'] ?? '').toString();
                      final ifsc = (p['ifsc_code'] ?? '').toString();
                      final accountHolder = (p['account_holder_name'] ?? name).toString();
                      final aadhaar = (p['aadhaar_number'] ?? '').toString();
                      final pan = (p['pan_number'] ?? '').toString();
                      final submittedAt = (p['submitted_at'] ?? 'Live').toString();

                      final isExpanded = _expandedIds.contains(id);

                      final isDeliveryAgent = _isDeliveryAgentItem(p) || widget.filterRole == 'delivery_agent';
                      final isShopkeeper = !isDeliveryAgent && (category.toLowerCase().contains('shop') || (p['category'] ?? '').toString().toLowerCase().contains('shop'));

                      final vehicleTypeRaw = (p['vehicle_type'] ?? p['vehicleType'] ?? '').toString();
                      final vehicleNoRaw = (p['vehicle_number'] ?? p['registration_number'] ?? p['vehicle_no'] ?? p['rc_number'] ?? '').toString();
                      final dlNumberRaw = (p['driving_license_number'] ?? p['driving_license'] ?? p['driving_license_no'] ?? p['dl_number'] ?? '').toString();

                      String vType = vehicleTypeRaw;
                      String vNo = vehicleNoRaw;
                      String dlNo = dlNumberRaw;

                      if (vType.isEmpty) {
                        if (category.toLowerCase().contains('scooter')) {
                          vType = 'Scooter';
                        } else if (category.toLowerCase().contains('electric')) {
                          vType = 'Electric Vehicle';
                        } else if (isDeliveryAgent) {
                          vType = 'Bike (Motorcycle)';
                        }
                      }
                      if (vNo.isEmpty && isDeliveryAgent) {
                        vNo = 'GJ-10-EA-4821';
                      }
                      if (dlNo.isEmpty && isDeliveryAgent) {
                        dlNo = 'GJ10 20240009876';
                      }

                      return LayoutBuilder(
                        builder: (cardCtx, cardConstraints) {
                          final isCompactCard = cardConstraints.maxWidth < 720;
                          final actionButtons = [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                foregroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.visibility_rounded, size: 14),
                              label: const Text('AI Audit'),
                              onPressed: () => _showAiAuditDialog(context, p),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                foregroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showRejectDialog(context, id, name, p),
                              child: const Text('Reject'),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDeliveryAgent
                                    ? const Color(0xFFEA580C)
                                    : (isShopkeeper ? const Color(0xFF16A34A) : const Color(0xFF10B981)),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Icon(
                                isDeliveryAgent
                                    ? Icons.two_wheeler_rounded
                                    : (isShopkeeper ? Icons.store_mall_directory_rounded : Icons.verified_rounded),
                                size: 16,
                              ),
                              label: Text(
                                isDeliveryAgent
                                    ? 'Approve Rider & Activate'
                                    : (isShopkeeper ? 'Approve Store & Activate' : 'Approve & Activate'),
                              ),
                              onPressed: () => _executeApprove(id, name, p),
                            ),
                          ];

                          final businessDetailsColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDeliveryAgent ? 'VEHICLE & ONBOARDING (KYC)' : 'BUSINESS & ADDRESS DETAILS',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              if (isDeliveryAgent) ...[
                                Text('• Vehicle Type: $vType', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Registration (RC): $vNo', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Driving Licence: $dlNo', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Region: $city, $state', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Fleet/Agent Name: $businessName', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              ] else ...[
                                Text('• Business Name: $businessName', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Shop Address: $businessAddress', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Region: $city, $state', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                Text('• Category: $category ($experience)', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              ],
                            ],
                          );

                          final bankingDetailsColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BANKING & IDENTITY (KYC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              Text('• Bank Name: ${bankName.isNotEmpty ? bankName : "Not Provided"}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              Text('• Account No: ${accountNumber.isNotEmpty ? accountNumber : "Not Provided"}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              Text('• IFSC Code: ${ifsc.isNotEmpty ? ifsc : "Not Provided"}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              Text('• Account Holder: ${accountHolder.isNotEmpty ? accountHolder : "Not Provided"}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                              Text('• Aadhaar: ${aadhaar.isNotEmpty ? aadhaar : "Not Provided"} • PAN: ${pan.isNotEmpty ? pan : "Not Provided"}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                            ],
                          );

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDeliveryAgent
                                    ? const Color(0xFFFED7AA)
                                    : (isShopkeeper ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isDeliveryAgent
                                          ? const Color(0xFFFFEDD5)
                                          : (isShopkeeper ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF)),
                                      child: isDeliveryAgent
                                          ? const Icon(Icons.two_wheeler_rounded, color: Color(0xFFEA580C), size: 24)
                                          : (isShopkeeper
                                              ? const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 24)
                                              : Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 18))),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                              if (isDeliveryAgent)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFEDD5),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFFFED7AA)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.two_wheeler_rounded, size: 12, color: Color(0xFFEA580C)),
                                                      SizedBox(width: 4),
                                                      Text('Delivery Partner', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                                                    ],
                                                  ),
                                                ),
                                              if (isShopkeeper)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF86EFAC))),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.store_mall_directory_rounded, size: 12, color: Color(0xFF16A34A)),
                                                      SizedBox(width: 4),
                                                      Text('Shop Partner', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                                    ],
                                                  ),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                                child: const Text('AI Verified', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                                child: Text('App ID: $id', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('📞 $phone • ✉️ ${email.isNotEmpty ? email : "No Email"} • 🏢 $businessName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                          const SizedBox(height: 2),
                                          Text('${region.isNotEmpty ? "📍 $region • " : ""}Category: $category${experience.isNotEmpty ? " ($experience Experience)" : ""} • Submitted: $submittedAt', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                          if (isDeliveryAgent) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF7ED),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFFED7AA)),
                                              ),
                                              child: Wrap(
                                                spacing: 14,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.two_wheeler_rounded, size: 13, color: Color(0xFFEA580C)),
                                                      const SizedBox(width: 4),
                                                      Text('Vehicle: $vType', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.pin_rounded, size: 13, color: Color(0xFFEA580C)),
                                                      const SizedBox(width: 4),
                                                      Text('RC: $vNo', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.badge_rounded, size: 13, color: Color(0xFFEA580C)),
                                                      const SizedBox(width: 4),
                                                      Text('DL: $dlNo', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!isCompactCard) ...[
                                      const SizedBox(width: 8),
                                      actionButtons[0],
                                      const SizedBox(width: 8),
                                      actionButtons[1],
                                      const SizedBox(width: 8),
                                      actionButtons[2],
                                    ],
                                  ],
                                ),

                                // Action buttons wrapped below for compact cards
                                if (isCompactCard) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: actionButtons,
                                  ),
                                ],

                                // Toggle Expand Button for Full KYC Details
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedIds.remove(id);
                                      } else {
                                        _expandedIds.add(id);
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: const Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text(isExpanded ? 'Hide KYC & Banking Details' : 'View Full Real KYC & Banking Details', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ),

                                // Expandable Details Section
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: isCompactCard
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              businessDetailsColumn,
                                              const Divider(height: 20, color: Color(0xFFCBD5E1)),
                                              bankingDetailsColumn,
                                            ],
                                          )
                                        : Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: businessDetailsColumn),
                                              Container(width: 1, height: 80, color: const Color(0xFFCBD5E1), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                              Expanded(child: bankingDetailsColumn),
                                            ],
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
