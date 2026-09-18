import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/domain/duty_models.dart';
import '../../dashboard/providers/duty_provider.dart';

enum EarningsTimeframe { today, week }

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  EarningsTimeframe _selectedTimeframe = EarningsTimeframe.today;

  @override
  Widget build(BuildContext context) {
    final dutyState = ref.watch(riderDutyProvider);
    final dutyNotifier = ref.read(riderDutyProvider.notifier);

    final isToday = _selectedTimeframe == EarningsTimeframe.today;
    final totalTrips = isToday ? dutyState.todayTrips : dutyState.weeklyTrips;
    final totalEarnings = isToday ? dutyState.todayEarnings : dutyState.weeklyEarnings;
    final avgPerTrip = totalTrips > 0 ? (totalEarnings / totalTrips) : 0.0;

    final now = DateTime.now();
    final tripsToShow = dutyState.completedTrips.where((trip) {
      if (isToday) {
        return trip.completedAt.year == now.year &&
            trip.completedAt.month == now.month &&
            trip.completedAt.day == now.day;
      } else {
        return trip.completedAt.isAfter(now.subtract(const Duration(days: 7)));
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Earnings & COD Wallet',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Timeframe Segmented Switch
            _buildTimeframeSelector(),
            const SizedBox(height: 16),

            // Top Earnings Summary Card
            _buildSummaryCard(totalEarnings, totalTrips, avgPerTrip),
            const SizedBox(height: 16),

            // COD Cash in Hand & Safety Limit Card
            _buildCodCashLimitCard(dutyState, dutyNotifier),
            const SizedBox(height: 20),

            // Section Header: Completed Trips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? 'TODAY\'S COMPLETED TRIPS' : 'THIS WEEK\'S COMPLETED TRIPS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${tripsToShow.length} Orders',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Trip History List
            if (tripsToShow.isEmpty)
              _buildEmptyTripsState()
            else
              ...tripsToShow.map(_buildTripItemCard),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
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
              onTap: () {
                setState(() => _selectedTimeframe = EarningsTimeframe.today);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTimeframe == EarningsTimeframe.today ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTimeframe == EarningsTimeframe.today
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _selectedTimeframe == EarningsTimeframe.today ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTimeframe = EarningsTimeframe.week);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTimeframe == EarningsTimeframe.week ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTimeframe == EarningsTimeframe.week
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _selectedTimeframe == EarningsTimeframe.week ? AppColors.primary : AppColors.textSecondary,
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

  Widget _buildSummaryCard(double totalEarnings, int totalTrips, double avgPerTrip) {
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
                '৳${totalEarnings.toStringAsFixed(0)}',
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
              _buildMiniMetric('Completed Trips', '$totalTrips Trips', Icons.check_circle_outline_rounded, AppColors.dutyOnline),
              _buildMiniMetric('Avg per Trip', '৳${avgPerTrip.toStringAsFixed(0)}', Icons.insights_rounded, AppColors.primary),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildCodCashLimitCard(RiderDutyState state, RiderDutyNotifier notifier) {
    final usagePercent = (state.cashLimitUsageRatio * 100).toInt();
    final isLimitReached = state.isCashLimitReached;
    final isNearLimit = state.isNearCashLimit;

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
              const Row(
                children: [
                  Icon(Icons.payments_rounded, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'COD Cash in Hand',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
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

          // Big Cash in Hand vs Max Limit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '৳${state.codCashInHand.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isLimitReached ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              Text(
                'Limit: ৳${state.cashSafetyLimit.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.cashLimitUsageRatio,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),

          // Remaining Headroom or Lock Message
          Text(
            isLimitReached
                ? '⚠️ Cash safety limit reached! You are blocked from accepting new COD orders until cash is submitted at the central office.'
                : (isNearLimit
                    ? '⚠️ Nearing limit: ৳${state.remainingCashLimit.toStringAsFixed(0)} remaining before COD orders are paused.'
                    : 'Safe limit remaining: ৳${state.remainingCashLimit.toStringAsFixed(0)} before safety threshold.'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLimitReached ? AppColors.error : (isNearLimit ? AppColors.warning : AppColors.textSecondary),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Action: Deposit Cash at Hub
          ElevatedButton.icon(
            onPressed: state.codCashInHand <= 0 || state.isDepositingCash
                ? null
                : () => _showCashDepositSheet(context, state, notifier),
            icon: state.isDepositingCash
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.account_balance_rounded, size: 18),
            label: Text(
              state.isDepositingCash ? 'PROCESSING DEPOSIT...' : 'DEPOSIT CASH AT HUB',
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

  void _showCashDepositSheet(BuildContext context, RiderDutyState state, RiderDutyNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Hub Cash Settlement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit your collected physical cash to the station cashier at your local hub counter to reset your COD safety limit.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 20),

              // Outstanding Cash Amount
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Outstanding Cash to Submit:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      '৳${state.codCashInHand.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Deposit Confirmation Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final success = await notifier.depositCashToHub();
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Full cash deposit registered. COD orders unlocked!'),
                          backgroundColor: AppColors.dutyOnline,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    'CONFIRM FULL DEPOSIT (৳${state.codCashInHand.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dutyOnline,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripItemCard(RiderCompletedTrip trip) {
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
              Row(
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
                  Text(
                    trip.orderNumber,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• $timeStr',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.dutyOnlineBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+৳${trip.payout.toStringAsFixed(0)}',
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
              Container(
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
                    Text(
                      trip.isCod ? 'COD Collected: ৳${trip.codCollected.toStringAsFixed(0)}' : 'Online Prepaid',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: trip.isCod ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildEmptyTripsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No Completed Deliveries Yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Your fulfilled orders and delivery payouts will appear here in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
