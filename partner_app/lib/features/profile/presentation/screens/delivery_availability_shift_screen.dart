import 'package:flutter/material.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../controllers/delivery_agent_profile_controller.dart';

class DeliveryAvailabilityShiftScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliveryAvailabilityShiftScreen({super.key, this.controller});

  @override
  State<DeliveryAvailabilityShiftScreen> createState() => _DeliveryAvailabilityShiftScreenState();
}

class _DeliveryAvailabilityShiftScreenState extends State<DeliveryAvailabilityShiftScreen> {
  late bool _isAvailable;
  final String _shiftTiming = '09:00 AM – 08:00 PM';
  final Set<String> _workingDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  bool _autoOfflineAfterShift = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.controller?.isOnline ?? true;
    _loadSavedAvailability();
  }

  Future<void> _loadSavedAvailability() async {
    try {
      final cached = widget.controller?.agentData ?? await LocalRegistrationCache.getActiveDeliveryAgent();
      if (cached != null && mounted) {
        setState(() {
          if (cached['is_online'] != null) {
            _isAvailable = cached['is_online'] == true;
          }
        });
      }
    } catch (_) {}
  }

  void _toggleDay(String day) {
    setState(() {
      if (_workingDays.contains(day)) {
        if (_workingDays.length > 1) _workingDays.remove(day);
      } else {
        _workingDays.add(day);
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    widget.controller?.toggleOnline(_isAvailable);
    await LocalRegistrationCache.updateActiveDeliveryAgent({
      'is_online': _isAvailable,
      'working_days': _workingDays.toList(),
      'shift_timing': _shiftTiming,
    });
    final uid = widget.controller?.agentData?['user_id']?.toString() ??
        (await LocalRegistrationCache.getActiveDeliveryAgent())?['user_id']?.toString();
    if (uid != null) {
      await SupabaseAuthService.updateDeliveryAgentInDatabase(
        userId: uid,
        availabilityStatus: _isAvailable ? 'ONLINE' : 'OFFLINE',
      );
    }
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability and shift settings saved to database!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFEA580C);
    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
          'Availability & Shift',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Currently Available Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAvailable ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAvailable ? 'Currently Available' : 'Currently Offline',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isAvailable ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'You will receive delivery requests when you are online.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailable,
                    activeTrackColor: orangeColor,
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Today's Shift
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Shift",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shift editor: Pick custom hours'),
                              backgroundColor: orangeColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Edit', style: TextStyle(color: orangeColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _shiftTiming,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Working Days
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Working Days',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allDays.map((d) {
                      final isSelected = _workingDays.contains(d);
                      return InkWell(
                        onTap: () => _toggleDay(d),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? orangeColor : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? orangeColor : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 4: Auto Offline After Shift
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Offline After Shift',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'When your shift ends, you will automatically go offline.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoOfflineAfterShift,
                    activeTrackColor: orangeColor,
                    onChanged: (val) => setState(() => _autoOfflineAfterShift = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info Callout Notice Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can change your availability anytime. You will not receive new requests when you are offline.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
