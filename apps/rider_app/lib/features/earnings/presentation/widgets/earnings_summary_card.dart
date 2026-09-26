import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';

class EarningsSummaryCard extends StatelessWidget {
  final double totalEarnings;
  final int totalTrips;
  final double avgPerTrip;

  const EarningsSummaryCard({
    super.key,
    required this.totalEarnings,
    required this.totalTrips,
    required this.avgPerTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL EARNINGS',
            style: AppTypography.badgeText.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCurrency(totalEarnings),
                style: AppTypography.statNumber.copyWith(fontSize: 34),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'BDT',
                style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildMiniMetric('Completed Trips', '$totalTrips Trips', Icons.check_circle_outline_rounded, AppColors.dutyOnline),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMiniMetric('Avg per Trip', formatCurrency(avgPerTrip), Icons.insights_rounded, AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyBold,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
