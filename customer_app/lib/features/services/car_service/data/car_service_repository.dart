import 'package:supabase_flutter/supabase_flutter.dart';

class CarServiceModel {
  final String serviceId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String status;

  const CarServiceModel({
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.status,
  });

  factory CarServiceModel.fromMap(Map<String, dynamic> map) {
    return CarServiceModel(
      serviceId: map['service_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'car_service',
      name: map['name']?.toString() ?? 'Car Service',
      description: map['description']?.toString() ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 499.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 60,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class CarServiceRepository {
  final SupabaseClient client;

  CarServiceRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<CarServiceModel>> getCarServices() async {
    try {
      final res = await client
          .from('services')
          .select()
          .eq('category_id', 'car_service')
          .eq('status', 'ACTIVE');
      return (res as List).map((e) => CarServiceModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
