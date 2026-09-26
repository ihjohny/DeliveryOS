import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/domain/duty_models.dart';

class CodCashLimitCard extends StatelessWidget {
  final RiderDutyState dutyState;
  final VoidCallback onDepositCash;

  const CodCashLimitCard({
    super.key,
    required this.dutyState,
    required this.onDepositCash,
  });

  @override
  Widget build(BuildContext context) {
    final usagePercent = (dutyState.cashLimitUsageRatio * 100).toInt();
    final isLimitReached = dutyState.isCashLimitReached;
    final isNearLimit = dutyState.isNearCashLimit;

    Color progressColor = AppColors.dutyOnline;
    if (isLimitReached) {
      progressColor = AppColors.error;
    } else if (isNearLimit) {
      progressColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLimitReached
              ? AppColors.error.withValues(alpha: 0.6)
              : (isNearLimit ? AppColors.warning.withValues(alpha: 0.6) : AppColors.border),
          width: isLimitReached ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, color: AppColors.warning, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'COD Cash in Hand',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyBold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isLimitReached
                      ? AppColors.errorBackground
                      : (isNearLimit ? AppColors.warningBackground : AppColors.dutyOnlineBackground),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  isLimitReached
                      ? 'LOCKED • COD BLOCKED'
                      : (isNearLimit ? 'CAUTION ($usagePercent%)' : 'SAFE ($usagePercent%)'),
                  style: AppTypography.badgeText.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: progressColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCurrency(dutyState.codCashInHand),
                style: AppTypography.statNumber.copyWith(
                  fontSize: 28,
                  color: isLimitReached ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              Text(
                'Limit: ${formatCurrency(dutyState.cashSafetyLimit)}',
                style: AppTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadius.roundedSm,
            child: LinearProgressIndicator(
              value: dutyState.cashLimitUsageRatio,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isLimitReached
                ? '⚠️ Cash safety limit reached! You are blocked from accepting new COD orders until cash is submitted at the central office.'
                : (isNearLimit
                    ? '⚠️ Nearing limit: ${formatCurrency(dutyState.remainingCashLimit)} remaining before COD orders are paused.'
                    : 'Safe limit remaining: ${formatCurrency(dutyState.remainingCashLimit)} before safety threshold.'),
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLimitReached ? AppColors.error : (isNearLimit ? AppColors.warning : AppColors.textSecondary),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: dutyState.codCashInHand <= 0 || dutyState.isDepositingCash
                ? null
                : onDepositCash,
            icon: dutyState.isDepositingCash
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.account_balance_rounded, size: 18),
            label: Text(
              dutyState.isDepositingCash ? 'PROCESSING DEPOSIT...' : 'DEPOSIT CASH AT HUB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.buttonText.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLimitReached ? AppColors.primary : AppColors.card,
              foregroundColor: isLimitReached ? AppColors.white : AppColors.primary,
              side: isLimitReached ? null : const BorderSide(color: AppColors.primary, width: 1.5),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
