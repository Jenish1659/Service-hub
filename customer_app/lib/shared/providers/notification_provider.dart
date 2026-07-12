import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      read: json['read'] ?? false,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]) {
    _initStream();
  }

  void _initStream() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .listen((data) {
          final notifications = data.map((json) => AppNotification.fromJson(json)).toList();
          // Sort reverse chronological
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          state = notifications;
        });
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
      });
    } catch (e) {
      // Silently handle insertion errors during simulations
    }
  }

  Future<void> markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', user.id);
    } catch (e) {
      // Handle error
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});
