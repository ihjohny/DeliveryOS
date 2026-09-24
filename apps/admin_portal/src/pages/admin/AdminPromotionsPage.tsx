import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Tag,
  Image as ImageIcon,
  Plus,
  Trash2,
  CheckCircle2,
  XCircle,
  Calendar,
  Percent,
  DollarSign,
  Layers,
} from 'lucide-react';
import adminApi, { AdminBanner, AdminCoupon } from '../../services/adminApi';
import { Badge } from '../../components/ui/Badge';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Modal } from '../../components/ui/Modal';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export const AdminPromotionsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<'BANNERS' | 'COUPONS'>('BANNERS');

  // Banner State
  const [isCreateBannerModalOpen, setIsCreateBannerModalOpen] = useState(false);
  const [bannerTitle, setBannerTitle] = useState('');
  const [bannerImageUrl, setBannerImageUrl] = useState('');
  const [bannerSortOrder, setBannerSortOrder] = useState('0');

  // Coupon State
  const [isCreateCouponModalOpen, setIsCreateCouponModalOpen] = useState(false);
  const [couponCode, setCouponCode] = useState('');
  const [couponDescription, setCouponDescription] = useState('');
  const [couponType, setCouponType] = useState<'PERCENTAGE' | 'FLAT'>('PERCENTAGE');
  const [couponValue, setCouponValue] = useState('20');
  const [minSpend, setMinSpend] = useState('300');
  const [maxDiscount, setMaxDiscount] = useState('100');
  const [usageLimit, setUsageLimit] = useState('500');

  // Queries
  const { data: banners = [], isLoading: isLoadingBanners } = useQuery({
    queryKey: ['admin-banners'],
    queryFn: adminApi.getBanners,
  });

  const { data: coupons = [], isLoading: isLoadingCoupons } = useQuery({
    queryKey: ['admin-coupons'],
    queryFn: adminApi.getCoupons,
  });

  // Mutations
  const createBannerMutation = useMutation({
    mutationFn: adminApi.createBanner,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-banners'] });
      setIsCreateBannerModalOpen(false);
      setBannerTitle('');
      setBannerImageUrl('');
      setBannerSortOrder('0');
    },
  });

  const toggleBannerMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      adminApi.updateBanner(id, { isActive }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin-banners'] }),
  });

  const deleteBannerMutation = useMutation({
    mutationFn: adminApi.deleteBanner,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin-banners'] }),
  });

  const createCouponMutation = useMutation({
    mutationFn: adminApi.createCoupon,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-coupons'] });
      setIsCreateCouponModalOpen(false);
      setCouponCode('');
      setCouponDescription('');
      setCouponValue('20');
      setMinSpend('300');
      setMaxDiscount('100');
      setUsageLimit('500');
    },
  });

  const toggleCouponMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      adminApi.updateCoupon(id, { isActive }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin-coupons'] }),
  });

  const deleteCouponMutation = useMutation({
    mutationFn: adminApi.deleteCoupon,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin-coupons'] }),
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2.5">
            <Tag className="h-6 w-6 text-primary-600 dark:text-primary-400" />
            Promotions & Coupon Engine
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Manage home screen hero carousels and checkout discount coupon campaigns
          </p>
        </div>
        <div>
          {activeTab === 'BANNERS' ? (
            <Button size="sm" className="gap-1.5" onClick={() => setIsCreateBannerModalOpen(true)}>
              <Plus className="h-4 w-4" /> Add Promotional Banner
            </Button>
          ) : (
            <Button size="sm" className="gap-1.5" onClick={() => setIsCreateCouponModalOpen(true)}>
              <Plus className="h-4 w-4" /> Create Promo Code
            </Button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200 dark:border-slate-800">
        <button
          onClick={() => setActiveTab('BANNERS')}
          className={`flex items-center gap-2 border-b-2 py-3 px-5 text-sm font-semibold transition-all ${
            activeTab === 'BANNERS'
              ? 'border-primary-600 text-primary-600 dark:border-primary-400 dark:text-primary-400'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
          }`}
        >
          <ImageIcon className="h-4 w-4" />
          Promotional Banners ({banners.length})
        </button>
        <button
          onClick={() => setActiveTab('COUPONS')}
          className={`flex items-center gap-2 border-b-2 py-3 px-5 text-sm font-semibold transition-all ${
            activeTab === 'COUPONS'
              ? 'border-primary-600 text-primary-600 dark:border-primary-400 dark:text-primary-400'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
          }`}
        >
          <Percent className="h-4 w-4" />
          Discount Coupons ({coupons.length})
        </button>
      </div>

      {/* Content Tab 1: Promotional Banners */}
      {activeTab === 'BANNERS' && (
        <div>
          {isLoadingBanners ? (
            <div className="py-16 text-center">
              <LoadingSpinner size="lg" />
            </div>
          ) : banners.length === 0 ? (
            <div className="rounded-xl border border-dashed border-slate-200 p-12 text-center text-xs text-slate-500 dark:border-slate-800">
              No promotional banners created yet. Add your first hero banner.
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {banners.map((banner) => (
                <div
                  key={banner.id}
                  className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900"
                >
                  <div className="relative h-40 bg-slate-100 dark:bg-slate-800">
                    <img
                      src={banner.imageUrl}
                      alt={banner.title}
                      className="h-full w-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src =
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600';
                      }}
                    />
                    <div className="absolute top-2 right-2 flex items-center gap-1.5">
                      {banner.isActive ? (
                        <Badge variant="success">Active</Badge>
                      ) : (
                        <Badge variant="default">Paused</Badge>
                      )}
                    </div>
                  </div>

                  <div className="p-4">
                    <h3 className="font-semibold text-sm text-slate-900 dark:text-slate-100">{banner.title}</h3>
                    <div className="mt-1 flex items-center justify-between text-xs text-slate-500">
                      <span>Order Rank: #{banner.sortOrder}</span>
                      <span>Link: {banner.linkType}</span>
                    </div>

                    <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 dark:border-slate-800">
                      <button
                        onClick={() =>
                          toggleBannerMutation.mutate({
                            id: banner.id,
                            isActive: !banner.isActive,
                          })
                        }
                        className="text-xs font-medium text-slate-600 hover:text-slate-900 dark:text-slate-400"
                      >
                        {banner.isActive ? 'Pause Banner' : 'Activate Banner'}
                      </button>
                      <button
                        onClick={() => {
                          if (confirm('Delete this promotional banner?')) {
                            deleteBannerMutation.mutate(banner.id);
                          }
                        }}
                        className="text-xs font-medium text-rose-600 hover:text-rose-700 flex items-center gap-1"
                      >
                        <Trash2 className="h-3.5 w-3.5" /> Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Content Tab 2: Coupon Codes */}
      {activeTab === 'COUPONS' && (
        <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900 overflow-hidden">
          {isLoadingCoupons ? (
            <div className="py-16 text-center">
              <LoadingSpinner size="lg" />
            </div>
          ) : coupons.length === 0 ? (
            <div className="p-12 text-center text-xs text-slate-500">
              No promo coupon codes created yet. Create codes like WELCOME50.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-slate-100 bg-slate-50 text-slate-600 dark:border-slate-800 dark:bg-slate-800/50 dark:text-slate-400">
                  <tr>
                    <th className="py-3 px-4 font-semibold">Promo Code</th>
                    <th className="py-3 px-4 font-semibold">Discount Rule</th>
                    <th className="py-3 px-4 font-semibold">Min Spend</th>
                    <th className="py-3 px-4 font-semibold">Max Cap</th>
                    <th className="py-3 px-4 font-semibold">Usage</th>
                    <th className="py-3 px-4 font-semibold">Status</th>
                    <th className="py-3 px-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                  {coupons.map((coupon) => (
                    <tr key={coupon.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                      <td className="py-3.5 px-4 font-bold tracking-wider text-slate-900 dark:text-slate-100">
                        {coupon.code}
                        {coupon.description && (
                          <div className="text-[11px] font-normal text-slate-500">{coupon.description}</div>
                        )}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="font-semibold text-primary-600 dark:text-primary-400">
                          {coupon.discountType === 'PERCENTAGE'
                            ? `${coupon.discountValue}% OFF`
                            : `৳${coupon.discountValue} FLAT`}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 dark:text-slate-300">
                        ৳{coupon.minOrderAmount}
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 dark:text-slate-300">
                        {coupon.maxDiscountAmount ? `৳${coupon.maxDiscountAmount}` : 'No Cap'}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="font-medium text-slate-900 dark:text-slate-100">{coupon.currentUses}</span>
                        <span className="text-slate-400"> / {coupon.usageLimit}</span>
                      </td>
                      <td className="py-3.5 px-4">
                        {coupon.isActive ? (
                          <Badge variant="success">Active</Badge>
                        ) : (
                          <Badge variant="default">Paused</Badge>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-right space-x-2">
                        <button
                          onClick={() =>
                            toggleCouponMutation.mutate({
                              id: coupon.id,
                              isActive: !coupon.isActive,
                            })
                          }
                          className="text-xs font-medium text-slate-600 hover:text-slate-900 dark:text-slate-400"
                        >
                          {coupon.isActive ? 'Pause' : 'Activate'}
                        </button>
                        <button
                          onClick={() => {
                            if (confirm(`Delete coupon code ${coupon.code}?`)) {
                              deleteCouponMutation.mutate(coupon.id);
                            }
                          }}
                          className="text-xs font-medium text-rose-600 hover:text-rose-700"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Modal: Create Banner */}
      <Modal
        isOpen={isCreateBannerModalOpen}
        onClose={() => setIsCreateBannerModalOpen(false)}
        title="Add Promotional Hero Banner"
      >
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Banner Title
            </label>
            <Input
              value={bannerTitle}
              onChange={(e) => setBannerTitle(e.target.value)}
              placeholder="e.g. 50% Off Pilot Weekend Feast"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Image URL (Creative Asset)
            </label>
            <Input
              value={bannerImageUrl}
              onChange={(e) => setBannerImageUrl(e.target.value)}
              placeholder="https://images.unsplash.com/..."
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Display Sequence Rank (Sort Order)
            </label>
            <Input
              type="number"
              value={bannerSortOrder}
              onChange={(e) => setBannerSortOrder(e.target.value)}
              placeholder="0"
            />
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
            <Button variant="outline" size="sm" onClick={() => setIsCreateBannerModalOpen(false)}>
              Cancel
            </Button>
            <Button
              size="sm"
              disabled={!bannerTitle || !bannerImageUrl}
              isLoading={createBannerMutation.isPending}
              onClick={() =>
                createBannerMutation.mutate({
                  title: bannerTitle,
                  imageUrl: bannerImageUrl,
                  sortOrder: parseInt(bannerSortOrder, 10) || 0,
                  isActive: true,
                })
              }
            >
              Publish Banner
            </Button>
          </div>
        </div>
      </Modal>

      {/* Modal: Create Coupon */}
      <Modal
        isOpen={isCreateCouponModalOpen}
        onClose={() => setIsCreateCouponModalOpen(false)}
        title="Create Promotional Discount Coupon"
      >
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Coupon Code (Alphanumeric)
            </label>
            <Input
              value={couponCode}
              onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
              placeholder="e.g. WELCOME50"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Description
            </label>
            <Input
              value={couponDescription}
              onChange={(e) => setCouponDescription(e.target.value)}
              placeholder="e.g. 20% discount on first 5 orders"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Discount Type
              </label>
              <select
                value={couponType}
                onChange={(e) => setCouponType(e.target.value as any)}
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs focus:border-primary-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
              >
                <option value="PERCENTAGE">Percentage (%)</option>
                <option value="FLAT">Flat Deduction (৳)</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Discount Value
              </label>
              <Input
                type="number"
                value={couponValue}
                onChange={(e) => setCouponValue(e.target.value)}
                placeholder="20"
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Min Spend (৳)
              </label>
              <Input
                type="number"
                value={minSpend}
                onChange={(e) => setMinSpend(e.target.value)}
                placeholder="300"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Max Cap (৳)
              </label>
              <Input
                type="number"
                value={maxDiscount}
                onChange={(e) => setMaxDiscount(e.target.value)}
                placeholder="100"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Usage Limit
              </label>
              <Input
                type="number"
                value={usageLimit}
                onChange={(e) => setUsageLimit(e.target.value)}
                placeholder="500"
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
            <Button variant="outline" size="sm" onClick={() => setIsCreateCouponModalOpen(false)}>
              Cancel
            </Button>
            <Button
              size="sm"
              disabled={!couponCode || !couponValue}
              isLoading={createCouponMutation.isPending}
              onClick={() =>
                createCouponMutation.mutate({
                  code: couponCode,
                  description: couponDescription,
                  discountType: couponType,
                  discountValue: parseFloat(couponValue) || 0,
                  minOrderAmount: parseFloat(minSpend) || 0,
                  maxDiscountAmount: maxDiscount ? parseFloat(maxDiscount) : undefined,
                  usageLimit: parseInt(usageLimit, 10) || 1000,
                  isActive: true,
                })
              }
            >
              Activate Promo Code
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
