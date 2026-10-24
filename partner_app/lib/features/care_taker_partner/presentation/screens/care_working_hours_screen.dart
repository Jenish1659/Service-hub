import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 10: Dedicated Availability & Working Hours Sub-Screen for Care Taker Specialist
class CareWorkingHoursScreen extends StatefulWidget {
  const CareWorkingHoursScreen({super.key});

  @override
  State<CareWorkingHoursScreen> createState() => _CareWorkingHoursScreenState();
}

class _CareWorkingHoursScreenState extends State<CareWorkingHoursScreen> {
  bool _isOnline = true;
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  final TimeOfDay _breakStart = const TimeOfDay(hour: 13, minute: 0);
  final TimeOfDay _breakEnd = const TimeOfDay(hour: 14, minute: 0);

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();
    if (mounted) {
      setState(() {
        _isOnline = (cached?['is_online'] == true) ||
            (cached?['availability_status']?.toString().toUpperCase() == 'ONLINE');
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveWorkingHours() async {
    await LocalRegistrationCache.updateActiveServiceProvider({
      'is_online': _isOnline,
      'availability_status': _isOnline ? 'ONLINE' : 'OFFLINE',
      'working_days': _selectedDays.toList(),
      'start_time': _startTime.format(context),
      'end_time': _endTime.format(context),
      'break_time': '${_breakStart.format(context)} - ${_breakEnd.format(context)}',
      'role': 'care_taker',
      'category': 'care_taker',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Working hours and availability saved successfully!'),
          backgroundColor: primaryIndigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Availability & Working Hours',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card matching reference UI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Status', style: TextStyle(fontSize: 13, color: textMuted)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: _isOnline ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _isOnline ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    activeThumbColor: primaryIndigo,
                    onChanged: (val) => setState(() => _isOnline = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Working Days Section matching circular chips in reference UI
            const Text('Working Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _allDays.map((day) {
                final isSelected = _selectedDays.contains(day);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedDays.length > 1) _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryIndigo : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? primaryIndigo : cardBorder),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryIndigo.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : darkSlate,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Working Hours Section
            const Text('Working Hours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time', style: TextStyle(fontSize: 11, color: textMuted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: primaryIndigo),
                              const SizedBox(width: 6),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time', style: TextStyle(fontSize: 11, color: textMuted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: primaryIndigo),
                              const SizedBox(width: 6),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Break Time Section (Optional)
            const Text('Break Time (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.coffee_rounded, size: 18, color: primaryIndigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_breakStart.format(context)} - ${_breakEnd.format(context)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 16, color: textMuted),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
          bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveWorkingHours,
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ),
      ),
    );
  }
}
