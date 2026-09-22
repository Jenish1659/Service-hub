import 'package:flutter/material.dart';
import '../../../../core/widgets/top_toast.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperBusinessHoursScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperBusinessHoursScreen({super.key, this.controller});

  @override
  State<ShopkeeperBusinessHoursScreen> createState() => _ShopkeeperBusinessHoursScreenState();
}

class _ShopkeeperBusinessHoursScreenState extends State<ShopkeeperBusinessHoursScreen> {
  late final ShopkeeperProfileController _controller;
  bool _isSaving = false;
  late bool _isOpen;
  late Map<String, Map<String, dynamic>> _schedule;

  static const List<String> _orderedDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ShopkeeperProfileController();
    _controller.addListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.loadShopkeeperProfile();
    }
    _syncFromController();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _syncFromController();
      });
    }
  }

  void _syncFromController() {
    _isOpen = _controller.isOpen;
    _schedule = {};
    for (final day in _orderedDays) {
      if (_controller.weeklySchedule.containsKey(day)) {
        _schedule[day] = Map<String, dynamic>.from(_controller.weeklySchedule[day]!);
      } else {
        final isSun = day == 'Sunday';
        _schedule[day] = {
          'open': isSun ? 'Closed' : '09:00 AM',
          'close': isSun ? 'Closed' : '08:00 PM',
          'isClosed': isSun,
        };
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.endsWith('PM');
      final isAm = clean.endsWith('AM');
      final parts = clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].trim());
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay tod) {
    final hourOfPeriod = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final hStr = hourOfPeriod.toString().padLeft(2, '0');
    final mStr = tod.minute.toString().padLeft(2, '0');
    return '$hStr:$mStr $period';
  }

  void _showTimingPickerModal(String day) {
    final dayData = _schedule[day]!;
    if (dayData['isClosed'] == true) {
      TopToast.show(context, '$day is currently marked as closed. Enable the toggle to set timings.', isError: true);
      return;
    }

    String currentOpen = dayData['open']?.toString() ?? '09:00 AM';
    String currentClose = dayData['close']?.toString() ?? '08:00 PM';
    if (currentOpen == 'Closed') currentOpen = '09:00 AM';
    if (currentClose == 'Closed') currentClose = '08:00 PM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Set Timings for $day',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Customers will only be able to place orders during these hours.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final initial = _parseTime(currentOpen);
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: initial,
                          helpText: 'SELECT OPENING TIME',
                        );
                        if (picked != null) {
                          setSheetState(() {
                            currentOpen = _formatTime(picked);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wb_sunny_outlined, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text('Opens At', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentOpen,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final initial = _parseTime(currentClose);
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: initial,
                          helpText: 'SELECT CLOSING TIME',
                        );
                        if (picked != null) {
                          setSheetState(() {
                            currentClose = _formatTime(picked);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.nightlight_round_outlined, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 4),
                                Text('Closes At', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentClose,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'QUICK PRESETS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip('09:00 AM - 08:00 PM', () {
                    setSheetState(() {
                      currentOpen = '09:00 AM';
                      currentClose = '08:00 PM';
                    });
                  }),
                  _buildPresetChip('10:00 AM - 09:00 PM', () {
                    setSheetState(() {
                      currentOpen = '10:00 AM';
                      currentClose = '09:00 PM';
                    });
                  }),
                  _buildPresetChip('08:00 AM - 10:00 PM', () {
                    setSheetState(() {
                      currentOpen = '08:00 AM';
                      currentClose = '10:00 PM';
                    });
                  }),
                  _buildPresetChip('10:00 AM - 07:00 PM', () {
                    setSheetState(() {
                      currentOpen = '10:00 AM';
                      currentClose = '07:00 PM';
                    });
                  }),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _schedule[day] = {
                        'open': currentOpen,
                        'close': currentClose,
                        'isClosed': false,
                      };
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Apply Hours',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ),
    );
  }

  void _applyToAllWeekdays(String sourceDay) {
    final src = _schedule[sourceDay]!;
    if (src['isClosed'] == true) {
      TopToast.show(context, 'Cannot copy closed hours to weekdays', isError: true);
      return;
    }
    setState(() {
      for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']) {
        _schedule[day] = {
          'open': src['open'],
          'close': src['close'],
          'isClosed': false,
        };
      }
    });
    TopToast.show(context, 'Applied $sourceDay timings to Mon - Sat', isError: false);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await _controller.updateBusinessHours(_schedule);
      if (_isOpen != _controller.isOpen) {
        _controller.toggleStoreStatus(_isOpen);
      }
      if (mounted) {
        TopToast.show(context, 'Business hours saved successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        TopToast.show(context, 'Failed to save hours: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldColor = Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Hours',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Set your working hours',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isOpen ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: _isOpen ? emeraldColor : const Color(0xFF94A3B8),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _isOpen ? 'Shop Status: Open Now' : 'Shop Status: Closed',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _isOpen ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _isOpen ? 'LIVE' : 'OFFLINE',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: _isOpen ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isOpen
                                      ? 'Your shop is open / Customers can place orders'
                                      : 'Shop is temporarily closed / Customers cannot place orders',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isOpen,
                            activeTrackColor: emeraldColor,
                            onChanged: (val) {
                              setState(() => _isOpen = val);
                              _controller.toggleStoreStatus(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Weekly List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'WEEKLY WORKING HOURS',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        InkWell(
                          onTap: () => _applyToAllWeekdays('Monday'),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 12, color: emeraldColor),
                                SizedBox(width: 4),
                                Text(
                                  'Copy Mon to Weekdays',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: emeraldColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Day List Cards
                    ..._orderedDays.map((day) => _buildDayTile(day, emeraldColor)),

                    const SizedBox(height: 16),

                    // Tip callout
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap any timing chip to adjust store opening and closing hours. Keeping consistent timings increases regular customer repeats.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Bottom Save Hours Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Hours',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(String day, Color emeraldColor) {
    final data = _schedule[day] ?? {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false};
    final isClosed = data['isClosed'] == true;
    final open = data['open']?.toString() ?? '09:00 AM';
    final close = data['close']?.toString() ?? '08:00 PM';
    final timingText = isClosed ? 'Closed' : '$open - $close';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isClosed ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          // Day Name
          SizedBox(
            width: 85,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isClosed ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              ),
            ),
          ),

          // Timing Chip (Tap to pick timings)
          Expanded(
            child: InkWell(
              onTap: isClosed ? null : () => _showTimingPickerModal(day),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isClosed ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isClosed ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isClosed ? Icons.do_not_disturb_on_outlined : Icons.access_time_filled_rounded,
                      size: 13,
                      color: isClosed ? const Color(0xFF94A3B8) : emeraldColor,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        timingText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isClosed ? const Color(0xFF64748B) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    if (!isClosed) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, size: 16, color: emeraldColor.withValues(alpha: 0.8)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Open / Closed Switch
          Switch(
            value: !isClosed,
            activeTrackColor: emeraldColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() {
                if (!val) {
                  // Turn off -> closed
                  _schedule[day] = {
                    'open': 'Closed',
                    'close': 'Closed',
                    'isClosed': true,
                  };
                } else {
                  // Turn on -> default hours
                  _schedule[day] = {
                    'open': '09:00 AM',
                    'close': '08:00 PM',
                    'isClosed': false,
                  };
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
