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
          'q': query,
          'lat': location.latitude,
          'lng': location.longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final results = SearchResult.fromJson(data);
        state = state.copyWith(isLoading: false, results: results, error: null);
        return;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        results: SearchResult(),
        error: 'Unable to perform search. Please check your connection.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      results: SearchResult(),
    );
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = SearchState(results: SearchResult());
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
