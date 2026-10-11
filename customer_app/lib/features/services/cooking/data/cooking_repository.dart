import 'package:supabase_flutter/supabase_flutter.dart';

class CookingServiceModel {
  final String serviceId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String status;

  const CookingServiceModel({
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.status,
  });

  factory CookingServiceModel.fromMap(Map<String, dynamic> map) {
    return CookingServiceModel(
      serviceId: map['service_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'cooking',
      name: map['name']?.toString() ?? 'Cooking Service',
      description: map['description']?.toString() ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 399.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 90,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class CookingRepository {
  final SupabaseClient client;

  CookingRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<CookingServiceModel>> getCookingServices() async {
    try {
      final res = await client
          .from('services')
          .select()
          .eq('category_id', 'cooking')
          .eq('status', 'ACTIVE');
      return (res as List).map((e) => CookingServiceModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
