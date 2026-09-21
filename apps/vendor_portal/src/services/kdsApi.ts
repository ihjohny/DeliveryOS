import apiClient from './apiClient';
import { KDSOrder, OutletCatalog, KDSOrderItem } from '../types/kds';

/**
 * Normalizes backend Prisma order entity into typed KDSOrder format.
 * Bridges differences between Prisma relational fields (orderItems, placedAt, rider.user)
 * and the frontend UI model.
 */
export function normalizeKDSOrder(raw: any): KDSOrder {
  if (!raw) return raw;

  const rawItems = raw.items || raw.orderItems || [];
  const items: KDSOrderItem[] = rawItems.map((item: any) => ({
    id: item.id || '',
    productId: item.productId || '',
    productName: item.productName || item.productNameSnapshot || 'Item',
    quantity: Number(item.quantity) || 1,
    unitPrice: Number(item.unitPrice) || 0,
    subtotal: Number(item.subtotal ?? item.totalPrice) || 0,
    instructions: item.instructions || item.specialInstructions || null,
    variant: item.variant || item.variantSnapshot || null,
    toppings: item.toppings || item.addonsSnapshot || [],
  }));

  const rider = raw.rider
    ? {
        id: raw.rider.id,
        fullName: raw.rider.fullName || raw.rider.user?.fullName || 'Assigned Rider',
        phone: raw.rider.phone || raw.rider.user?.phone || '',
        latitude: raw.rider.latitude,
        longitude: raw.rider.longitude,
      }
    : null;

  const customer = raw.customer
    ? {
        id: raw.customer.id || '',
        fullName: raw.customer.fullName || raw.customerPhoneSnapshot || 'Customer',
        phone: raw.customer.phone || raw.customerPhoneSnapshot || '',
      }
    : {
        id: '',
        fullName: raw.customerPhoneSnapshot || 'Customer',
        phone: raw.customerPhoneSnapshot || '',
      };

  return {
    id: raw.id,
    orderNumber: raw.orderNumber || '',
    vendorId: raw.vendorId || '',
    status: raw.status,
    subtotal: Number(raw.subtotal) || 0,
    taxAmount: Number(raw.taxAmount) || 0,
    deliveryFee: Number(raw.deliveryFee) || 0,
    discountAmount: Number(raw.couponDiscount ?? raw.discountAmount) || 0,
    totalAmount: Number(raw.totalAmount) || 0,
    paymentMethod: raw.paymentMethod || 'CASH_ON_DELIVERY',
    paymentStatus: raw.paymentStatus || 'PENDING',
    deliveryAddress: raw.deliveryAddress || raw.deliveryAddressSnapshot || null,
    customerNotes: raw.customerNotes || null,
    prepTimeMinutes: raw.prepTimeMinutes ?? raw.vendor?.defaultPrepTimeMinutes ?? null,
    createdAt: raw.createdAt || raw.placedAt || new Date().toISOString(),
    updatedAt: raw.updatedAt || raw.placedAt || new Date().toISOString(),
    acceptedAt: raw.acceptedAt || null,
    readyAt: raw.readyAt || null,
    customer,
    rider,
    items,
  };
}

