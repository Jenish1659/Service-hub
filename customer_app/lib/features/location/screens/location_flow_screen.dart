import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_permission_service.dart';
import 'location_permission_screen.dart';
import 'detecting_location_screen.dart';

class LocationFlowScreen extends ConsumerStatefulWidget {
  const LocationFlowScreen({super.key});

  @override
  ConsumerState<LocationFlowScreen> createState() => _LocationFlowScreenState();
}

class _LocationFlowScreenState extends ConsumerState<LocationFlowScreen> {
  bool _isLoadingPermissionCheck = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final permissionService = LocationPermissionService();
    final status = await permissionService.checkPermission();

    if (mounted) {
      setState(() {
        _hasPermission = status == LocationPermissionStatus.granted;
        _isLoadingPermissionCheck = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermissionCheck) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasPermission) {
      return const DetectingLocationScreen();
    } else {
      return LocationPermissionScreen(
        onPermissionGranted: () {
          setState(() {
            _hasPermission = true;
          });
        },
      );
    }
  }
}
