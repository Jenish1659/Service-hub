import 'package:supabase_flutter/supabase_flutter.dart';

class CareTakerModel {
  final String serviceId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String status;

  const CareTakerModel({
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.status,
  });

  factory CareTakerModel.fromMap(Map<String, dynamic> map) {
    return CareTakerModel(
      serviceId: map['service_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'care_taker',
      name: map['name']?.toString() ?? 'Care Taker Service',
      description: map['description']?.toString() ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 599.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 480,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class CareTakerRepository {
  final SupabaseClient client;

  CareTakerRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<CareTakerModel>> getCareTakerServices() async {
    try {
      final res = await client
          .from('services')
          .select()
          .eq('category_id', 'care_taker')
          .eq('status', 'ACTIVE');
      return (res as List).map((e) => CareTakerModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
