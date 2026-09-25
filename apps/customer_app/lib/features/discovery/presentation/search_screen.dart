import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/vendor_conflict_dialog.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../cart/providers/cart_provider.dart';
import '../../store/domain/store_catalog_model.dart';
import '../../store/presentation/item_customizer_sheet.dart';
import '../../store/presentation/outlet_detail_screen.dart';
import '../domain/search_result_model.dart';
import '../providers/search_provider.dart';
import 'widgets/search_item_card.dart';
import 'widgets/search_store_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final results = searchState.results;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () {
            ref.read(searchProvider.notifier).clearSearch();
            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search dishes, groceries, outlets...',
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchProvider.notifier).clearSearch();
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            ref.read(searchProvider.notifier).onQueryChanged(val);
            setState(() {});
          },
        ),
      ),
      body: searchState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : (results.outlets.isEmpty && results.items.isEmpty)
              ? _buildEmptyOrSuggestionsState()
              : _buildResultsList(results),
    );
  }

  Widget _buildEmptyOrSuggestionsState() {
    if (_controller.text.trim().isNotEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No matches found for "${_controller.text.trim()}"',
        message: 'Try searching for "Biryani", "Kacchi", or "Burger"',
      );
    }

    // Popular Quick Suggestions
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Searches',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Kacchi Biryani'),
              _buildSuggestionChip('Borhani'),
              _buildSuggestionChip('Beef Kebab'),
              _buildSuggestionChip('Fresh Milk'),
              _buildSuggestionChip('Chicken Biryani'),
              _buildSuggestionChip('Groceries'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return InkWell(
      onTap: () {
        _controller.text = label;
        ref.read(searchProvider.notifier).onQueryChanged(label);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildResultsList(SearchResult results) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Outlets Section
        if (results.outlets.isNotEmpty) ...[
          Text(
            'Stores & Restaurants (${results.outlets.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...results.outlets.map(
            (outlet) => SearchStoreCard(
              outlet: outlet,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OutletDetailScreen(
                      vendorId: outlet.id,
                      initialVendorName: outlet.name,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Dishes & Items Section
        if (results.items.isNotEmpty) ...[
          Text(
            'Dishes & Groceries (${results.items.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...results.items.map(
            (item) => SearchItemCard(
              item: item,
              onAdd: () => _openItemCustomizer(item),
            ),
          ),
        ],
      ],
    );
  }

  void _openItemCustomizer(SearchItem item) {
    final product = ProductModel(
      id: item.id,
      name: item.name,
      description: item.description,
      basePrice: item.basePrice,
      unitType: item.unitType,
      imageUrl: item.imageUrl,
      isInStock: item.isInStock,
    );

    ItemCustomizerSheet.show(
      context,
      product: product,
      onAddToCart: ({
        required product,
        selectedVariant,
        required selectedAddons,
        required quantity,
        specialInstructions,
        required totalPrice,
      }) {
        _handleAddToCart(
          item: item,
          product: product,
          selectedVariant: selectedVariant,
          selectedAddons: selectedAddons,
          quantity: quantity,
          specialInstructions: specialInstructions,
          unitPrice: totalPrice / quantity,
        );
      },
    );
  }

  void _handleAddToCart({
    required SearchItem item,
    required ProductModel product,
    required VariantModel? selectedVariant,
    required List<AddonModel> selectedAddons,
    required int quantity,
    required String? specialInstructions,
    required double unitPrice,
  }) {
    final result = ref.read(cartProvider.notifier).addItem(
          vendorId: item.vendorId,
          vendorName: item.vendorName,
          product: product,
          selectedVariant: selectedVariant,
          selectedAddons: selectedAddons,
          quantity: quantity,
          specialInstructions: specialInstructions,
          unitPrice: unitPrice,
        );

    if (result == AddToCartResult.vendorConflict) {
      showVendorConflictDialog(
        context: context,
        newVendorName: item.vendorName,
        onConfirmReplace: () {
          ref.read(cartProvider.notifier).addItem(
                vendorId: item.vendorId,
                vendorName: item.vendorName,
                product: product,
                selectedVariant: selectedVariant,
                selectedAddons: selectedAddons,
                quantity: quantity,
                specialInstructions: specialInstructions,
                unitPrice: unitPrice,
                forceReplace: true,
              );
          _showAddedSnackbar(product.name, quantity);
        },
      );
    } else {
      _showAddedSnackbar(product.name, quantity);
    }
  }

  void _showAddedSnackbar(String productName, int quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $quantity x $productName to cart'),
        backgroundColor: AppColors.secondary,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }
}
