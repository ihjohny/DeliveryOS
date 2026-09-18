import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/native_launcher.dart';
import '../domain/trip_models.dart';
import '../providers/trip_provider.dart';

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
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Trip Finished')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.dutyOnline, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Trip Completed Successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return to Dashboard'),
              ),
            ],
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
                  '+৳${trip.payout.toStringAsFixed(0)}',
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
            // 3-Step Timeline Header
            _buildTimelineHeader(currentStep),

            // Step Content Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (currentStep == TripStep.pickup)
                    _buildStep1PickUp(trip, tripState)
                  else if (currentStep == TripStep.delivering)
                    _buildStep2Deliver(trip, tripState)
                  else
                    _buildStep3Handover(trip, tripState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineHeader(TripStep currentStep) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStepPill(
            stepNumber: 1,
            title: 'Pick Up',
            isActive: currentStep == TripStep.pickup,
            isCompleted: currentStep.stepNumber > 1,
          ),
          _buildStepDivider(isCompleted: currentStep.stepNumber > 1),
          _buildStepPill(
            stepNumber: 2,
            title: 'Deliver',
            isActive: currentStep == TripStep.delivering,
            isCompleted: currentStep.stepNumber > 2,
          ),
          _buildStepDivider(isCompleted: currentStep.stepNumber > 2),
          _buildStepPill(
            stepNumber: 3,
            title: 'Handover',
            isActive: currentStep == TripStep.handover,
            isCompleted: currentStep == TripStep.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    final bgColor = isCompleted
        ? AppColors.dutyOnline
        : isActive
            ? AppColors.primary
            : AppColors.background;
    final textColor = (isActive || isCompleted) ? Colors.white : AppColors.textSecondary;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: bgColor,
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isCompleted ? AppColors.dutyOnline : AppColors.border,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: PICK UP FOOD FROM STORE
  // ---------------------------------------------------------------------------
  Widget _buildStep1PickUp(TripOrder trip, RiderTripState tripState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Detail Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.store.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.store.address,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons: Directions & Call
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => openNativeTurnByTurnNavigation(trip.store.latitude, trip.store.longitude),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Directions to Store', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => makeDirectPhoneCall(trip.store.phone),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text('Call Store', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              if (trip.store.instructions != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.store.instructions!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Package Label Confirmation Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dutyOnlineBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dutyOnline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.dutyOnline, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOOK FOR PACKAGE BAG',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
                    ),
                    Text(
                      'Order ${trip.orderNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary Confirm Pickup CTA (height >= 56px)
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: tripState.isUpdating
                ? null
                : () async {
                    await ref.read(riderTripProvider.notifier).confirmPickup();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dutyOnline,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: tripState.isUpdating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.takeout_dining_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ORDER PICKED UP ➔ START DELIVERY',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: DELIVER FOOD TO CUSTOMER
  // ---------------------------------------------------------------------------
  Widget _buildStep2Deliver(TripOrder trip, RiderTripState tripState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dutyOnlineBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_pin_circle_rounded, color: AppColors.dutyOnline, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.customer.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.customer.address,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons: Directions & Call Customer
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => openNativeTurnByTurnNavigation(trip.customer.latitude, trip.customer.longitude),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Directions to Customer', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => makeDirectPhoneCall(trip.customer.phone),
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text('Call Customer', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              if (trip.customer.deliveryNotes != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: ${trip.customer.deliveryNotes!}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Arrived at Doorstep CTA
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => ref.read(riderTripProvider.notifier).proceedToHandover(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dutyOnline,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.door_front_door_rounded, size: 22),
                SizedBox(width: 8),
                Text(
                  'ARRIVED AT DOORSTEP ➔ HANDOVER',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: COMPLETE HANDOVER & COD VERIFICATION
  // ---------------------------------------------------------------------------
  Widget _buildStep3Handover(TripOrder trip, RiderTripState tripState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment Mode Banner
        if (trip.isCod) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warningBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.warning, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_rounded, color: AppColors.warning, size: 26),
                        SizedBox(width: 8),
                        Text(
                          'CASH ON DELIVERY',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.warning),
                        ),
                      ],
                    ),
                    Text(
                      '৳${trip.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please collect the exact cash amount shown above from the customer before releasing the food package.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 14),

                // Mandatory Cash Verification Checkbox
                InkWell(
                  onTap: () => setState(() => _cashCollectedVerified = !_cashCollectedVerified),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cashCollectedVerified ? AppColors.dutyOnline : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _cashCollectedVerified,
                          activeColor: AppColors.dutyOnline,
                          onChanged: (val) => setState(() => _cashCollectedVerified = val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'I have collected ৳${trip.totalAmount.toStringAsFixed(0)} in cash from customer',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dutyOnlineBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.dutyOnline, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.dutyOnline, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREPAID ONLINE ORDER',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.dutyOnline),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No cash to collect. Hand over food package to customer.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Complete Delivery CTA (height >= 56px)
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: tripState.isUpdating || (trip.isCod && !_cashCollectedVerified)
                ? null
                : () async {
                    final success = await ref.read(riderTripProvider.notifier).completeDelivery(
                          codCashCollected: _cashCollectedVerified,
                          amountCollected: trip.isCod ? trip.totalAmount : 0.0,
                        );

                    if (mounted && success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Delivery Completed! ৳${trip.payout.toStringAsFixed(0)} credited to your earnings.'),
                          backgroundColor: AppColors.dutyOnline,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dutyOnline,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: tripState.isUpdating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'COMPLETE DELIVERY',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
