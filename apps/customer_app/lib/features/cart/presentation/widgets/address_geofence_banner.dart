import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
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
        margin: AppSpacing.edgeInsetsVerticalSm,
        padding: AppSpacing.edgeInsetsMd,
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.errorBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Out of Delivery Coverage',
                    style: AppTypography.titleSmall.copyWith(
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
              style: AppTypography.bodySmall.copyWith(color: AppColors.errorText),
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
                label: Text(
                  'Change Address',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                  padding: AppSpacing.edgeInsetsHorizontalMd,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: AppSpacing.edgeInsetsVerticalSm,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.successDark, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Delivering to: $currentAddress',
              style: AppTypography.labelMedium.copyWith(color: AppColors.successText),
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
            child: Text(
              'Edit',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.successDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
