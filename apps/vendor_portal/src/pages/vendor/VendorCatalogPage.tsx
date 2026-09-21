import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Layers,
  Search,
  CheckCircle2,
  XCircle,
  Tag,
  RefreshCw,
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useVendorOutlet } from '../../contexts/VendorOutletContext';
import kdsApi from '../../services/kdsApi';
import { OutletCatalog } from '../../types/kds';
import { Input } from '../../components/ui/Input';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export const VendorCatalogPage: React.FC = () => {
  const { user } = useAuth();
  const { activeOutletId, outlets } = useVendorOutlet();
  const queryClient = useQueryClient();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');

  const vendorId =
    activeOutletId && activeOutletId !== 'ALL'
      ? activeOutletId
      : outlets[0]?.id || user?.vendorId || '';

  const { data: catalog, isLoading, refetch } = useQuery<OutletCatalog>({
    queryKey: ['vendor-catalog', vendorId],
    queryFn: () => kdsApi.getOutletCatalog(vendorId),
    enabled: !!vendorId,
  });

  // Product Stock Mutation
  const productStockMutation = useMutation({
    mutationFn: ({ productId, isInStock }: { productId: string; isInStock: boolean }) =>
      kdsApi.toggleProductStock(productId, isInStock),
    onMutate: async ({ productId, isInStock }) => {
      await queryClient.cancelQueries({ queryKey: ['vendor-catalog', vendorId] });
      const previous = queryClient.getQueryData<OutletCatalog>(['vendor-catalog', vendorId]);

      if (previous) {
        queryClient.setQueryData<OutletCatalog>(['vendor-catalog', vendorId], {
          ...previous,
          categories: previous.categories.map((cat) => ({
            ...cat,
            products: cat.products.map((p) =>
              p.id === productId ? { ...p, isInStock } : p
            ),
          })),
        });
      }
      return { previous };
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        queryClient.setQueryData(['vendor-catalog', vendorId], context.previous);
      }
    },
  });

  // Variant Stock Mutation
  const variantStockMutation = useMutation({
    mutationFn: ({ variantId, isInStock }: { variantId: string; isInStock: boolean }) =>
      kdsApi.toggleVariantStock(variantId, isInStock),
    onMutate: async ({ variantId, isInStock }) => {
      await queryClient.cancelQueries({ queryKey: ['vendor-catalog', vendorId] });
      const previous = queryClient.getQueryData<OutletCatalog>(['vendor-catalog', vendorId]);

      if (previous) {
        queryClient.setQueryData<OutletCatalog>(['vendor-catalog', vendorId], {
          ...previous,
          categories: previous.categories.map((cat) => ({
            ...cat,
            products: cat.products.map((p) => ({
              ...p,
              variants: p.variants.map((v) =>
                v.id === variantId ? { ...v, isInStock } : v
              ),
            })),
          })),
        });
      }
      return { previous };
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        queryClient.setQueryData(['vendor-catalog', vendorId], context.previous);
      }
    },
  });

  // Compute counts
  const categories = catalog?.categories || [];
  const allProducts = categories.flatMap((c) => c.products);
  const totalInStock = allProducts.filter((p) => p.isInStock).length;
  const totalOutOfStock = allProducts.filter((p) => !p.isInStock).length;

  // Filter products by category and search
  const filteredCategories = categories
    .map((cat) => {
      if (selectedCategory !== 'ALL' && cat.id !== selectedCategory) {
        return null;
      }
      const matchingProducts = cat.products.filter(
        (p) =>
          p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          p.description?.toLowerCase().includes(searchQuery.toLowerCase())
      );
      return { ...cat, products: matchingProducts };
    })
    .filter((cat): cat is typeof categories[0] => cat !== null && cat.products.length > 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-b border-slate-200 pb-4 dark:border-slate-800">
        <div>
          <div className="flex items-center gap-2.5">
            <h2 className="text-2xl font-extrabold tracking-tight text-slate-900 dark:text-slate-100">
              Menu & Stock Control
            </h2>
            <Badge variant="purple" size="md">
              {allProducts.length} Items
            </Badge>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Toggle real-time item availability to prevent orders for sold-out dishes
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Badge variant="success" size="sm">
            <CheckCircle2 className="h-3 w-3 mr-1" /> {totalInStock} In Stock
          </Badge>
          {totalOutOfStock > 0 && (
            <Badge variant="danger" size="sm">
              <XCircle className="h-3 w-3 mr-1" /> {totalOutOfStock} Out of Stock
            </Badge>
          )}
          <Button
            variant="outline"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RefreshCw className="h-4 w-4" />}
          >
            Refresh
          </Button>
        </div>
      </div>

      {/* Search & Category Filter Bar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="w-full sm:w-72">
          <Input
            placeholder="Search items or variants..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            leftIcon={<Search className="h-4 w-4" />}
          />
        </div>

        {/* Category Tabs */}
        <div className="flex flex-wrap items-center gap-1.5 overflow-x-auto pb-1">
          <button
            type="button"
            onClick={() => setSelectedCategory('ALL')}
            className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
              selectedCategory === 'ALL'
                ? 'bg-primary-600 text-white shadow-sm'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300'
            }`}
          >
            All Categories
          </button>
          {categories.map((cat) => (
            <button
              key={cat.id}
              type="button"
              onClick={() => setSelectedCategory(cat.id)}
              className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
                selectedCategory === cat.id
                  ? 'bg-primary-600 text-white shadow-sm'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300'
              }`}
            >
              {cat.name} ({cat.products.length})
            </button>
          ))}
        </div>
      </div>

      {/* Catalog Content */}
      {isLoading ? (
        <div className="py-20">
          <LoadingSpinner size="lg" label="Loading menu items..." />
        </div>
      ) : filteredCategories.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-12 text-center dark:border-slate-800 dark:bg-slate-900">
          <Layers className="mx-auto h-10 w-10 text-slate-400 mb-2" />
          <h4 className="font-bold text-slate-800 dark:text-slate-200">No items match your filter</h4>
          <p className="text-xs text-slate-500 mt-1">Try searching for a different item name</p>
        </div>
      ) : (
        <div className="space-y-8">
          {filteredCategories.map((category) => (
            <div key={category.id} className="space-y-3">
              <div className="flex items-center gap-2 border-b border-slate-200 pb-2 dark:border-slate-800">
                <Tag className="h-4 w-4 text-primary-600 dark:text-primary-400" />
                <h3 className="font-bold text-base text-slate-900 dark:text-slate-100">
                  {category.name}
                </h3>
                <span className="text-xs text-slate-400">({category.products.length} dishes)</span>
              </div>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                {category.products.map((product) => (
                  <div
                    key={product.id}
                    className={`rounded-xl border p-4 transition-all ${
                      product.isInStock
                        ? 'border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900'
                        : 'border-rose-200 bg-rose-50/20 opacity-75 dark:border-rose-950 dark:bg-rose-950/10'
                    }`}
                  >
                    {/* Item header and main stock switch */}
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h4 className="font-bold text-sm text-slate-900 dark:text-slate-100">
                          {product.name}
                        </h4>
                        <p className="text-xs text-slate-500 dark:text-slate-400 line-clamp-2 mt-0.5">
                          {product.description || 'Standard outlet recipe'}
                        </p>
                        <span className="mt-1 inline-block text-xs font-bold text-primary-600 dark:text-primary-400">
                          ৳ {product.basePrice}
                        </span>
                      </div>

                      {/* Stock Switch */}
                      <button
                        type="button"
                        onClick={() =>
                          productStockMutation.mutate({
                            productId: product.id,
                            isInStock: !product.isInStock,
                          })
                        }
                        className={`flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-semibold transition-colors ${
                          product.isInStock
                            ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200 dark:bg-emerald-950 dark:text-emerald-300'
                            : 'bg-rose-100 text-rose-800 hover:bg-rose-200 dark:bg-rose-950 dark:text-rose-300'
                        }`}
                      >
                        {product.isInStock ? (
                          <>
                            <CheckCircle2 className="h-3.5 w-3.5" />
                            <span>In Stock</span>
                          </>
                        ) : (
                          <>
                            <XCircle className="h-3.5 w-3.5" />
                            <span>Sold Out</span>
                          </>
                        )}
                      </button>
                    </div>

                    {/* Variants if any */}
                    {product.variants && product.variants.length > 0 && (
                      <div className="mt-3 border-t border-slate-100 pt-2.5 space-y-1.5 dark:border-slate-800">
                        <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                          Portions / Variants:
                        </span>
                        {product.variants.map((variant) => (
                          <div
                            key={variant.id}
                            className="flex items-center justify-between rounded bg-slate-50 px-2.5 py-1 text-xs dark:bg-slate-800/60"
                          >
                            <span className="text-slate-700 dark:text-slate-300">
                              {variant.name}{' '}
                              {variant.priceDelta !== 0 && (
                                <span className="text-slate-400 font-medium">
                                  ({variant.priceDelta > 0 ? '+' : ''}৳{variant.priceDelta})
                                </span>
                              )}
                            </span>
                            <button
                              type="button"
                              onClick={() =>
                                variantStockMutation.mutate({
                                  variantId: variant.id,
                                  isInStock: !variant.isInStock,
                                })
                              }
                              className={`text-[11px] font-bold px-1.5 py-0.5 rounded transition-colors ${
                                variant.isInStock
                                  ? 'text-emerald-700 hover:bg-emerald-100 dark:text-emerald-400'
                                  : 'text-rose-700 hover:bg-rose-100 dark:text-rose-400 line-through'
                              }`}
                            >
                              {variant.isInStock ? 'In Stock' : 'Out of Stock'}
                            </button>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
