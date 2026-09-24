import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/address_model.dart';

class AddressState {
  final List<CustomerAddressModel> addresses;
  final CustomerAddressModel? selectedAddress;
  final bool isLoading;
  final String? errorMessage;

  const AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.errorMessage,
  });

  AddressState copyWith({
    List<CustomerAddressModel>? addresses,
    CustomerAddressModel? selectedAddress,
    bool clearSelectedAddress = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: clearSelectedAddress ? null : (selectedAddress ?? this.selectedAddress),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AddressNotifier extends Notifier<AddressState> {
  @override
  AddressState build() {
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        loadAddresses();
      }
    });
    return const AddressState();
  }

  Future<void> loadAddresses() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(ApiConstants.customerAddresses);

      if (response.statusCode == 200) {
        final payload = response.data['data'] as List<dynamic>? ?? [];
        final list = payload
            .map((item) => CustomerAddressModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Default or first address is selected if none currently selected
        CustomerAddressModel? selected = state.selectedAddress;
        if (selected == null && list.isNotEmpty) {
          selected = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
        } else if (selected != null) {
          selected = list.firstWhere(
            (a) => a.id == selected?.id,
            orElse: () => list.isNotEmpty ? list.first : selected!,
          );
        }

        state = state.copyWith(
          addresses: list,
          selectedAddress: selected,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to load addresses',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectAddress(CustomerAddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<bool> createAddress({
    required String label,
    required String addressLine,
    String? buildingFloor,
    String? deliveryNote,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(
        ApiConstants.customerAddresses,
        data: {
          'label': label,
          'addressLine': addressLine,
          if (buildingFloor != null && buildingFloor.isNotEmpty) 'buildingFloor': buildingFloor,
          if (deliveryNote != null && deliveryNote.isNotEmpty) 'deliveryNote': deliveryNote,
          'latitude': latitude,
          'longitude': longitude,
          'isDefault': isDefault,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadAddresses();
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to create address',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAddress({
    required String addressId,
    String? label,
    String? addressLine,
    String? buildingFloor,
    String? deliveryNote,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.put(
        '${ApiConstants.customerAddresses}/$addressId',
        data: {
          if (label != null) 'label': label,
          if (addressLine != null) 'addressLine': addressLine,
          if (buildingFloor != null) 'buildingFloor': buildingFloor,
          if (deliveryNote != null) 'deliveryNote': deliveryNote,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (isDefault != null) 'isDefault': isDefault,
        },
      );

      if (response.statusCode == 200) {
        await loadAddresses();
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to update address',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.delete('${ApiConstants.customerAddresses}/$addressId');

      if (response.statusCode == 200) {
        await loadAddresses();
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to delete address',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.patch('${ApiConstants.customerAddresses}/$addressId/default');

      if (response.statusCode == 200) {
        await loadAddresses();
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to set default address',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final addressProvider = NotifierProvider<AddressNotifier, AddressState>(AddressNotifier.new);
