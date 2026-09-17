import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
        const SizedBox(height: 8),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
