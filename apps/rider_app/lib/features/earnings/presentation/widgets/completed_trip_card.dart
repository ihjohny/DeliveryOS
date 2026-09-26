import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/domain/duty_models.dart';

class CompletedTripCard extends StatelessWidget {
  final RiderCompletedTrip trip;

  const CompletedTripCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${trip.completedAt.hour.toString().padLeft(2, '0')}:${trip.completedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        trip.orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyBold.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $timeStr',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.dutyOnlineBackground,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  '+${formatCurrency(trip.payout)}',
                  style: AppTypography.badgeText.copyWith(fontSize: 12, color: AppColors.dutyOnline),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            trip.storeName,
            style: AppTypography.bodyBold,
          ),
          const SizedBox(height: 2),
          Text(
            trip.customerAddress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: trip.isCod ? AppColors.warningBackground : AppColors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trip.isCod ? Icons.payments_rounded : Icons.credit_card_rounded,
                        size: 13,
                        color: trip.isCod ? AppColors.warning : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          trip.isCod ? 'COD Collected: ${formatCurrency(trip.codCollected)}' : 'Online Prepaid',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.badgeText.copyWith(
                            fontSize: 10,
                            color: trip.isCod ? AppColors.warning : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${trip.distanceKm.toStringAsFixed(1)} km',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
