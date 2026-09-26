import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'COD Cash in Hand',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLimitReached
                      ? AppColors.errorBackground
                      : (isNearLimit ? AppColors.warningBackground : AppColors.dutyOnlineBackground),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLimitReached
                      ? 'LOCKED • COD BLOCKED'
                      : (isNearLimit ? 'CAUTION ($usagePercent%)' : 'SAFE ($usagePercent%)'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: progressColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCurrency(dutyState.codCashInHand),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isLimitReached ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              Text(
                'Limit: ${formatCurrency(dutyState.cashSafetyLimit)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: dutyState.cashLimitUsageRatio,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLimitReached
                ? '⚠️ Cash safety limit reached! You are blocked from accepting new COD orders until cash is submitted at the central office.'
                : (isNearLimit
                    ? '⚠️ Nearing limit: ${formatCurrency(dutyState.remainingCashLimit)} remaining before COD orders are paused.'
                    : 'Safe limit remaining: ${formatCurrency(dutyState.remainingCashLimit)} before safety threshold.'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLimitReached ? AppColors.error : (isNearLimit ? AppColors.warning : AppColors.textSecondary),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: dutyState.codCashInHand <= 0 || dutyState.isDepositingCash
                ? null
                : onDepositCash,
            icon: dutyState.isDepositingCash
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.account_balance_rounded, size: 18),
            label: Text(
              dutyState.isDepositingCash ? 'PROCESSING DEPOSIT...' : 'DEPOSIT CASH AT HUB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLimitReached ? AppColors.primary : AppColors.card,
              foregroundColor: isLimitReached ? Colors.white : AppColors.primary,
              side: isLimitReached ? null : const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
