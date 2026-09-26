import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';

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
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTimeframeChanged(EarningsTimeframe.today),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTimeframe == EarningsTimeframe.today ? AppColors.card : AppColors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedTimeframe == EarningsTimeframe.today
                      ? [BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Today',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBold.copyWith(
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
                  color: selectedTimeframe == EarningsTimeframe.week ? AppColors.card : AppColors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedTimeframe == EarningsTimeframe.week
                      ? [BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'This Week',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBold.copyWith(
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
