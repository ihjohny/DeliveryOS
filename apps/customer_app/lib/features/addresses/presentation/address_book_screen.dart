import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../location/providers/location_provider.dart';
import '../domain/address_model.dart';
import '../providers/address_provider.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const AddressBookScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressProvider.notifier).loadAddresses();
    });
  }

  void _showAddEditAddressSheet({CustomerAddressModel? existingAddress}) {
    final labelOptions = ['Home', 'Work', 'Other'];
    String selectedLabel = existingAddress?.label ?? 'Home';
    final addressLineController = TextEditingController(text: existingAddress?.addressLine ?? '');
    final buildingFloorController = TextEditingController(text: existingAddress?.buildingFloor ?? '');
    final deliveryNoteController = TextEditingController(text: existingAddress?.deliveryNote ?? '');
    bool isDefault = existingAddress?.isDefault ?? false;

    // Default coords from current device location if new
    final currentLoc = ref.read(locationProvider).location;
    final lat = existingAddress?.latitude ?? currentLoc.latitude;
    final lng = existingAddress?.longitude ?? currentLoc.longitude;

    if (existingAddress == null && addressLineController.text.isEmpty) {
      addressLineController.text = currentLoc.addressLine;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existingAddress != null ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Label Chips
              const Text('Address Label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: labelOptions.map((l) {
                  final isSelected = selectedLabel == l;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedLabel = l);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Address Line
              const Text('Street Address & Area', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: addressLineController,
                decoration: InputDecoration(
                  hintText: 'e.g. House 42, Road 11, Banani, Dhaka',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Building / Floor
              const Text('Apartment / Building / Floor (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: buildingFloorController,
                decoration: InputDecoration(
                  hintText: 'e.g. Apt 4B, 4th Floor',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Delivery Note
              const Text('Delivery Instructions (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: deliveryNoteController,
                decoration: InputDecoration(
                  hintText: 'e.g. Call when outside, leave with security...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // Default toggle
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default delivery address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: isDefault,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setSheetState(() => isDefault = val ?? false);
                },
              ),
              const SizedBox(height: 14),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final line = addressLineController.text.trim();
                    if (line.isEmpty) return;

                    Navigator.pop(ctx);
                    if (existingAddress != null) {
                      await ref.read(addressProvider.notifier).updateAddress(
                            addressId: existingAddress.id,
                            label: selectedLabel,
                            addressLine: line,
                            buildingFloor: buildingFloorController.text.trim(),
                            deliveryNote: deliveryNoteController.text.trim(),
                            isDefault: isDefault,
                          );
                    } else {
                      await ref.read(addressProvider.notifier).createAddress(
                            label: selectedLabel,
                            addressLine: line,
                            buildingFloor: buildingFloorController.text.trim(),
                            deliveryNote: deliveryNoteController.text.trim(),
                            latitude: lat,
                            longitude: lng,
                            isDefault: isDefault,
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(existingAddress != null ? 'Update Address' : 'Save Address', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isSelectionMode ? 'Select Delivery Address' : 'Saved Addresses',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
            tooltip: 'Add Address',
            onPressed: () => _showAddEditAddressSheet(),
          ),
        ],
      ),
      body: addressState.isLoading && addressState.addresses.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : addressState.addresses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_off_rounded, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Saved Addresses',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your delivery locations for fast single-tap checkout.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditAddressSheet(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addressState.addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addressState.addresses[index];
                    final isSelected = addressState.selectedAddress?.id == address.id;

                    return InkWell(
                      onTap: () {
                        ref.read(addressProvider.notifier).selectAddress(address);
                        if (widget.isSelectionMode) {
                          Navigator.pop(context, address);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  address.label == 'Home'
                                      ? Icons.home_rounded
                                      : address.label == 'Work'
                                          ? Icons.business_rounded
                                          : Icons.place_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  address.label,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                                  onSelected: (val) {
                                    if (val == 'default') {
                                      ref.read(addressProvider.notifier).setDefaultAddress(address.id);
                                    } else if (val == 'edit') {
                                      _showAddEditAddressSheet(existingAddress: address);
                                    } else if (val == 'delete') {
                                      ref.read(addressProvider.notifier).deleteAddress(address.id);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (!address.isDefault)
                                      const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              address.addressLine,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            if (address.buildingFloor != null && address.buildingFloor!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                address.buildingFloor!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                            if (address.deliveryNote != null && address.deliveryNote!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address.deliveryNote!,
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
