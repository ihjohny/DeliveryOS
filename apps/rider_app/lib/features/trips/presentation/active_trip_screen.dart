import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/trip_models.dart';
import '../providers/trip_provider.dart';
import 'widgets/delivery_step_card.dart';
import 'widgets/handover_step_card.dart';
import 'widgets/pickup_step_card.dart';
import 'widgets/trip_timeline_header.dart';
import 'widgets/unreachable_bottom_sheet.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  bool _cashCollectedVerified = false;

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(riderTripProvider);
    final trip = tripState.activeTrip;

    if (trip == null) {
      final isCancelled = tripState.error != null &&
          (tripState.error!.toLowerCase().contains('cancel') ||
              tripState.error!.toLowerCase().contains('issue'));

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isCancelled ? 'Order Cancelled' : 'Trip Finished'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  color: isCancelled ? AppColors.error : AppColors.dutyOnline,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  isCancelled ? 'Order Cancelled' : 'Trip Completed Successfully!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                if (tripState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    tripState.error!,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentStep = trip.currentStep;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip ${trip.orderNumber}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            Text(
              trip.itemsSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.dutyOnlineBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dutyOnlineLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.dutyOnline),
                const SizedBox(width: 4),
                Text(
                  '+${formatCurrency(trip.payout)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.dutyOnline),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TripTimelineHeader(currentStep: currentStep),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (currentStep == TripStep.pickup)
                    PickupStepCard(
                      trip: trip,
                      isUpdating: tripState.isUpdating,
                      onConfirmPickup: () => ref.read(riderTripProvider.notifier).confirmPickup(),
                    )
                  else if (currentStep == TripStep.delivering)
                    DeliveryStepCard(
                      trip: trip,
                      onProceedToHandover: () => ref.read(riderTripProvider.notifier).proceedToHandover(),
                      onReportUnreachable: () => _handleShowUnreachable(trip),
                    )
                  else
                    HandoverStepCard(
                      trip: trip,
                      isUpdating: tripState.isUpdating,
                      cashCollectedVerified: _cashCollectedVerified,
                      onCashVerifiedChanged: (val) => setState(() => _cashCollectedVerified = val),
                      onCompleteDelivery: () => _handleCompleteDelivery(trip),
                      onReportIssue: () => _handleShowUnreachable(trip),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteDelivery(TripOrder trip) async {
    final success = await ref.read(riderTripProvider.notifier).completeDelivery(
          codCashCollected: _cashCollectedVerified,
          amountCollected: trip.isCod ? trip.totalAmount : 0.0,
        );

    if (mounted && success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery Completed! ${formatCurrency(trip.payout)} credited to your earnings.'),
          backgroundColor: AppColors.dutyOnline,
        ),
      );
    }
  }

  void _handleShowUnreachable(TripOrder trip) {
    showUnreachableBottomSheet(
      context: context,
      trip: trip,
      onReportIssue: (reason) async {
        final messenger = ScaffoldMessenger.of(context);
        final success = await ref.read(riderTripProvider.notifier).reportDeliveryIssue(reason: reason);
        if (mounted && success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Delivery issue reported to dispatch HQ. Order released.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      },
    );
  }
}
