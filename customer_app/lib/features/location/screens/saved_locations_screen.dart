import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/customer_location_model.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import 'map_screen.dart';
import '../../../../core/theme/app_theme.dart';

class SavedLocationsScreen extends ConsumerStatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  ConsumerState<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends ConsumerState<SavedLocationsScreen> {
  List<CustomerLocationModel> _savedLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    setState(() {
      _isLoading = true;
    });
    final apiService = ref.read(locationApiServiceProvider);
    final list = await apiService.getAllSavedLocations();

    if (mounted) {
      setState(() {
        _savedLocations = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLocation(String id) async {
    final apiService = ref.read(locationApiServiceProvider);
    await apiService.deleteLocation(id);
    _loadSavedLocations();
  }

  void _selectLocation(CustomerLocationModel item) {
    final locationModel = LocationModel(
      latitude: item.latitude,
      longitude: item.longitude,
      address: item.address,
      area: item.area,
      city: item.city,
      state: item.state,
      country: item.country,
      postalCode: item.postalCode,
    );
    ref.read(locationProvider.notifier).setSelectedLocation(locationModel);
    Navigator.pop(context, locationModel);
  }

  IconData _getIconForTag(AddressType type) {
    switch (type) {
      case AddressType.home:
        return Icons.home;
      case AddressType.work:
        return Icons.work;
      case AddressType.parents:
        return Icons.family_restroom;
      case AddressType.friends:
        return Icons.people;
      case AddressType.other:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          title: const Text(
            'Saved Addresses',
            style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.bold, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xff0f172a)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                  _loadSavedLocations();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_location_alt, color: AppTheme.primaryColor, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add New Service Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xff94a3b8)),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedLocations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xffeff6ff),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bookmark_border, size: 40, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Saved Addresses Yet',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Save your home, office or recipient locations for fast booking',
                                style: TextStyle(fontSize: 13, color: Color(0xff64748b)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _savedLocations.length,
                          itemBuilder: (context, index) {
                            final item = _savedLocations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xffeff6ff),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_getIconForTag(item.addressType), color: AppTheme.primaryColor, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          item.addressType.name.toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff0f172a)),
                                        ),
                                        if (item.isForSomeoneElse) ...[
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xfffef3c7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'For: ${item.recipientName ?? "Other"}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xffd97706)),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Color(0xffef4444), size: 20),
                                          onPressed: () => _deleteLocation(item.id),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        '${item.houseNumber != null && item.houseNumber!.isNotEmpty ? "${item.houseNumber}, " : ""}${item.address}',
                                        style: const TextStyle(fontSize: 13, color: Color(0xff334155), height: 1.3),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppTheme.primaryColor),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _selectLocation(item),
                                        child: const Text(
                                          'Deliver / Service Here',
                                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
