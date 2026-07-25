import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final loggedInPartnerNameProvider = StateProvider<String>((ref) => 'ServiceHub Partner');

// Stream/Fetch profile details for the logged-in partner
final partnerProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response != null && response['name'] != null && (response['name'] as String).isNotEmpty) {
      ref.read(loggedInPartnerNameProvider.notifier).state = response['name'];
    }
        
    return response;
  } catch (_) {
    return null;
  }
});
