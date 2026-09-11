import 'package:supabase_flutter/supabase_flutter.dart';

class UsernameAvailabilityService {
  /// Condition rules:
  /// - Minimum 6 characters
  /// - Numbers allowed
  /// - Allowed special characters ONLY: '_' and '.'
  /// - At most 1 special character allowed (more than 1 shows error)
  static bool isValidUsernameFormat(String username) {
    final clean = username.trim();
    if (clean.length < 6) return false;
    // Disallow any characters other than letters, digits, '_' and '.'
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(clean)) return false;
    // Count special characters
    final specialCount = RegExp(r'[_.]').allMatches(clean).length;
    if (specialCount > 1) return false;
    return true;
  }

  static List<String> generateSuggestions(String base) {
    var clean = base.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.length < 4) {
      clean = '${clean}partner';
    }

    final candidates = <String>[
      '${clean}_01',
      '$clean.pro',
      '${clean}_99',
      '$clean.hub',
      '${clean}_hub',
    ];

    return candidates.where((s) => isValidUsernameFormat(s)).take(4).toList();
  }

  static Future<bool> checkAvailabilityInSupabase(String username) async {
    final clean = username.trim().toLowerCase();
    if (!isValidUsernameFormat(clean)) return false;

    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('users')
          .select('username')
          .ilike('username', clean)
          .limit(1);
      return res.isEmpty;
    } catch (_) {
      return true; // Graceful offline fallback
    }
  }
}
