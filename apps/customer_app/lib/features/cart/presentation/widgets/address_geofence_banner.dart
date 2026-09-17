import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../location/presentation/map_location_picker_screen.dart';

class AddressGeofenceBanner extends StatelessWidget {
  final bool isWithinCoverage;
  final String currentAddress;
  final String? coverageError;
  final VoidCallback onAddressChanged;

  const AddressGeofenceBanner({
    super.key,
    required this.isWithinCoverage,
    required this.currentAddress,
    this.coverageError,
    required this.onAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWithinCoverage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Out of Delivery Coverage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              coverageError ??
                  'Selected address is outside this outlet\'s delivery coverage radius. Please choose an address within coverage.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.3),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MapLocationPickerScreen(isInitialOnboarding: false),
                    ),
                  );
                  onAddressChanged();
                },
                icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                label: const Text(
                  'Change Address',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delivering to: $currentAddress',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MapLocationPickerScreen(isInitialOnboarding: false),
                ),
              );
              onAddressChanged();
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
