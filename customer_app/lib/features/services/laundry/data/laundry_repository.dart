import 'package:supabase_flutter/supabase_flutter.dart';

class LaundryModel {
  final String serviceId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String status;

  const LaundryModel({
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.status,
  });

  factory LaundryModel.fromMap(Map<String, dynamic> map) {
    return LaundryModel(
      serviceId: map['service_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'laundry',
      name: map['name']?.toString() ?? 'Laundry Service',
      description: map['description']?.toString() ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 199.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 120,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class LaundryRepository {
  final SupabaseClient client;

  LaundryRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<LaundryModel>> getLaundryServices() async {
    try {
      final res = await client
          .from('services')
          .select()
          .eq('category_id', 'laundry')
          .eq('status', 'ACTIVE');
      return (res as List).map((e) => LaundryModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
