import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../trips/domain/trip_models.dart';

class ActiveTripBanner extends StatelessWidget {
  final TripOrder trip;
  final VoidCallback onResumeTrip;

  const ActiveTripBanner({
    super.key,
    required this.trip,
    required this.onResumeTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: AppColors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'ACTIVE TRIP: ${trip.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.badgeText.copyWith(
                          fontSize: 13,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  trip.currentStep.stepTitle,
                  style: AppTypography.badgeText.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${trip.store.name} ➔ ${trip.customer.address}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              color: AppColors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onResumeTrip,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              'RESUME FULFILLMENT',
              style: AppTypography.buttonText.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}
