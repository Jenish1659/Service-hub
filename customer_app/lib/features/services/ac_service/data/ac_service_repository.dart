import 'package:supabase_flutter/supabase_flutter.dart';

class ACServiceModel {
  final String serviceId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String status;

  const ACServiceModel({
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.status,
  });

  factory ACServiceModel.fromMap(Map<String, dynamic> map) {
    return ACServiceModel(
      serviceId: map['service_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'ac_service',
      name: map['name']?.toString() ?? 'AC Service',
      description: map['description']?.toString() ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 499.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 60,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class ACServiceRepository {
  final SupabaseClient client;

  ACServiceRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<ACServiceModel>> getACServices() async {
    try {
      final res = await client
          .from('services')
          .select()
          .eq('category_id', 'ac_service')
          .eq('status', 'ACTIVE');
      return (res as List).map((e) => ACServiceModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
