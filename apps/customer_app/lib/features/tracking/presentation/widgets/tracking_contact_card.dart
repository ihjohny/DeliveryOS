import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class TrackingContactCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget? titleTrailing;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final bool isPrimaryAction;

  const TrackingContactCard({
    super.key,
    required this.leading,
    required this.title,
    this.titleTrailing,
    required this.subtitle,
    required this.actionLabel,
    this.actionIcon = Icons.call_rounded,
    required this.onAction,
    this.isPrimaryAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.edgeInsetsMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isPrimaryAction)
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 16),
              label: Text(
                actionLabel,
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 16),
              label: Text(
                actionLabel,
                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              ),
            ),
        ],
      ),
    );
  }
}
