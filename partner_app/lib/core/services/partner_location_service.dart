import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'h3_geospatial_service.dart';
import 'live_booking_sync_service.dart';

/// Real-Time Partner GPS Tracking and Backend Geolocation Sync Engine
/// - Captures real physical/GPS device coordinates via Geolocator
/// - Computes H3 resolution 8 hexagonal cell index
/// - Upserts authoritative state to Supabase `public.partner_live_locations`
/// - Provides location freshness tracking for the intelligent assignment engine
class PartnerLocationService {
  PartnerLocationService._internal();

  static final PartnerLocationService instance = PartnerLocationService._internal();

  StreamSubscription<Position>? _positionStreamSub;
  Timer? _heartbeatTimer;
  Position? _lastKnownPosition;
  String? _activePartnerId;

  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isTracking => _positionStreamSub != null;

  /// Retrieves current real physical GPS position from device
  Future<Position?> getCurrentPosition({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[PartnerLocationService] GPS Location service is disabled on device.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[PartnerLocationService] Location permissions are denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[PartnerLocationService] Location permissions are permanently denied.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('[PartnerLocationService] Error acquiring current position: $e');
      return null;
    }
  }

  /// Synchronizes partner's live GPS coordinates & H3 index to Supabase backend
  Future<bool> syncLiveLocationToBackend({
    required String partnerId,
    Position? customPosition,
  }) async {
    if (partnerId.isEmpty) return false;

    final pos = customPosition ?? await getCurrentPosition();
    if (pos == null) return false;

    _lastKnownPosition = pos;
    final lat = pos.latitude;
    final lng = pos.longitude;
    final accuracy = pos.accuracy;

    // 1. Compute H3 Resolution 8 Hex Index (~460m edge)
    final h3Index = H3GeospatialService.instance.latLngToH3Index(lat, lng, resolution: 8);

    // 2. Persist to Supabase `partner_live_locations` table
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('partner_live_locations').upsert({
        'partner_id': partnerId,
        'latitude': lat,
        'longitude': lng,
        'h3_index_res8': h3Index,
        'accuracy': accuracy,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[PartnerLocationService] Successfully synced live location for partner $partnerId: ($lat, $lng, H3: $h3Index)');
    } catch (e) {
      debugPrint('[PartnerLocationService] Supabase partner_live_locations sync note: $e');
    }

    // 3. Sync to local cross-process IPC bridge for active bookings of this partner
    try {
      final activeList = LiveBookingSyncService.instance.getAllBookings();
      for (final b in activeList) {
        final bPartner = (b['partner_id'] ?? '').toString();
        if (bPartner == partnerId) {
          final bId = (b['booking_id'] ?? b['id'] ?? '').toString();
          if (bId.isNotEmpty) {
            LiveBookingSyncService.instance.updatePartnerLocation(bId, lat, lng);
          }
        }
      }
    } catch (_) {}

    return true;
  }

  /// Begins real-time location stream and periodic heartbeat sync
  void startLiveLocationTracking({required String partnerId}) {
    if (partnerId.isEmpty) return;
    _activePartnerId = partnerId;

    stopLiveLocationTracking();

    // 1. Initial immediate sync
    syncLiveLocationToBackend(partnerId: partnerId);

    // 2. High-accuracy location stream (triggers on 10m movement)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _lastKnownPosition = position;
          syncLiveLocationToBackend(
            partnerId: partnerId,
            customPosition: position,
          );
        },
        onError: (err) {
          debugPrint('[PartnerLocationService] Position stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('[PartnerLocationService] Could not start location stream: $e');
    }

    // 3. Periodic 30-second heartbeat to guarantee location freshness even when stationary
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_activePartnerId != null) {
        syncLiveLocationToBackend(partnerId: _activePartnerId!);
      }
    });
  }

  /// Stops tracking and clears subscriptions
  void stopLiveLocationTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
