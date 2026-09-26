import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/native_launcher.dart';
import '../../domain/trip_models.dart';

class UnreachableBottomSheet extends StatefulWidget {
  final TripOrder trip;
  final Future<void> Function(String reason) onReportIssue;

  const UnreachableBottomSheet({
    super.key,
    required this.trip,
    required this.onReportIssue,
  });

  @override
  State<UnreachableBottomSheet> createState() => _UnreachableBottomSheetState();
}

class _UnreachableBottomSheetState extends State<UnreachableBottomSheet> {
  int _remainingSeconds = 300;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0 && mounted) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'Customer Unreachable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h2.copyWith(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _timer?.cancel();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Standard Operating Procedure:\n'
                '1. Call the customer at least twice.\n'
                '2. Ring the doorbell / knock at door.\n'
                '3. Wait minimum 5 minutes before reporting delivery failure.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warningBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SOP Wait Timer:',
                      style: AppTypography.bodyBold,
                    ),
                    Text(
                      '$minutes:$seconds',
                      style: AppTypography.h2.copyWith(
                        fontSize: 22,
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  _startTimer();
                  makeDirectPhoneCall(widget.trip.customer.phone);
                },
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: Text(
                  'Call Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderStrong),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () async {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                  await widget.onReportIssue('Customer unreachable at doorstep after 5 min wait');
                },
                icon: const Icon(Icons.report_problem_rounded, size: 18),
                label: Text(
                  'Report Unresponsive & Release Order',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showUnreachableBottomSheet({
  required BuildContext context,
  required TripOrder trip,
  required Future<void> Function(String reason) onReportIssue,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xxl)),
    ),
    builder: (_) => UnreachableBottomSheet(
      trip: trip,
      onReportIssue: onReportIssue,
    ),
  );
}
