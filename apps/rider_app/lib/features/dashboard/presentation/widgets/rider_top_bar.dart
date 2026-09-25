import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/auth_models.dart';

class RiderTopBar extends StatelessWidget {
  final RiderProfileData? profile;
  final VoidCallback onOpenEarnings;
  final VoidCallback onLogout;

  const RiderTopBar({
    super.key,
    required this.profile,
    required this.onOpenEarnings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
            child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile?.fullName ?? 'Rider Partner',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dutyOnlineBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            profile?.rating.toString() ?? '5.0',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _getVehicleIcon(profile?.vehicleType),
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile?.vehicleType.displayName ?? 'Motorcycle',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      profile?.phone ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
            tooltip: 'Earnings & COD Wallet',
            onPressed: onOpenEarnings,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Log Out',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(VehicleType? vehicle) {
    switch (vehicle) {
      case VehicleType.bicycle:
        return Icons.pedal_bike_rounded;
      case VehicleType.car:
        return Icons.directions_car_rounded;
      case VehicleType.motorcycle:
      default:
        return Icons.two_wheeler_rounded;
    }
  }
}
