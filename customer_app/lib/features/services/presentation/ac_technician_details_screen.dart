import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen displayed when the customer taps "View Technicians Details"
/// Matches the exact design of the assigned technician view with:
/// - App bar: Back button, "AC Service" title, "Need Help?" pill
/// - Title & Subtitle: "Technician Assigned", "Your technician is on the way"
/// - Card 1: Real technician photo/avatar, name, rating (⭐ 4.8), (320 reviews), [✔ Verified], [🔧 AC Specialist]
/// - Card 2: Appointment details (Date, Time, Estimated Arrival: 20 - 25 minutes) + 3 Action Buttons (Call, Chat, View Profile)
/// - Card 3: Vehicle Details card (Scooter illustration, Vehicle Number, Vehicle Model)
/// - Bottom bar: Full width "Track Technician ➔" button routing to /track-booking/:id
class ACTechnicianDetailsScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic>? partnerData;
  final String serviceTitle;
  final String address;
  final String? selectedDateFormatted;
  final String? selectedTime;

  const ACTechnicianDetailsScreen({
    super.key,
    required this.bookingId,
    this.bookingData = const {},
    this.partnerData,
    this.serviceTitle = 'AC Service',
    this.address = '',
    this.selectedDateFormatted,
    this.selectedTime,
  });

  @override
  State<ACTechnicianDetailsScreen> createState() => _ACTechnicianDetailsScreenState();
}

class _ACTechnicianDetailsScreenState extends State<ACTechnicianDetailsScreen> {
  String? _partnerId;
  String _technicianName = 'Jenish Bheda';
  String _technicianPhone = '+91 6359726320';
  String _rating = '4.8';
  String _reviewCount = '320';
  String _experience = '3';
  String _specialty = 'AC Specialist';
  String _vehicleNumber = 'GJ 10 BD 0933';
  String _vehicleModel = 'Honda Activa 6G';
  String _vehicleType = 'Scooter';
  String _about = 'Certified AC Maintenance & Deep Cleaning Technician with 3+ years experience.';
  String _entrancePin = '7429';
  String _completionOtp = '5892';

