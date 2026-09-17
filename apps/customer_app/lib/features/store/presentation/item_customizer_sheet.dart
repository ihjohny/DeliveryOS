import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/store_catalog_model.dart';

class ItemCustomizerSheet extends StatefulWidget {
  final ProductModel product;
  final void Function({
    required ProductModel product,
    VariantModel? selectedVariant,
    required List<AddonModel> selectedAddons,
    required int quantity,
    String? specialInstructions,
    required double totalPrice,
  })? onAddToCart;

  const ItemCustomizerSheet({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    void Function({
      required ProductModel product,
      VariantModel? selectedVariant,
      required List<AddonModel> selectedAddons,
      required int quantity,
      String? specialInstructions,
      required double totalPrice,
    })? onAddToCart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemCustomizerSheet(
        product: product,
        onAddToCart: onAddToCart,
      ),
    );
  }

  @override
  State<ItemCustomizerSheet> createState() => _ItemCustomizerSheetState();
}

class _ItemCustomizerSheetState extends State<ItemCustomizerSheet> {
  VariantModel? _selectedVariant;
  final Set<AddonModel> _selectedAddons = {};
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to first in-stock variant if available
    if (widget.product.variants.isNotEmpty) {
      final available = widget.product.variants.where((v) => v.isInStock);
      if (available.isNotEmpty) {
        _selectedVariant = available.first;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    final base = _selectedVariant?.price ?? widget.product.basePrice;
    final addonsTotal = _selectedAddons.fold<double>(0.0, (sum, a) => sum + a.price);
    return base + addonsTotal;
  }

  double get _totalPrice => _unitPrice * _quantity;

  bool get _canAddToCart {
    if (!widget.product.isInStock) return false;
    if (widget.product.variants.isNotEmpty && _selectedVariant == null) return false;
    return true;
  }

  void _handleAddToCart() {
    if (!_canAddToCart) return;
    widget.onAddToCart?.call(
      product: widget.product,
      selectedVariant: _selectedVariant,
      selectedAddons: _selectedAddons.toList(),
      quantity: _quantity,
      specialInstructions: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      totalPrice: _totalPrice,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Close Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Product Title & Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '৳${product.basePrice.toStringAsFixed(0)} / ${product.unitType}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!product.isInStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sold Out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),

                if (product.description != null && product.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],

                const Divider(height: 28, color: AppColors.border),

                // Variant Single-Choice Radio Group
                if (product.variants.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choose Portion / Variant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REQUIRED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...product.variants.map((variant) {
                    final isSelected = _selectedVariant?.id == variant.id;
                    return InkWell(
                      onTap: variant.isInStock
                          ? () => setState(() => _selectedVariant = variant)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<VariantModel>(
                              value: variant,
                              groupValue: _selectedVariant,
                              activeColor: AppColors.primary,
                              onChanged: variant.isInStock
                                  ? (val) => setState(() => _selectedVariant = val)
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                variant.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: variant.isInStock ? AppColors.textPrimary : AppColors.textMuted,
                                  decoration: variant.isInStock ? null : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            Text(
                              variant.isInStock ? '৳${variant.price.toStringAsFixed(0)}' : 'Unavailable',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: variant.isInStock ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 24, color: AppColors.border),
                ],

                // Toppings & Add-on Checkbox Groups
                if (product.addonGroups.isNotEmpty) ...[
                  ...product.addonGroups.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...group.addons.map((addon) {
                          final isChecked = _selectedAddons.any((a) => a.id == addon.id);
                          return InkWell(
                            onTap: addon.isInStock
                                ? () {
                                    setState(() {
                                      if (isChecked) {
                                        _selectedAddons.removeWhere((a) => a.id == addon.id);
                                      } else {
                                        if (_selectedAddons.length < group.maxSelections) {
                                          _selectedAddons.add(addon);
                                        }
                                      }
                                    });
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isChecked ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isChecked ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: AppColors.primary,
                                    onChanged: addon.isInStock
                                        ? (val) {
                                            setState(() {
                                              if (val == true) {
                                                if (_selectedAddons.length < group.maxSelections) {
                                                  _selectedAddons.add(addon);
                                                }
                                              } else {
                                                _selectedAddons.removeWhere((a) => a.id == addon.id);
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      addon.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: addon.isInStock ? AppColors.textPrimary : AppColors.textMuted,
                                        decoration: addon.isInStock ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    addon.isInStock ? '+৳${addon.price.toStringAsFixed(0)}' : 'Unavailable',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: addon.isInStock ? AppColors.primary : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const Divider(height: 24, color: AppColors.border),
                      ],
                    );
                  }),
                ],

                // Special Kitchen Instructions
                const Text(
                  'Special Instructions for the Kitchen',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Less spicy, extra sauce, separate packaging...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Action Bar: Quantity & Real-Time Price CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Quantity Increment/Decrement
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          onPressed: (_quantity > 1 && _canAddToCart)
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          onPressed: _canAddToCart
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Add to Cart CTA with Dynamic Total Price
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _canAddToCart ? _handleAddToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _canAddToCart ? 'Add to Cart' : 'Currently Unavailable',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_canAddToCart)
                              Text(
                                '৳${_totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
