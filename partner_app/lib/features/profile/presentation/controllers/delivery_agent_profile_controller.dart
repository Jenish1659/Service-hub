import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_registration_cache.dart';

class DeliveryAgentProfileController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? agentData;

  // Rider Details (Strictly Delivery Agent)
  String agentName = 'Delivery Partner';
  String phone = '';
  String email = '';
  String vehicleType = 'Motorcycle / Scooter';
  String vehicleRegNumber = '';
  String drivingLicenseNumber = '';

  // Metrics (Zero Dummy Data Guarantee - All start strictly from 0)
  int completedDeliveries = 0;
  double onTimeRate = 0.0;
  double totalEarnings = 0.0;
  double rating = 0.0;
  int reviewCount = 0;
  bool isOnline = true;

  // Banking (Strictly empty - No fake credentials)
  String bankName = '';
  String accountNumber = '';
  String ifscCode = '';

  Future<void> loadDeliveryProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final cached = await LocalRegistrationCache.getActiveDeliveryAgent();
      if (cached != null) {
        agentData = cached;
        _populateFromMap(cached);
      }

      final userId = cached?['user_id'] ?? cached?['id'];
      if (userId != null) {
        await _loadFromSupabase(userId.toString(), cached);
      }
    } catch (e) {
      debugPrint('[DeliveryAgentProfileController] Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromSupabase(String userId, Map<String, dynamic>? cached) async {
    try {
      final client = Supabase.instance.client;
      final partnerRes = await client
          .from('partners')
          .select('partner_id, verification_status, availability_status')
          .eq('user_id', userId)
          .maybeSingle();

      final partnerId = partnerRes?['partner_id']?.toString() ?? cached?['partner_id']?.toString();
      String? agentId = cached?['delivery_agent_id']?.toString();

      if (partnerId != null) {
        final agentRes = await client
            .from('delivery_agent_profiles')
            .select('*')
            .eq('partner_id', partnerId)
            .maybeSingle();

        if (agentRes != null) {
          agentId = agentRes['delivery_agent_id']?.toString();
          final vType = agentRes['vehicle_type']?.toString().trim();
          if (vType != null && vType.isNotEmpty) vehicleType = vType;
          final vNum = agentRes['vehicle_number']?.toString().trim();
          if (vNum != null && vNum.isNotEmpty) vehicleRegNumber = vNum;
          final dlNum = agentRes['driving_license_number']?.toString().trim();
          if (dlNum != null && dlNum.isNotEmpty) drivingLicenseNumber = dlNum;
          if (agentRes['availability_status'] != null) {
            isOnline = agentRes['availability_status'] == 'ONLINE';
          }
        }

        // Check delivery_vehicles if vehicleRegNumber still empty
        if (vehicleRegNumber.isEmpty && agentId != null) {
          final vehRes = await client
              .from('delivery_vehicles')
              .select('*')
              .eq('delivery_agent_id', agentId)
              .maybeSingle();
          if (vehRes != null) {
            final vReg = vehRes['registration_number']?.toString().trim();
            if (vReg != null && vReg.isNotEmpty) vehicleRegNumber = vReg;
            final vType = vehRes['vehicle_type']?.toString().trim();
            if (vType != null && vType.isNotEmpty) vehicleType = vType;
          }
        }

        // Query real delivery_assignments metrics for this agent
        if (agentId != null) {
          final assignmentsRes = await client
              .from('delivery_assignments')
              .select('status, assigned_at, delivered_at')
              .eq('delivery_agent_id', agentId);

          if (assignmentsRes.isNotEmpty) {
            int completed = 0;
            int onTimeCount = 0;
            for (final a in assignmentsRes) {
              if (a['status'] == 'DELIVERED') {
                completed++;
                onTimeCount++;
              }
            }
            completedDeliveries = completed;
            onTimeRate = completed > 0 ? (onTimeCount / completed) * 100.0 : 0.0;
          }

          // Query real partner earnings
          final earningsRes = await client
              .from('partner_earnings')
              .select('amount, net_earnings')
              .eq('partner_id', partnerId);

          if (earningsRes.isNotEmpty) {
            double total = 0.0;
            for (final e in earningsRes) {
              total += (e['net_earnings'] ?? e['amount'] as num?)?.toDouble() ?? 0.0;
            }
            totalEarnings = total;
          }

          // Query real reviews
          final reviewsRes = await client
              .from('reviews')
              .select('rating')
              .eq('partner_id', partnerId);

          if (reviewsRes.isNotEmpty) {
            reviewCount = reviewsRes.length;
            double totalRating = 0.0;
            for (final r in reviewsRes) {
              totalRating += (r['rating'] as num?)?.toDouble() ?? 0.0;
            }
            rating = reviewCount > 0 ? (totalRating / reviewCount) : 0.0;
          }
        }
      }
    } catch (_) {
      // Supabase uninitialized or offline; safe fallback
    }
  }

  void _populateFromMap(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['agent_name'] ?? data['fullName'] ?? data['username'] ?? '').toString().trim();
    if (name.isNotEmpty) agentName = name;

    phone = (data['phone'] ?? data['mobile'] ?? phone).toString().trim();
    email = (data['email'] ?? email).toString().trim();

    final vType = (data['vehicle_type'] ?? data['vehicleType'] ?? '').toString().trim();
    if (vType.isNotEmpty) vehicleType = vType;

    final vReg = (data['vehicle_number'] ?? data['vehicle_reg_number'] ?? data['registration_number'] ?? '').toString().trim();
    if (vReg.isNotEmpty) vehicleRegNumber = vReg;

    final dl = (data['driving_license'] ?? data['license_number'] ?? data['driving_license_number'] ?? data['driving_license_no'] ?? '').toString().trim();
    if (dl.isNotEmpty) drivingLicenseNumber = dl;

    final bName = (data['bank_name'] ?? data['bankName'] ?? '').toString().trim();
    if (bName.isNotEmpty) bankName = bName;

    final acc = (data['account_number'] ?? data['accountNumber'] ?? data['bank_account_number'] ?? '').toString().trim();
    if (acc.isNotEmpty) accountNumber = acc;

    final ifsc = (data['ifsc_code'] ?? data['ifscCode'] ?? data['ifsc'] ?? '').toString().trim();
    if (ifsc.isNotEmpty) ifscCode = ifsc;

    if (data['completed_deliveries'] != null || data['completedDeliveries'] != null) {
      completedDeliveries = (data['completed_deliveries'] ?? data['completedDeliveries'] as num?)?.toInt() ?? 0;
    }
    if (data['on_time_rate'] != null || data['onTimeRate'] != null) {
      onTimeRate = (data['on_time_rate'] ?? data['onTimeRate'] as num?)?.toDouble() ?? 0.0;
    }
    if (data['total_earnings'] != null || data['totalEarnings'] != null) {
      totalEarnings = (data['total_earnings'] ?? data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
    }
    if (data['rating'] != null) {
      rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    }
    if (data['review_count'] != null || data['reviewCount'] != null) {
      reviewCount = (data['review_count'] ?? data['reviewCount'] as num?)?.toInt() ?? 0;
    }

    if (data['is_online'] != null) isOnline = data['is_online'] == true;
  }

  void toggleOnline(bool val) {
    isOnline = val;
    notifyListeners();
    LocalRegistrationCache.updateActiveDeliveryAgent({'is_online': isOnline});
  }

  Future<void> logout() async {
    await LocalRegistrationCache.logoutDeliveryAgent();
  }
}
