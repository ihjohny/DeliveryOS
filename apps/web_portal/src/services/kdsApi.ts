import apiClient from './apiClient';
import { KDSOrder, OutletCatalog } from '../types/kds';

export const kdsApi = {
  /**
   * Fetch active kitchen orders queue
   */
  async getLiveOrders(vendorId?: string): Promise<KDSOrder[]> {
    const params = vendorId ? { vendorId } : undefined;
    const response = await apiClient.get('/api/v1/vendor/orders/live', { params });
    const payload = response.data?.data || response.data;
    return payload || [];
  },

  /**
   * Accept incoming order with default or custom preparation time
   */
  async acceptOrder(orderId: string, prepTimeMinutes?: number): Promise<KDSOrder> {
    const response = await apiClient.patch(`/api/v1/vendor/orders/${orderId}/accept`, {
      prepTimeMinutes,
    });
    return response.data?.data || response.data;
  },

  /**
   * Mark order as packaged and ready for rider pickup
   */
  async markOrderReady(orderId: string): Promise<KDSOrder> {
    const response = await apiClient.patch(`/api/v1/vendor/orders/${orderId}/ready`);
    return response.data?.data || response.data;
  },

  /**
   * Confirm food parcel handover to rider at store counter
   */
  async handoverOrder(orderId: string): Promise<KDSOrder> {
    const response = await apiClient.patch(`/api/v1/vendor/orders/${orderId}/handover`);
    return response.data?.data || response.data;
  },

  /**
   * Retrieve full outlet catalog for stock management
   */
  async getOutletCatalog(vendorId: string): Promise<OutletCatalog> {
    const response = await apiClient.get(`/api/v1/vendors/${vendorId}/catalog`);
    return response.data?.data || response.data;
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

