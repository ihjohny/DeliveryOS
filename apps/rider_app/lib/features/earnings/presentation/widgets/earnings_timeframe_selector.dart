import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum EarningsTimeframe { today, week }

class EarningsTimeframeSelector extends StatelessWidget {
  final EarningsTimeframe selectedTimeframe;
  final ValueChanged<EarningsTimeframe> onTimeframeChanged;

  const EarningsTimeframeSelector({
    super.key,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTimeframeChanged(EarningsTimeframe.today),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTimeframe == EarningsTimeframe.today ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedTimeframe == EarningsTimeframe.today
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Today',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selectedTimeframe == EarningsTimeframe.today ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTimeframeChanged(EarningsTimeframe.week),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTimeframe == EarningsTimeframe.week ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedTimeframe == EarningsTimeframe.week
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'This Week',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selectedTimeframe == EarningsTimeframe.week ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
