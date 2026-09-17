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
};

export default kdsApi;
