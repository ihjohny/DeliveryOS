import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../store/domain/store_catalog_model.dart';
import '../../store/presentation/item_customizer_sheet.dart';
import '../../store/presentation/outlet_detail_screen.dart';
import '../domain/search_result_model.dart';
import '../providers/search_provider.dart';

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No matches found for "${_controller.text.trim()}"',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching for "Biryani", "Kacchi", or "Burger"',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
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
              _buildSuggestionChip("Sultan's Dine"),
              _buildSuggestionChip('Shwapno'),
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
          ...results.outlets.map((outlet) => _buildOutletCard(outlet)),
          const SizedBox(height: 16),
        ],

        // Dishes & Items Section
        if (results.items.isNotEmpty) ...[
          Text(
            'Dishes & Groceries (${results.items.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...results.items.map((item) => _buildItemCard(item)),
        ],
      ],
    );
  }

  Widget _buildOutletCard(SearchOutlet outlet) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outlet.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    outlet.addressText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${outlet.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(SearchItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
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
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: item.isInStock ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (!item.isInStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sold Out',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'from ${item.vendorName}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '৳${item.basePrice.toStringAsFixed(0)} / ${item.unitType}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: item.isInStock ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: item.isInStock
                          ? () {
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added $quantity x ${product.name} to cart'),
                                      backgroundColor: AppColors.secondary,
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        disabledBackgroundColor: AppColors.background,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                      child: Text(
                        item.isInStock ? 'ADD +' : 'UNAVAILABLE',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
