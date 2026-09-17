import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/banner_model.dart';

class BannerState {
  final List<BannerModel> banners;
  final bool isLoading;
  final String? error;

  BannerState({
    this.banners = const [],
    this.isLoading = false,
    this.error,
  });

  BannerState copyWith({
    List<BannerModel>? banners,
    bool? isLoading,
    String? error,
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BannerNotifier extends Notifier<BannerState> {
  @override
  BannerState build() {
    Future.microtask(() => fetchBanners());
    return BannerState(banners: BannerModel.pilotBanners, isLoading: false);
  }

  Future<void> fetchBanners() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(ApiConstants.activeBanners);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final banners = data
            .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
            .toList();
        if (banners.isNotEmpty) {
          state = state.copyWith(banners: banners, isLoading: false);
          return;
        }
      }
    } catch (_) {
      // Graceful fallback to pilot banners in offline / test environments
    }
    state = state.copyWith(banners: BannerModel.pilotBanners, isLoading: false);
  }
}

final bannerProvider =
    NotifierProvider<BannerNotifier, BannerState>(BannerNotifier.new);
