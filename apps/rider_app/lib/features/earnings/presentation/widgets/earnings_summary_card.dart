import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
          const Text(
            'TOTAL EARNINGS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCurrency(totalEarnings),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              const Text(
                'BDT',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildMiniMetric('Completed Trips', '$totalTrips Trips', Icons.check_circle_outline_rounded, AppColors.dutyOnline),
              ),
              const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
