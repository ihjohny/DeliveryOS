import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../dashboard/providers/duty_provider.dart';
import 'widgets/cod_cash_limit_card.dart';
import 'widgets/completed_trip_card.dart';
import 'widgets/earnings_summary_card.dart';
import 'widgets/earnings_timeframe_selector.dart';
import 'widgets/hub_cash_deposit_sheet.dart';

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  EarningsTimeframe _selectedTimeframe = EarningsTimeframe.today;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderDutyProvider.notifier).fetchDailyTrips());
  }

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
        child: RefreshIndicator(
          onRefresh: () => ref.read(riderDutyProvider.notifier).fetchDailyTrips(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              EarningsTimeframeSelector(
                selectedTimeframe: _selectedTimeframe,
                onTimeframeChanged: (tf) => setState(() => _selectedTimeframe = tf),
              ),
              const SizedBox(height: 16),
              EarningsSummaryCard(
                totalEarnings: totalEarnings,
                totalTrips: totalTrips,
                avgPerTrip: avgPerTrip,
              ),
              const SizedBox(height: 16),
              CodCashLimitCard(
                dutyState: dutyState,
                onDepositCash: () => _handleDepositCash(context, dutyNotifier),
              ),
              const SizedBox(height: 20),
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
              if (tripsToShow.isEmpty)
                const EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: 'No Completed Deliveries Yet',
                  message: 'Your fulfilled orders and delivery payouts will appear here in real-time.',
                )
              else
                ...tripsToShow.map((trip) => CompletedTripCard(trip: trip)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDepositCash(BuildContext context, RiderDutyNotifier notifier) {
    final dutyState = ref.read(riderDutyProvider);
    showHubCashDepositSheet(
      context: context,
      dutyState: dutyState,
      onConfirmDeposit: () async {
        final success = await notifier.depositCashToHub();
        if (context.mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Full cash deposit registered. COD orders unlocked!'),
              backgroundColor: AppColors.dutyOnline,
            ),
          );
        }
      },
    );
  }
}
