import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../domain/auth_models.dart';

class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selectedVehicle;
  final ValueChanged<VehicleType> onVehicleSelected;

  const VehicleTypeSelector({
    super.key,
    required this.selectedVehicle,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOption(
          type: VehicleType.motorcycle,
          icon: Icons.two_wheeler_rounded,
          label: 'Motorcycle',
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildOption(
          type: VehicleType.bicycle,
          icon: Icons.pedal_bike_rounded,
          label: 'Bicycle',
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildOption(
          type: VehicleType.car,
          icon: Icons.directions_car_rounded,
          label: 'Car',
        ),
      ],
    );
  }

  Widget _buildOption({
    required VehicleType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedVehicle == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onVehicleSelected(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.1) : AppColors.background,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
