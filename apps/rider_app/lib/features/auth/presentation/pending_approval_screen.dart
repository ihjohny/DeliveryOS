import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../../dashboard/presentation/rider_dashboard_screen.dart';
import '../domain/auth_models.dart';
import '../providers/auth_provider.dart';
import 'phone_login_screen.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(riderAuthProvider);
    final profile = authState.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.warningBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Account Pending Approval',
                        textAlign: TextAlign.center,
                        style: AppTypography.h2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.warningBackground,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          'STATUS: PENDING_APPROVAL',
                          style: AppTypography.badgeText.copyWith(color: AppColors.warning),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Welcome ${profile?.fullName ?? "Rider"}! Your application to join DeliveryOS is currently under review by our operations team.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Rider Name', profile?.fullName ?? 'New Applicant'),
                            const Divider(height: AppSpacing.lg, color: AppColors.border),
                            _buildDetailRow('Mobile Phone', profile?.phone ?? authState.phoneNumber ?? '-'),
                            const Divider(height: AppSpacing.lg, color: AppColors.border),
                            _buildDetailRow('Vehicle Type', profile?.vehicleType.displayName ?? 'Motorcycle'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorBackground,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Duty Switch is locked until account approval per fleet safety compliance.',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await ref.read(riderAuthProvider.notifier).refreshApprovalStatus();
                            final updated = ref.read(riderAuthProvider);
                            if (context.mounted && updated.isAuthenticated) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
                                (route) => false,
                              );
                            }
                          },
                    icon: authState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'Check Approval Status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.buttonText.copyWith(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (kDebugMode) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(riderAuthProvider.notifier).forceApproveForDev();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.dutyOnline),
                    label: Text(
                      'Simulate Admin Approval (Dev Mode)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyBold.copyWith(fontSize: 13, color: AppColors.dutyOnline),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.dutyOnline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                TextButton.icon(
                  onPressed: () async {
                    await ref.read(riderAuthProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textSecondary),
                  label: Text('Log Out', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyBold.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
