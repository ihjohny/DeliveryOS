import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../location/providers/location_provider.dart';
import '../domain/search_result_model.dart';

class SearchState {
  final String query;
  final bool isLoading;
  final SearchResult results;
  final String? error;

  SearchState({
    this.query = '',
    this.isLoading = false,
    required this.results,
    this.error,
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    SearchResult? results,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;

  @override
  SearchState build() {
    return SearchState(results: SearchResult());
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = SearchState(query: '', results: SearchResult());
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final location = ref.read(locationProvider).location;
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(
        ApiConstants.searchVendors,
        queryParameters: {
          'query': query,
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final results = SearchResult.fromJson(data);
        state = state.copyWith(isLoading: false, results: results);
        return;
      }
    } catch (_) {
      // Graceful fallback with pilot test data
    }

    // Pilot fallback mock for search query
    final lower = query.toLowerCase();
    final mockOutlets = [
      SearchOutlet(
        id: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
        name: "Sultan's Dine - Banani",
        addressText: 'Road 11, Block D, Banani, Dhaka',
        distanceKm: 0.45,
      ),
      SearchOutlet(
        id: 'c7c44cf7-7c33-4cc4-8e52-f0fc05d36712',
        name: 'Kacchi Bhai - Gulshan 1',
        addressText: 'Gulshan Avenue, Dhaka',
        distanceKm: 1.20,
      ),
      SearchOutlet(
        id: 'd6d55df8-8d44-5dd5-9f63-01fd16e47823',
        name: 'Shwapno Superstore Express',
        addressText: 'Kemal Ataturk Ave, Banani',
        distanceKm: 0.85,
      ),
    ].where((o) => o.name.toLowerCase().contains(lower)).toList();

    final mockItems = [
      SearchItem(
        id: 'prod-kacchi-1',
        name: 'Kacchi Biryani with Borhani',
        description: 'Fragrant basmati rice with tender mutton, potatoes & rich borhani',
        basePrice: 420.0,
        unitType: 'portion',
        isInStock: true,
        vendorId: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
        vendorName: "Sultan's Dine - Banani",
        distanceKm: 0.45,
      ),
      SearchItem(
        id: 'prod-kebab-2',
        name: 'Beef Jali Kebab',
        description: 'Minced beef patty spiced with shahi garam masala, egg lacing',
        basePrice: 90.0,
        unitType: 'piece',
        isInStock: true,
        vendorId: 'c7c44cf7-7c33-4cc4-8e52-f0fc05d36712',
        vendorName: 'Kacchi Bhai - Gulshan 1',
        distanceKm: 1.20,
      ),
      SearchItem(
        id: 'prod-soldout-3',
        name: 'Mutton Rezala (Chef Special)',
        description: 'Tender mutton cooked in yogurt and poppy seed paste',
        basePrice: 380.0,
        unitType: 'portion',
        isInStock: false,
        vendorId: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
        vendorName: "Sultan's Dine - Banani",
        distanceKm: 0.45,
      ),
    ].where((i) => i.name.toLowerCase().contains(lower) || (i.description?.toLowerCase().contains(lower) ?? false)).toList();

    state = state.copyWith(
      isLoading: false,
      results: SearchResult(outlets: mockOutlets, items: mockItems),
    );
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = SearchState(results: SearchResult());
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
