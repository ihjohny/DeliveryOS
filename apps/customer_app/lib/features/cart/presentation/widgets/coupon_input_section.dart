import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/currency_formatter.dart';

class CouponInputSection extends StatefulWidget {
  final String? appliedCoupon;
  final double couponDiscount;
  final bool isLoading;
  final String? message;
  final ValueChanged<String> onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  const CouponInputSection({
    super.key,
    this.appliedCoupon,
    this.couponDiscount = 0.0,
    this.isLoading = false,
    this.message,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  @override
  State<CouponInputSection> createState() => _CouponInputSectionState();
}

class _CouponInputSectionState extends State<CouponInputSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code "${widget.appliedCoupon}" Applied',
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    'Saved ${CurrencyFormatter.format(widget.couponDiscount)} on your order',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
              tooltip: 'Remove Coupon',
              onPressed: () {
                _controller.clear();
                widget.onRemoveCoupon();
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon (e.g. WELCOME50)',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: widget.isLoading
                    ? null
                    : () {
                        if (_controller.text.trim().isNotEmpty) {
                          widget.onApplyCoupon(_controller.text.trim());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                  padding: AppSpacing.edgeInsetsHorizontalLg,
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(
                        'Apply',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.message!,
            style: AppTypography.labelSmall.copyWith(
              color: widget.message!.contains('applied') ? AppColors.secondary : AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
