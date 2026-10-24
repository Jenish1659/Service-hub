import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized service to launch the native device phone dialer
/// strictly dialing the authentic assigned partner or customer contact.
class PhoneLauncherService {
  /// Launches native phone dialer with tel: scheme.
  /// Strips formatting spaces/dashes while preserving leading '+'.
  static Future<bool> makePhoneCall(BuildContext context, String rawPhoneNumber) async {
    final cleanNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid contact phone number available for this booking.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch device dialer for $cleanNumber: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }
}
