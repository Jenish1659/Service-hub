import 'package:supabase_flutter/supabase_flutter.dart';

class PlumbingServiceModel {
  final String serviceId;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String status;

  const PlumbingServiceModel({
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.status,
  });

  factory PlumbingServiceModel.fromMap(Map<String, dynamic> map) {
    return PlumbingServiceModel(
      serviceId: map['service_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'plumbing',
      name: map['name']?.toString() ?? 'Plumbing Service',
      description: map['description']?.toString() ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 249.0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 45,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class PlumbingRepository {
  final SupabaseClient client;

  PlumbingRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<List<PlumbingServiceModel>> getPlumbingServices() async {
    try {
      final res = await client
          .from('services')
          .select()
          .eq('category_id', 'plumbing')
          .eq('status', 'ACTIVE');
      return (res as List).map((e) => PlumbingServiceModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
