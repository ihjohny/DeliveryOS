import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/cart_item_model.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onMethodChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOption(
          method: PaymentMethod.cashOnDelivery,
          title: 'Cash on Delivery (COD)',
          subtitle: 'Pay with cash upon receipt',
          icon: Icons.money_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildOption(
          method: PaymentMethod.onlineCard,
          title: 'Online Card / Mobile Wallet',
          subtitle: 'Visa, Mastercard, bKash, Nagad',
          icon: Icons.credit_card_rounded,
        ),
      ],
    );
  }

  Widget _buildOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedMethod == method;
    return InkWell(
      onTap: () => onMethodChanged(method),
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.white,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: selectedMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) onMethodChanged(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
