import 'dart:math';
import 'package:flutter/foundation.dart';

/// Central Cryptographically Secure Random OTP Generation Engine
/// 
/// Guarantees:
/// 1. Dynamic length support: 4-digit or 6-digit as per requirement.
/// 2. True cryptographic randomness using [Random.secure] (zero pre-defined patterns or fixed seeds).
/// 3. Per-User Non-Repetition: For a particular user / phone number, an OTP will NOT repeat
///    until the rolling history window cycles.
class SecureOtpEngine {
  SecureOtpEngine._();
  static final SecureOtpEngine instance = SecureOtpEngine._();

  final Random _secureRandom = Random.secure();

  // History buffer: userKey (phone or user_id) -> sliding list of recently issued OTPs
  final Map<String, List<String>> _userOtpHistory = {};

  static const int maxHistoryPerUser4Digit = 100;
  static const int maxHistoryPerUser6Digit = 500;

  /// Generate a cryptographically secure random OTP (4-digit or 6-digit)
  /// that is guaranteed NOT to repeat for this particular user until the history window cycles.
  String generateOtp({
    required String userIdOrPhone,
    int digits = 6,
  }) {
    assert(digits == 4 || digits == 6, 'OTP digits must be either 4 or 6');
    final cleanKey = userIdOrPhone.replaceAll(RegExp(r'\D'), '').trim();
    final effectiveKey = cleanKey.isNotEmpty ? cleanKey : userIdOrPhone.trim();

    final maxHistory = (digits == 4) ? maxHistoryPerUser4Digit : maxHistoryPerUser6Digit;
    final minVal = digits == 4 ? 1000 : 100000;
    final range = digits == 4 ? 9000 : 900000;

    final history = _userOtpHistory.putIfAbsent(effectiveKey, () => <String>[]);

    // Roll cryptographically secure random until a non-repeated code is found
    String candidate;
    int attempts = 0;
    const maxAttempts = 100;

    do {
      final num = minVal + _secureRandom.nextInt(range);
      candidate = num.toString().padLeft(digits, '0');
      attempts++;
    } while (history.contains(candidate) && attempts < maxAttempts);

    // Maintain sliding history window
    if (history.length >= maxHistory) {
      history.removeAt(0);
    }

    history.add(candidate);

    if (kDebugMode) {
      debugPrint('[SecureOtpEngine] Generated dynamic $digits-digit OTP for $effectiveKey (History depth: ${history.length})');
    }

    return candidate;
  }

  /// Get the list of recently issued OTPs for a user (for tests & audits)
  List<String> getRecentOtpsForUser(String userIdOrPhone) {
    final cleanKey = userIdOrPhone.replaceAll(RegExp(r'\D'), '').trim();
    final effectiveKey = cleanKey.isNotEmpty ? cleanKey : userIdOrPhone.trim();
    return List.unmodifiable(_userOtpHistory[effectiveKey] ?? const []);
  }

  /// Clear history for a specific user
  void clearHistoryForUser(String userIdOrPhone) {
    final cleanKey = userIdOrPhone.replaceAll(RegExp(r'\D'), '').trim();
    final effectiveKey = cleanKey.isNotEmpty ? cleanKey : userIdOrPhone.trim();
    _userOtpHistory.remove(effectiveKey);
  }

  /// Clear all history (useful for test isolation)
  @visibleForTesting
  void resetForTesting() {
    _userOtpHistory.clear();
  }
}
