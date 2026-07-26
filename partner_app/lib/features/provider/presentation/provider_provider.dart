import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Stream all bookings that are currently waiting for acceptance ('Pending')
final providerPendingBookingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  try {
    final List<dynamic> response = await Supabase.instance.client
        .from('bookings')
        .select()
        .eq('status', 'Pending')
        .order('created_at', ascending: false);
    yield List<Map<String, dynamic>>.from(response);
  } catch (_) {
    yield [];
  }

  await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('status', 'Pending')
          .order('created_at', ascending: false);
      yield List<Map<String, dynamic>>.from(response);
    } catch (_) {}
  }
});

// Stream all ongoing bookings currently active for the provider ('En Route' or 'Started')
final providerActiveTasksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  try {
    final List<dynamic> response = await Supabase.instance.client
        .from('bookings')
        .select()
        .or('status.eq.En Route,status.eq.Started')
        .order('created_at', ascending: false);
    yield List<Map<String, dynamic>>.from(response);
  } catch (_) {
    yield [];
  }

  await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('bookings')
          .select()
          .or('status.eq.En Route,status.eq.Started')
          .order('created_at', ascending: false);
      yield List<Map<String, dynamic>>.from(response);
    } catch (_) {}
  }
});
