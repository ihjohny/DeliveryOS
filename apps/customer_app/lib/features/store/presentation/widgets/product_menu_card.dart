import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/store_catalog_model.dart';

/// Reusable product menu card displaying item details, stock availability,
/// formatted currency pricing, and an ADD / UNAVAILABLE button.
class ProductMenuCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const ProductMenuCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: product.isInStock ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (!product.isInStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          CurrencyFormatter.format(product.basePrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: product.isInStock ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: product.isInStock ? onAdd : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          disabledBackgroundColor: AppColors.background,
                          disabledForegroundColor: AppColors.textMuted,
                        ),
                        child: Text(
                          product.isInStock ? 'ADD +' : 'UNAVAILABLE',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
