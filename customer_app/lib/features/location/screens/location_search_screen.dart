import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/location_provider.dart';
import '../widgets/search_result_card.dart';
import '../models/location_model.dart';
import '../../../../core/theme/app_theme.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(locationSearchProvider);
    final searchNotifier = ref.read(locationSearchProvider.notifier);

    final bool isQueryEmpty = _searchController.text.trim().isEmpty;

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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (val) {
              setState(() {});
              searchNotifier.onQueryChanged(val);
            },
            decoration: InputDecoration(
              hintText: 'Search city, area, or street name...',
              hintStyle: const TextStyle(color: Color(0xff94a3b8), fontSize: 14),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xff64748b), size: 20),
                      onPressed: () {
                        _searchController.clear();
                        searchNotifier.clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 15, color: Color(0xff0f172a), fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Use Current Location Bar
          InkWell(
            onTap: () async {
              final nav = Navigator.of(context);
              await ref.read(locationProvider.notifier).fetchCurrentGpsLocation();
              if (mounted) nav.pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xffeff6ff),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Using GPS device location',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 2. Body Area (Recent History vs Active Search Results)
          Expanded(
            child: searchState.isSearching
                ? const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor)),
                  )
                : isQueryEmpty && searchState.recentSearches.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'RECENT SEARCHES',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff64748b),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextButton(
                                  onPressed: searchNotifier.clearHistory,
                                  child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Color(0xffef4444))),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: searchState.recentSearches.length,
                              itemBuilder: (context, index) {
                                final item = searchState.recentSearches[index];
                                return SearchResultCard(
                                  result: item,
                                  onTap: () {
                                    final locationModel = LocationModel(
                                      latitude: item.latitude,
                                      longitude: item.longitude,
                                      address: item.displayAddress,
                                      city: item.name,
                                      area: item.name,
                                    );
                                    ref.read(locationProvider.notifier).setSelectedLocation(locationModel);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : searchState.errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                searchState.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                              ),
                            ),
                          )
                        : searchState.results.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48, color: Color(0xffcbd5e1)),
                                    SizedBox(height: 12),
                                    Text(
                                      'Search for a location, street, or city',
                                      style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: searchState.results.length,
                                itemBuilder: (context, index) {
                                  final item = searchState.results[index];
                                  return SearchResultCard(
                                    result: item,
                                    onTap: () async {
                                      await searchNotifier.selectAndSaveLocation(item);
                                      final locationModel = LocationModel(
                                        latitude: item.latitude,
                                        longitude: item.longitude,
                                        address: item.displayAddress,
                                        city: item.name,
                                        area: item.name,
                                      );
                                      ref.read(locationProvider.notifier).setSelectedLocation(locationModel);
                                      if (context.mounted) Navigator.pop(context);
                                    },
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