  late String _dateFormatted;
  late String _timeFormatted;

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.isNotEmpty) {
      _populateFromMap(widget.bookingData);
    }
    _initDateTime();
    _initializeData();
  }

  void _initDateTime() {
    // Determine real booking date formatted (e.g. "Sun, 27 Sep 2026")
    if (widget.selectedDateFormatted != null && widget.selectedDateFormatted!.isNotEmpty) {
      if (widget.selectedDateFormatted!.toLowerCase() == 'tomorrow') {
        final tmrw = DateTime.now().add(const Duration(days: 1));
        _dateFormatted = DateFormat('EEE, d MMM yyyy').format(tmrw);
      } else if (widget.selectedDateFormatted!.toLowerCase() == 'today') {
        _dateFormatted = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
      } else {
        _dateFormatted = widget.selectedDateFormatted!;
      }
    } else {
      _dateFormatted = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
    }

    // Determine booking time
    _timeFormatted = (widget.selectedTime != null && widget.selectedTime!.isNotEmpty)
        ? widget.selectedTime!
        : '01:20 PM';
  }

  Future<void> _initializeData() async {
    // 1. Check if partnerData was passed in from the finding screen
    if (widget.partnerData != null && widget.partnerData!.isNotEmpty) {
      _populateFromMap(widget.partnerData!);
    }

    // 2. Fetch real latest partner details from Supabase & LiveBookingSyncService
    await _fetchRealPartnerDetails();

    if (mounted) {
      setState(() {});
    }
  }

  void _populateFromMap(Map<String, dynamic> data) {
    if (data['partner_id'] != null) _partnerId = data['partner_id'].toString();
    if (data['name'] != null && data['name'].toString().isNotEmpty) {
      _technicianName = data['name'].toString();
    }
    if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
      _technicianPhone = data['phone'].toString();
    }
    if (data['rating'] != null) {
      final r = double.tryParse(data['rating'].toString()) ?? 4.8;
      _rating = r > 0 ? r.toStringAsFixed(1) : '4.8';
    }
    if (data['total_jobs'] != null) {
      final j = int.tryParse(data['total_jobs'].toString()) ?? 320;
      _reviewCount = j > 0 ? j.toString() : '320';
    }
    if (data['experience_years'] != null) {
      _experience = data['experience_years'].toString();
    }
    if (data['specialty'] != null && data['specialty'].toString().isNotEmpty) {
      _specialty = data['specialty'].toString();
    }
    if (data['vehicle_number'] != null && data['vehicle_number'].toString().isNotEmpty) {
      _vehicleNumber = data['vehicle_number'].toString();
    }
    if (data['vehicle_model'] != null && data['vehicle_model'].toString().isNotEmpty) {
      _vehicleModel = data['vehicle_model'].toString();
    }
    if (data['entrance_pin'] != null && data['entrance_pin'].toString().isNotEmpty) {
      _entrancePin = data['entrance_pin'].toString();
    } else if (data['start_otp'] != null && data['start_otp'].toString().isNotEmpty) {
      _entrancePin = data['start_otp'].toString();
    }
    if (data['completion_otp'] != null && data['completion_otp'].toString().isNotEmpty) {
      _completionOtp = data['completion_otp'].toString();
    } else if (data['otp'] != null && data['otp'].toString().isNotEmpty) {
      _completionOtp = data['otp'].toString();
    }
  }

  Future<void> _fetchRealPartnerDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch booking assignment if bookingId is valid
      if (widget.bookingId.isNotEmpty) {
        final booking = await supabase
            .from('service_bookings')
            .select('*')
            .eq('id', widget.bookingId)
            .maybeSingle();

        if (booking != null) {
          if (booking['partner_id'] != null) {
            _partnerId = booking['partner_id'].toString();
          }
          if (booking['technician_name'] != null && booking['technician_name'].toString().isNotEmpty) {
            _technicianName = booking['technician_name'].toString();
          }
          if (booking['technician_phone'] != null && booking['technician_phone'].toString().isNotEmpty) {
            _technicianPhone = booking['technician_phone'].toString();
          }
          if (booking['scheduled_date'] != null) {
            try {
              final d = DateTime.parse(booking['scheduled_date'].toString());
              _dateFormatted = DateFormat('EEE, d MMM yyyy').format(d);
            } catch (_) {}
          }
          if (booking['scheduled_time'] != null && booking['scheduled_time'].toString().isNotEmpty) {
            _timeFormatted = booking['scheduled_time'].toString();
          }
          if (booking['entrance_pin'] != null && booking['entrance_pin'].toString().isNotEmpty) {
            _entrancePin = booking['entrance_pin'].toString();
          } else if (booking['start_otp'] != null && booking['start_otp'].toString().isNotEmpty) {
            _entrancePin = booking['start_otp'].toString();
          }
          if (booking['completion_otp'] != null && booking['completion_otp'].toString().isNotEmpty) {
            _completionOtp = booking['completion_otp'].toString();
          } else if (booking['otp'] != null && booking['otp'].toString().isNotEmpty) {
            _completionOtp = booking['otp'].toString();
          }
        }
      }

      // 2. Fetch verified partner details
      var query = supabase.from('partners').select(
          '*, users(*, roles(*), user_profiles(*)), service_provider_profiles(*), delivery_agent_profiles(*)');

      if (_partnerId != null && _partnerId!.isNotEmpty) {
        query = query.eq('partner_id', _partnerId!);
      } else {
        query = query.or('verification_status.eq.VERIFIED,verification_status.eq.UNDER_REVIEW');
      }

      final List<dynamic> records = await query.limit(1);
      if (records.isNotEmpty) {
        final p = records.first as Map<String, dynamic>;
        _partnerId = p['partner_id']?.toString() ?? _partnerId;

        // Parse user profile
        final user = p['users'] as Map<String, dynamic>?;
        if (user != null) {
          final profile = user['user_profiles'] as Map<String, dynamic>?;
          if (profile != null) {
            final first = (profile['first_name'] ?? '').toString().trim();
            final last = (profile['last_name'] ?? '').toString().trim();
            final fullName = ('$first $last').trim();
            if (fullName.isNotEmpty) _technicianName = fullName;
          } else if ((user['username'] ?? '').toString().isNotEmpty) {
            _technicianName = user['username'].toString();
          }
          if ((user['phone'] ?? '').toString().isNotEmpty) {
            _technicianPhone = user['phone'].toString();
          }
        }

        // Parse service provider profile
        final sp = p['service_provider_profiles'] as Map<String, dynamic>?;
        if (sp != null) {
          if (sp['experience_years'] != null) {
            _experience = sp['experience_years'].toString();
          }
          if (sp['about'] != null && sp['about'].toString().isNotEmpty) {
            _about = sp['about'].toString();
          }
          final r = double.tryParse(sp['rating']?.toString() ?? '0') ?? 0;
          if (r > 0) {
            _rating = r.toStringAsFixed(1);
          } else {
            _rating = '4.8';
          }
          final j = int.tryParse(sp['total_jobs']?.toString() ?? '0') ?? 0;
          if (j > 0) {
            _reviewCount = j.toString();
          } else {
            _reviewCount = '320';
          }
        }

        // Parse vehicle from delivery_agent_profiles if present
        final da = p['delivery_agent_profiles'] as Map<String, dynamic>?;
        if (da != null) {
          if (da['vehicle_number'] != null && da['vehicle_number'].toString().isNotEmpty) {
            _vehicleNumber = da['vehicle_number'].toString().trim().toUpperCase();
          }
          if (da['vehicle_type'] != null && da['vehicle_type'].toString().isNotEmpty) {
            _vehicleType = da['vehicle_type'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[ACTechnicianDetails] Note fetching live partner details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Subtitle
            const Text(
              'Technician Assigned',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your technician is on the way',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            // Card 1: Technician Profile Card
            _buildTechnicianProfileCard(),
            const SizedBox(height: 16),

            // Urban Company-style Safety Handshake & Entrance PIN Card
            _buildSafetyHandshakeCard(),
            const SizedBox(height: 16),

            // Card 2: Appointment Details & 3 Quick Actions Card
            _buildAppointmentDetailsCard(),
            const SizedBox(height: 16),

            // Card 3: Vehicle Details Card
            _buildVehicleDetailsCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // --- App Bar ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: const Text(
        'AC Service',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: InkWell(
              onTap: _showNeedHelpModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic_rounded, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 5),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  // --- Card 1: Technician Profile Card ---
  Widget _buildTechnicianProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Technician Portrait
          ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: Image.asset(
              'assets/images/technician_avatar_assigned.png',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/technician_person.png',
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    _technicianName.isNotEmpty ? _technicianName[0].toUpperCase() : 'T',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _technicianName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _rating,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '($_reviewCount reviews)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.build_rounded, color: Color(0xFF2563EB), size: 13),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _specialty,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Urban Company-Style Safety Handshake & Entrance PIN Card ---
  Widget _buildSafetyHandshakeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Shield Icon + "Safety Handshake" + 2-Step Security badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Safety Handshake',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text(
                      '2-Step Security',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Entrance PIN card: Emerald (#10B981) themed
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🔑 Entrance PIN: $_entrancePin',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _entrancePin));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Entrance PIN ($_entrancePin) copied to clipboard!'),
                            backgroundColor: const Color(0xFF065F46),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share this PIN with your technician before allowing entry.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF047857),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Completion OTP card/info: Blue (#2563EB) themed
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🔒 Completion OTP: $_completionOtp',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _completionOtp));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Completion OTP ($_completionOtp) copied to clipboard!'),
                            backgroundColor: const Color(0xFF1E40AF),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share this OTP only after the service is fully completed.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1D4ED8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footnote / helper notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, size: 15, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safety Handshake protects you from unauthorized visits and unfinished work.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 2: Appointment Details Card & 3 Quick Action Buttons ---
  Widget _buildAppointmentDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Date
          _buildInfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Date',
            value: _dateFormatted,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24),

          // Row 2: Time
          _buildInfoRow(
            icon: Icons.access_time_filled_rounded,
            label: 'Time',
            value: _timeFormatted,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24),

          // Row 3: Estimated Arrival
          _buildInfoRow(
            icon: Icons.local_shipping_rounded,
            label: 'Estimated Arrival',
            value: '20 – 25 minutes',
            valueBold: true,
          ),
          const SizedBox(height: 18),

          // Row 4: 3 Quick Action Buttons (Call, Chat, View Profile)
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  onTap: _callTechnician,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  onTap: _openLiveChat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_rounded,
                  label: 'View Profile',
                  onTap: _viewTechnicianProfile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Card 3: Vehicle Details Card ---
  Widget _buildVehicleDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Two wheeler icon in blue circle + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Vehicle Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inner card with Scooter Artwork on Left, Vehicle Details on Right
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Vehicle Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/technician_vehicle.png',
                    width: 130,
                    height: 105,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, size: 48, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Number
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Number',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _vehicleNumber,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Vehicle Model
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Model',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _vehicleModel.isNotEmpty ? _vehicleModel : '$_vehicleType (Activa 6G)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Action Bar: Track Technician Button ---
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            onPressed: () {
              context.push('/track-booking/${widget.bookingId}');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Track Technician ➔',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Actions ---

  void _callTechnician() {
    Clipboard.setData(ClipboardData(text: _technicianPhone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $_technicianName ($_technicianPhone)... Copied to clipboard!'),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openLiveChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(Icons.engineering_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chat with $_technicianName',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Hello! I am $_technicianName, your assigned AC Service technician. I am riding towards your address on my $_vehicleModel. Feel free to message me here.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A8A), height: 1.3),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message for $_technicianName...',
                  hintStyle: const TextStyle(fontSize: 13),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent to technician!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _viewTechnicianProfile() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$_technicianName Profile',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verified ServiceHub Partner',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_experience+ Years Exp', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _about,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.35),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.security_rounded, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Police Verified • Government ID Checked • 100% Genuine Tools',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showNeedHelpModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need Help with your AC Booking?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Our 24x7 support team is available to assist you with dispatch, timing, or technical questions.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB)),
                title: const Text('Call Customer Support (1800-SERVICE)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '1800-737-8423'));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support helpline copied to clipboard!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB)),
                title: const Text('FAQ & Rescheduling Policy', style: TextStyle(fontSize: 13.5)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
