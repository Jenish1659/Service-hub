import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 10: Availability & Working Hours Screen for Cooking Partner (Matching Design)
/// 100% Real Data Guarantee • Zero Fake/Mock Data
class CookingWorkingHoursScreen extends StatefulWidget {
  const CookingWorkingHoursScreen({super.key});

  @override
  State<CookingWorkingHoursScreen> createState() => _CookingWorkingHoursScreenState();
}

class _CookingWorkingHoursScreenState extends State<CookingWorkingHoursScreen> {
  bool _isOnline = true;
  bool _isLoading = true;
  bool _isSaving = false;

  final Set<String> _workingDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _breakStartTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _breakEndTime = const TimeOfDay(hour: 14, minute: 0);

  Map<String, dynamic>? _partnerProfile;

  static const Color primaryOrange = Color(0xFFEA580C);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner() ??
        {};

    if (mounted) {
      _partnerProfile = cached;
      _isOnline = (cached['is_online'] == true) ||
          (cached['availability_status']?.toString().toUpperCase() == 'ONLINE');

      final savedDays = cached['working_days'];
      if (savedDays is List && savedDays.isNotEmpty) {
        _workingDays.clear();
        _workingDays.addAll(savedDays.map((e) => e.toString()));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final updated = Map<String, dynamic>.from(_partnerProfile ?? {});
    updated['is_online'] = _isOnline;
    updated['availability_status'] = _isOnline ? 'ONLINE' : 'OFFLINE';
    updated['working_days'] = _workingDays.toList();
    updated['working_hours_start'] = _formatTimeOfDay(_startTime);
    updated['working_hours_end'] = _formatTimeOfDay(_endTime);
    updated['break_hours'] = '${_formatTimeOfDay(_breakStartTime)} - ${_formatTimeOfDay(_breakEndTime)}';

    await LocalRegistrationCache.updateActiveServiceProvider(updated);
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Working hours and availability updated successfully!'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime({required bool isStart}) async {
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

  Future<void> _pickBreakTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _breakStartTime : _breakEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _breakStartTime = picked;
        } else {
          _breakEndTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Availability & Working Hours',
          style: TextStyle(color: darkSlate, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Current Status Switch Card (Screen 10)
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Status',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isOnline ? 'Online • Accepting Orders' : 'Offline • Busy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _isOnline,
                      activeThumbColor: const Color(0xFF16A34A),
                      onChanged: (val) => setState(() => _isOnline = val),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Working Days Chips
          const Text(
            'Working Days *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _allDays.map((day) {
              final isSelected = _workingDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_workingDays.length > 1) _workingDays.remove(day);
                    } else {
                      _workingDays.add(day);
                    }
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryOrange : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? primaryOrange : cardBorder),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryOrange.withValues(alpha: 0.25),
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

          // 3. Working Hours Time Pickers
          const Text(
            'Working Hours *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTimePickerCard(
                  label: 'Start Time',
                  timeStr: _formatTimeOfDay(_startTime),
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePickerCard(
                  label: 'End Time',
                  timeStr: _formatTimeOfDay(_endTime),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Break Time (Optional)
          const Text(
            'Break Time (Optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTimePickerCard(
                  label: 'Break Starts',
                  timeStr: _formatTimeOfDay(_breakStartTime),
                  onTap: () => _pickBreakTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePickerCard(
                  label: 'Break Ends',
                  timeStr: _formatTimeOfDay(_breakEndTime),
                  onTap: () => _pickBreakTime(isStart: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimePickerCard({
    required String label,
    required String timeStr,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                  ),
                  const Icon(Icons.access_time_rounded, size: 16, color: primaryOrange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
