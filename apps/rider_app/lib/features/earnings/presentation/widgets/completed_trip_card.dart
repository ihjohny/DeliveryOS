import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        trip.orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $timeStr',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.dutyOnlineBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${formatCurrency(trip.payout)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.dutyOnline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trip.storeName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            trip.customerAddress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trip.isCod ? 'COD Collected: ${formatCurrency(trip.codCollected)}' : 'Online Prepaid',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: trip.isCod ? AppColors.warning : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${trip.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