export const kdsApi = {
  /**
   * Fetch active kitchen orders queue
   */
  async getLiveOrders(vendorId?: string): Promise<KDSOrder[]> {
    const params = vendorId ? { vendorId } : undefined;
    const response = await apiClient.get('/api/v1/vendor/orders/live', { params });
    const payload = response.data?.data || response.data;
    const rawList = Array.isArray(payload) ? payload : [];
    return rawList.map(normalizeKDSOrder);
  },

  /**
   * Accept incoming order with default or custom preparation time
   */
  async acceptOrder(orderId: string, prepTimeMinutes?: number): Promise<KDSOrder> {
    const response = await apiClient.patch(`/api/v1/vendor/orders/${orderId}/accept`, {
      prepTimeMinutes,
    });
    const payload = response.data?.data || response.data;
    return normalizeKDSOrder(payload);
  },

  /**
   * Mark order as packaged and ready for rider pickup
   */
  async markOrderReady(orderId: string): Promise<KDSOrder> {
    const response = await apiClient.patch(`/api/v1/vendor/orders/${orderId}/ready`);
    const payload = response.data?.data || response.data;
    return normalizeKDSOrder(payload);
  },

  /**
   * Confirm food parcel handover to rider at store counter
   */
  async handoverOrder(orderId: string): Promise<KDSOrder> {
    const response = await apiClient.patch(`/api/v1/vendor/orders/${orderId}/handover`);
    const payload = response.data?.data || response.data;
    return normalizeKDSOrder(payload);
  },

  /**
   * Retrieve full outlet catalog for stock management
   */
  async getOutletCatalog(vendorId: string): Promise<OutletCatalog> {
    const response = await apiClient.get(`/api/v1/vendors/${vendorId}/catalog`);
    const payload = response.data?.data || response.data;
    if (!payload || !payload.categories) {
      return payload || { vendorId, vendorName: '', defaultPrepTimeMinutes: 20, categories: [] };
    }
    // Normalize variant price modifiers to priceDelta
    const categories = payload.categories.map((cat: any) => ({
      ...cat,
      products: (cat.products || []).map((prod: any) => ({
        ...prod,
        variants: (prod.variants || []).map((v: any) => ({
          ...v,
          priceDelta: Number(v.priceDelta ?? v.priceModifier) || 0,
        })),
      })),
    }));
    return { ...payload, categories };
  },

  /**
   * Instant toggle for product stock availability
   */
  async toggleProductStock(productId: string, isInStock: boolean): Promise<{ id: string; isInStock: boolean }> {
    const response = await apiClient.patch(`/api/v1/vendor/products/${productId}/stock`, {
      isInStock,
    });
    return response.data?.data || response.data;
  },

  /**
   * Instant toggle for product variant stock availability
   */
  async toggleVariantStock(variantId: string, isInStock: boolean): Promise<{ id: string; isInStock: boolean }> {
    const response = await apiClient.patch(`/api/v1/vendor/products/variants/${variantId}/stock`, {
      isInStock,
    });
    return response.data?.data || response.data;
  },

  /**
   * Get accessible outlets based on staff scope (Particular vs Brand Owner)
   */
  async getAccessibleOutlets(): Promise<
    Array<{
      id: string;
      name: string;
      addressText: string;
      isBusy: boolean;
      isActive: boolean;
      defaultPrepTimeMinutes: number;
      brandId?: string | null;
    }>
  > {
    const response = await apiClient.get('/api/v1/vendor/outlets');
    return response.data?.data || response.data;
  },

  /**
   * Get outlet settings and operating schedule
   */
  async getOutletSettings(vendorId?: string): Promise<{
    id: string;
    name: string;
    addressText: string;
    contactPhone: string;
    isBusy: boolean;
    isActive: boolean;
    commissionRate: number;
    defaultPrepTimeMinutes: number;
    brand?: { id: string; name: string } | null;
    operatingHours: Array<{
      id: string;
      dayOfWeek: number;
      openTime: string;
      closeTime: string;
      isClosed: boolean;
    }>;
  }> {
    const params = vendorId && vendorId !== 'ALL' ? { vendorId } : undefined;
    const response = await apiClient.get('/api/v1/vendor/settings', { params });
    return response.data?.data || response.data;
  },

  /**
   * Update outlet settings (prep time, emergency pause, active state)
   */
  async updateOutletSettings(
    vendorId: string,
    data: {
      defaultPrepTimeMinutes?: number;
      isBusy?: boolean;
      isActive?: boolean;
    }
  ) {
    const response = await apiClient.patch('/api/v1/vendor/settings', data, {
      params: { vendorId },
    });
    return response.data?.data || response.data;
  },

  /**
   * Update weekly operating schedule
   */
  async updateOperatingHours(
    vendorId: string,
    hours: Array<{
      dayOfWeek: number;
      openTime: string;
      closeTime: string;
      isClosed: boolean;
    }>
  ) {
    const response = await apiClient.put(
      '/api/v1/vendor/operating-hours',
      { hours },
      { params: { vendorId } }
    );
    return response.data?.data || response.data;
  },

  /**
   * Get daily sales ledger and commission breakdown
   */
  async getSalesLedger(vendorId?: string): Promise<{
    summary: {
      totalOrders: number;
      grossSales: number;
      commissionDeducted: number;
      netVendorPayable: number;
    };
    ledgers: Array<{
      id: string;
      orderId: string;
      orderNumber: string;
      vendorId: string;
      vendorName: string;
      customerName: string;
      paymentMethod: string;
      orderStatus: string;
      grossAmount: number;
      commissionRate: number;
      commissionAmount: number;
      netVendorPayable: number;
      settlementStatus: string;
      settledAt?: string | null;
      createdAt: string;
    }>;
  }> {
    const params = vendorId && vendorId !== 'ALL' ? { vendorId } : undefined;
    const response = await apiClient.get('/api/v1/vendor/sales', { params });
    return response.data?.data || response.data;
  },
};

export default kdsApi;

