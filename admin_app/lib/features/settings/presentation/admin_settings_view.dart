import 'package:flutter/material.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  double _serviceCommission = 10.0;
  double _geofenceRadius = 5.0;
  bool _enforceStrictGeofence = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings & Security Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Configure platform commission, geofence radius limits (5km strict), and audit parameters', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Commission & Geofence Policy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Text('Service Provider Commission Rate (%):', style: TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    Text('${_serviceCommission.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                  ],
                ),
                Slider(
                  value: _serviceCommission,
                  min: 5,
                  max: 25,
                  divisions: 20,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => setState(() => _serviceCommission = val),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Text('Partner Job Dispatch Radius (km):', style: TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                    Text('${_geofenceRadius.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                  ],
                ),
                Slider(
                  value: _geofenceRadius,
                  min: 2,
                  max: 20,
                  divisions: 18,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => setState(() => _geofenceRadius = val),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enforce Strict Geofence Job Dispatching', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  subtitle: const Text('Only notify partners located within configured radius of the customer', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _enforceStrictGeofence,
                  activeTrackColor: const Color(0xFF2563EB),
                  onChanged: (val) => setState(() => _enforceStrictGeofence = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
