import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/store_catalog_model.dart';

final storeCatalogProvider =
    FutureProvider.family<VendorCatalog, String>((ref, vendorId) async {
  try {
    final dio = ref.watch(dioClientProvider);
    final response = await dio.get(ApiConstants.vendorCatalog(vendorId));
    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return VendorCatalog.fromJson(data);
    }
  } catch (_) {
    // Graceful pilot fallback in offline or test mode
  }
  return VendorCatalog.pilotSultansDine();
});
