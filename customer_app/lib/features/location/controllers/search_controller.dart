import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_location_model.dart';
import '../services/location_search_service.dart';
import '../services/location_history_service.dart';

class LocationSearchState {
  final String query;
  final bool isSearching;
  final List<SearchLocationModel> results;
  final List<SearchLocationModel> recentSearches;
  final String? errorMessage;

  const LocationSearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.recentSearches = const [],
    this.errorMessage,
  });

  LocationSearchState copyWith({
    String? query,
    bool? isSearching,
    List<SearchLocationModel>? results,
    List<SearchLocationModel>? recentSearches,
    String? errorMessage,
  }) {
    return LocationSearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      errorMessage: errorMessage,
    );
  }
}

class LocationSearchController extends StateNotifier<LocationSearchState> {
  final LocationSearchService _searchService = LocationSearchService();
  final LocationHistoryService _historyService = LocationHistoryService();
  Timer? _debounceTimer;

  LocationSearchController() : super(const LocationSearchState()) {
    loadRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    final history = await _historyService.getRecentSearches();
    state = state.copyWith(recentSearches: history);
  }

  Future<void> selectAndSaveLocation(SearchLocationModel location) async {
    await _historyService.saveRecentSearch(location);
    await loadRecentSearches();
  }

  Future<void> clearHistory() async {
    await _historyService.clearRecentSearches();
    state = state.copyWith(recentSearches: []);
  }

  void onQueryChanged(String text) {
    state = state.copyWith(query: text);

    _debounceTimer?.cancel();
    if (text.trim().length < 2) {
      state = state.copyWith(isSearching: false, results: []);
      return;
    }

    state = state.copyWith(isSearching: true, errorMessage: null);

    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      try {
        final searchResults = await _searchService.searchLocation(text);
        state = state.copyWith(
          isSearching: false,
          results: searchResults,
          errorMessage: searchResults.isEmpty ? 'No locations found. Try searching a different city or area.' : null,
        );
      } catch (e) {
        state = state.copyWith(
          isSearching: false,
          results: [],
          errorMessage: 'Unable to fetch search results. Check your internet connection.',
        );
      }
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(query: '', isSearching: false, results: []);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
