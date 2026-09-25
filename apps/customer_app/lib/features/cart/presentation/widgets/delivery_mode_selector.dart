import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/cart_item_model.dart';

class DeliveryModeSelector extends StatelessWidget {
  final DeliveryMethod selectedMethod;
  final ValueChanged<DeliveryMethod> onMethodChanged;
  final double deliveryFee;

  const DeliveryModeSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.deliveryFee = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              method: DeliveryMethod.homeDelivery,
              title: 'Home Delivery',
              subtitle: '${CurrencyFormatter.format(deliveryFee)} fee',
              icon: Icons.delivery_dining_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTab(
              method: DeliveryMethod.takeaway,
              title: 'Takeaway',
              subtitle: 'Free pickup',
              icon: Icons.shopping_bag_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required DeliveryMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedMethod == method;
    return InkWell(
      onTap: () => onMethodChanged(method),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
