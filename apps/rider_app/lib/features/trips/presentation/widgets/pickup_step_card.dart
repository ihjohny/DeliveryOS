import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/native_launcher.dart';
import '../../domain/trip_models.dart';

class PickupStepCard extends StatelessWidget {
  final TripOrder trip;
  final bool isUpdating;
  final Future<void> Function() onConfirmPickup;

  const PickupStepCard({
    super.key,
    required this.trip,
    required this.isUpdating,
    required this.onConfirmPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.store.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.store.address,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => openNativeTurnByTurnNavigation(trip.store.latitude, trip.store.longitude),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text(
                        'Directions to Store',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => makeDirectPhoneCall(trip.store.phone),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text(
                      'Call Store',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              if (trip.store.instructions != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.store.instructions!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dutyOnlineBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dutyOnline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.dutyOnline, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOOK FOR PACKAGE BAG',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
                    ),
                    Text(
                      'Order ${trip.orderNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isUpdating ? null : onConfirmPickup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dutyOnline,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isUpdating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.takeout_dining_rounded, size: 22),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'ORDER PICKED UP ➔ START DELIVERY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
