import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/top_toast.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperServiceAreaScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperServiceAreaScreen({super.key, this.controller});

  @override
  State<ShopkeeperServiceAreaScreen> createState() => _ShopkeeperServiceAreaScreenState();
}

class _ShopkeeperServiceAreaScreenState extends State<ShopkeeperServiceAreaScreen> {
  late final ShopkeeperProfileController _controller;
  late double _radiusKm;
  late String _currentArea;
  bool _isSaving = false;

  final List<String> _popularAreas = [
    'Rajkot',
    'Jamnagar',
    'Ahmedabad',
    'Surat',
    'Vadodara',
    'Morbi',
    'Junagadh',
    'Gandhinagar',
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
    _radiusKm = _controller.serviceRadiusKm.clamp(1.0, 10.0);
    _currentArea = _controller.currentArea.isNotEmpty
        ? _controller.currentArea
        : (_controller.city.isNotEmpty ? _controller.city : 'Rajkot');
  }

  void _showChangeAreaDialog() {
    final areaTextController = TextEditingController(text: _currentArea);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Change Operational Area',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter city or neighborhood where your store is situated:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaTextController,
                autofocus: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF16A34A)),
                  hintText: 'e.g. Rajkot, Kalawad Road',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'POPULAR REGIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularAreas.map((city) {
                  final isSelected = areaTextController.text.trim().toLowerCase() == city.toLowerCase();
                  return InkWell(
                    onTap: () {
                      setDialogState(() {
                        areaTextController.text = city;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF15803D) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final text = areaTextController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _currentArea = text;
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Set Area', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await _controller.updateServiceArea(
        radiusKm: _radiusKm,
        area: _currentArea,
      );
      if (mounted) {
        TopToast.show(context, 'Service area updated successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        TopToast.show(context, 'Failed to update service area: $e', isError: true);
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
            // Header
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
                          'Service Area',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Manage your delivery area',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Visual Map Card with Concentric Circles & Center Pin
                    Container(
                      height: 230,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Custom Painter drawing the concentric radius circles & map simulation
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ConcentricRadiusMapPainter(
                                  radiusKm: _radiusKm,
                                  centerLabel: _currentArea,
                                ),
                              ),
                            ),

                            // Top Left Pill: Dynamic Radius Pill
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: emeraldColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_radiusKm.toStringAsFixed(0)} km Radius',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Top Right Compass / GPS indicator
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF2563EB)),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE GPS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Center Pinpoint Marker with Pulse
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: emeraldColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: emeraldColor.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.store_mall_directory_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _currentArea,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Area Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.location_city_rounded, color: emeraldColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CURRENT OPERATIONAL HUB',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentArea,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Base store location & order dispatch center',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFA7F3D0)),
                              backgroundColor: const Color(0xFFF0FDF4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _showChangeAreaDialog,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_location_alt_rounded, size: 14, color: emeraldColor),
                                SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: emeraldColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Radius Slider Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.radar_rounded, color: emeraldColor, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delivery Radius',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_radiusKm.toStringAsFixed(0)} km',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Adjust how far your delivery personnel or courier partner will travel.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),

                          // Slider: 1 km to 10 km
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: emeraldColor,
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              thumbColor: emeraldColor,
                              overlayColor: emeraldColor.withValues(alpha: 0.15),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            ),
                            child: Slider(
                              value: _radiusKm,
                              min: 1.0,
                              max: 10.0,
                              divisions: 9,
                              onChanged: (val) {
                                setState(() {
                                  _radiusKm = val;
                                });
                              },
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1 km (Hyperlocal)', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                Text('5 km (Standard)', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                Text('10 km (Max)', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Preset Radius Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [2.0, 3.0, 5.0, 7.0, 10.0].map((r) {
                              final isSelected = (_radiusKm.round() == r.round());
                              return InkWell(
                                onTap: () => setState(() => _radiusKm = r),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? emeraldColor : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? emeraldColor : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    '${r.round()} km',
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

                    // Info Callout
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: emeraldColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Orders will be shown within the selected radius only.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customers residing within ${_radiusKm.toStringAsFixed(0)} km of $_currentArea will see your products in their app feed. Keeping a focused radius ensures rapid 30-45 minute dispatch.',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534), height: 1.35),
                                ),
                              ],
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

            // Bottom Save Changes Bar
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
                            Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
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
}

class _ConcentricRadiusMapPainter extends CustomPainter {
  final double radiusKm;
  final String centerLabel;

  _ConcentricRadiusMapPainter({required this.radiusKm, required this.centerLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);

    // 1. Draw subtle road grid pattern
    final roadPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Diagonal arterial roads
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.8), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.75, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.2, size.height), secondaryRoadPaint);

    // 2. Concentric circles scaling
    final maxAllowedRadiusPx = math.min(size.width, size.height) * 0.44;
    final currentOuterPx = (radiusKm / 10.0) * (maxAllowedRadiusPx - 30) + 30;

    // Outer fill area (Translucent emerald)
    final fillPaint = Paint()
      ..color = const Color(0xFF16A34A).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentOuterPx, fillPaint);

    // 3 Concentric Ring Stems
    final ring1 = currentOuterPx * 0.35;
    final ring2 = currentOuterPx * 0.68;
    final ring3 = currentOuterPx;

    final innerRingPaint = Paint()
      ..color = const Color(0xFF16A34A).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final outerRingPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, ring1, innerRingPaint);
    canvas.drawCircle(center, ring2, innerRingPaint);
    canvas.drawCircle(center, ring3, outerRingPaint);

    // Distance Label on Ring 2
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(radiusKm * 0.65).toStringAsFixed(1)} km',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF15803D).withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx + 4, center.dy - ring2 - 10));

    // Distance Label on Outer Ring
    final outerTextPainter = TextPainter(
      text: TextSpan(
        text: '${radiusKm.toStringAsFixed(0)} km Zone',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF15803D),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    outerTextPainter.paint(canvas, Offset(center.dx + 4, center.dy - ring3 - 12));
  }

  @override
  bool shouldRepaint(covariant _ConcentricRadiusMapPainter oldDelegate) {
    return oldDelegate.radiusKm != radiusKm || oldDelegate.centerLabel != centerLabel;
  }
}
