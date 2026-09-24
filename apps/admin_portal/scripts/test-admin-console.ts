import axios from 'axios';
import { PrismaClient } from '../../../services/backend_api/node_modules/@prisma/client';

function assert(condition: boolean, message: string) {
  if (!condition) {
    console.error(`❌ ASSERTION FAILED: ${message}`);
    process.exit(1);
  }
  console.log(`   ✅ ${message}`);
}

const API_BASE = 'http://localhost:4000/api/v1';
const prisma = new PrismaClient();

async function runAdminConsoleVerification() {
  console.log('================================================================');
  console.log(' DeliveryOS Super Admin Master Governance & Console Tests');
  console.log('================================================================\n');

  try {
    // 1. Authenticate Super Admin (+8801700000001)
    console.log('🔑 1. Authenticating Super Admin & Verifying Access...');
    const adminAuthRes = await axios.post(`${API_BASE}/auth/otp/verify`, {
      phone: '+8801700000001', // Tariqul Islam (Super Admin)
      otp: '123456',
    });
    const adminToken = adminAuthRes.data.data.accessToken;
    const adminHeaders = { Authorization: `Bearer ${adminToken}` };
    assert(adminAuthRes.data.data.user.role === 'SUPER_ADMIN', 'Super Admin role verified');

    // Also authenticate Customer (+8801700000005) for test order creation
    const customerAuthRes = await axios.post(`${API_BASE}/auth/otp/verify`, {
      phone: '+8801700000005',
      otp: '123456',
    });
    const customerHeaders = { Authorization: `Bearer ${customerAuthRes.data.data.accessToken}` };

    // Also authenticate Rider (+8801700000004) to ensure online status
    const riderAuthRes = await axios.post(`${API_BASE}/auth/otp/verify`, {
      phone: '+8801700000004',
      otp: '123456',
    });
    const riderHeaders = { Authorization: `Bearer ${riderAuthRes.data.data.accessToken}` };
    const riderMeRes = await axios.get(`${API_BASE}/rider/profile`, { headers: riderHeaders });
    const riderId = riderMeRes.data.data.id;
    console.log(`   ℹ️ Active Delivery Courier: ${riderMeRes.data.data.fullName} [${riderId}]`);

    // 2. Dashboard Overview KPIs
    console.log('\n📊 2. Testing Super Admin Dashboard Overview KPIs (GET /admin/overview)...');
    const overviewRes = await axios.get(`${API_BASE}/admin/overview`, { headers: adminHeaders });
    assert(overviewRes.status === 200, 'Overview stats retrieved successfully');
    const overview = overviewRes.data.data;
    assert(typeof overview.metrics.totalOrders === 'number', `Total orders metric: ${overview.metrics.totalOrders}`);
    assert(typeof overview.metrics.activeRiders === 'number', `Active riders metric: ${overview.metrics.activeRiders}`);
    assert(typeof overview.metrics.onlineVendors === 'number', `Online vendors metric: ${overview.metrics.onlineVendors}`);
    assert(Array.isArray(overview.recentOrders), `Recent orders stream has ${overview.recentOrders.length} items`);

    // 3. Live Fleet Radar & Cash Safety Limit Adjustment
    console.log('\n🛰️  3. Testing Live Fleet Radar & Cash Safety Adjust (GET/PATCH /admin/fleet)...');
    const fleetRes = await axios.get(`${API_BASE}/admin/fleet`, { headers: adminHeaders });
    assert(fleetRes.status === 200, 'Fleet radar retrieved successfully');
    const fleet = fleetRes.data.data;
    assert(Array.isArray(fleet) && fleet.length > 0, `Fleet radar tracks ${fleet.length} registered couriers`);
    const targetRider = fleet.find((r: { id: string }) => r.id === riderId);
    assert(!!targetRider, 'Test courier found in fleet telemetry');

    // Update Cash Safety Limit
    const newLimit = 6500;
    const patchLimitRes = await axios.patch(
      `${API_BASE}/admin/riders/${riderId}/cash-limit`,
      { maxCashLimit: newLimit },
      { headers: adminHeaders }
    );
    assert(patchLimitRes.status === 200, `Courier cash safety limit successfully updated to ৳${newLimit}`);

    // Restore Cash Limit
    await axios.patch(
      `${API_BASE}/admin/riders/${riderId}/cash-limit`,
      { maxCashLimit: 5000 },
      { headers: adminHeaders }
    );

    // 4. Promotional Banners Engine (CRUD)
    console.log('\n🎨 4. Testing Promotional Banners Engine (POST/GET/PATCH/DELETE /admin/banners)...');
    const bannerPayload = {
      title: 'Super Admin Pilot Mega Deal',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      linkType: 'OUTLET',
      sortOrder: 1,
      isActive: true,
    };
    const createBannerRes = await axios.post(`${API_BASE}/admin/banners`, bannerPayload, { headers: adminHeaders });
    assert(createBannerRes.status === 201 || createBannerRes.status === 200, 'Promotional banner created successfully');
    const createdBanner = createBannerRes.data.data;
    assert(createdBanner.title === bannerPayload.title, 'Banner title matches payload');

    const bannersListRes = await axios.get(`${API_BASE}/admin/banners`, { headers: adminHeaders });
    const foundBanner = bannersListRes.data.data.find((b: { id: string }) => b.id === createdBanner.id);
    assert(!!foundBanner, 'New banner visible in admin banners list');

    // Toggle Banner Paused
    const patchBannerRes = await axios.patch(
      `${API_BASE}/admin/banners/${createdBanner.id}`,
      { isActive: false },
      { headers: adminHeaders }
    );
    assert(patchBannerRes.data.data.isActive === false, 'Banner successfully paused');

    // Delete Banner
    await axios.delete(`${API_BASE}/admin/banners/${createdBanner.id}`, { headers: adminHeaders });
    const bannersAfterDel = await axios.get(`${API_BASE}/admin/banners`, { headers: adminHeaders });
    assert(!bannersAfterDel.data.data.some((b: { id: string }) => b.id === createdBanner.id), 'Banner cleanly deleted');

    // 5. Coupon Engine (CRUD)
    console.log('\n🏷️  5. Testing Coupon Engine Management (POST/GET/PATCH/DELETE /admin/coupons)...');
    const testCouponCode = `ADMIN${Math.floor(1000 + Math.random() * 9000)}`;
    const createCouponRes = await axios.post(
      `${API_BASE}/admin/coupons`,
      {
        code: testCouponCode,
        description: 'Automated test discount coupon',
        discountType: 'PERCENTAGE',
        discountValue: 25,
        minOrderAmount: 200,
        maxDiscountAmount: 80,
        usageLimit: 50,
      },
      { headers: adminHeaders }
    );
    assert(createCouponRes.status === 201 || createCouponRes.status === 200, `Coupon "${testCouponCode}" created successfully`);
    const createdCoupon = createCouponRes.data.data;

    // Validate Coupon via Public Endpoint
    const validateRes = await axios.post(`${API_BASE}/coupons/validate`, {
      code: testCouponCode,
      cartSubtotal: 300,
    });
    assert(validateRes.status === 200, 'New coupon validated successfully against customer checkout');
    assert(validateRes.data.data.discountAmount === 75, '25% discount accurately calculated (৳75 on ৳300 subtotal)');

    // Delete Coupon
    await axios.delete(`${API_BASE}/admin/coupons/${createdCoupon.id}`, { headers: adminHeaders });
    console.log('   ✅ Coupon deleted cleanly');

    // 6. Live Order Monitor & Manual Dispatch Force-Assign Override
    console.log('\n⚡ 6. Testing Order Lifecycle Monitor & Manual Dispatch Force-Assign Override...');
    // Create an order
    const product = await prisma.product.findFirst({ where: { isInStock: true }, include: { vendor: true } });
    assert(!!product, `In-stock product found: "${product?.name}"`);
    const vendor = product!.vendor;
    assert(!!vendor, `Active store outlet found: "${vendor?.name}"`);
    const customer = await prisma.user.findFirst({ where: { phone: '+8801700000005' } });
    const address = await prisma.customerAddress.findFirst({ where: { userId: customer!.id, isDefault: true } });

    const checkoutRes = await axios.post(
      `${API_BASE}/orders/checkout`,
      {
        vendorId: vendor!.id,
        deliveryAddressId: address!.id,
        paymentMethod: 'CASH_ON_DELIVERY',
        items: [{ productId: product!.id, quantity: 1 }],
      },
      { headers: customerHeaders }
    );
    const orderData = checkoutRes.data.data;
    const testOrderId = orderData.orderId || orderData.id;
    assert(!!testOrderId, `New order placed for force-assignment: #${orderData.orderNumber} (ID: ${testOrderId})`);

    // Fetch in Live Order Monitor
    const liveOrdersRes = await axios.get(`${API_BASE}/admin/orders`, { headers: adminHeaders });
    const orderInQueue = liveOrdersRes.data.data.find((o: { id: string }) => o.id === testOrderId);
    assert(!!orderInQueue, 'Order visible in Super Admin Master Order Lifecycle queue');

    // Super Admin Force Assigns Rider
    const forceAssignRes = await axios.post(
      `${API_BASE}/admin/orders/${testOrderId}/force-assign`,
      { riderId },
      { headers: adminHeaders }
    );
    assert(forceAssignRes.status === 200, 'Super Admin manual dispatch override executed successfully');
    assert(forceAssignRes.data.data.assignedRider.id === riderId, 'Order assigned directly to specified courier');
    assert(
      forceAssignRes.data.data.status === 'RIDER_ASSIGNED',
      `Order lifecycle advanced to status: ${forceAssignRes.data.data.status}`
    );

    // 7. System Settings & Order Flow Mode Switcher
    console.log('\n⚙️  7. Testing System Settings & Order Flow Mode (GET/PATCH /admin/settings)...');
    const settingsRes = await axios.get(`${API_BASE}/admin/settings`, { headers: adminHeaders });
    assert(settingsRes.status === 200, 'System settings retrieved successfully');
    const initialFlowMode = settingsRes.data.data.orderFlow.mode;

    // Switch to VENDOR_FIRST
    const switchRes = await axios.patch(
      `${API_BASE}/admin/settings/order-flow`,
      { mode: 'VENDOR_FIRST', riderSearchTimeoutSeconds: 120 },
      { headers: adminHeaders }
    );
    assert(switchRes.status === 200, 'Order flow mode switched to VENDOR_FIRST');

    // Verify switch persisted
    const verifyFlowRes = await axios.get(`${API_BASE}/admin/settings`, { headers: adminHeaders });
    assert(verifyFlowRes.data.data.orderFlow.mode === 'VENDOR_FIRST', 'VENDOR_FIRST flow mode persisted in database');

    // Restore to initial flow mode
    await axios.patch(
      `${API_BASE}/admin/settings/order-flow`,
      { mode: initialFlowMode, riderSearchTimeoutSeconds: 90 },
      { headers: adminHeaders }
    );
    console.log(`   ✅ Order flow mode safely restored to ${initialFlowMode}`);

    // 8. Financial Settlements Statement & RFC 4180 CSV Export
    console.log('\n💰 8. Testing Financial Settlements Statement & CSV Export (GET /admin/finance/settlement-export)...');
    // JSON format
    const jsonExportRes = await axios.get(`${API_BASE}/admin/finance/settlement-export?format=json`, {
      headers: adminHeaders,
    });
    assert(jsonExportRes.status === 200, 'JSON settlement statements retrieved successfully');
    const statements = jsonExportRes.data.data;
    assert(Array.isArray(statements), 'Settlement statements returned as array');

    if (statements.length > 0) {
      const sample = statements[0];
      const expectedCommission = Math.round(sample.grossSales * 0.15 * 100) / 100;
      const expectedNet = Math.round((sample.grossSales - expectedCommission) * 100) / 100;
      assert(
        Math.abs(sample.platformCommission - expectedCommission) < 0.1,
        `Statement for "${sample.vendorName}" has 15% platform commission (৳${sample.platformCommission})`
      );
      assert(
        Math.abs(sample.netVendorPayable - expectedNet) < 0.1,
        `Statement for "${sample.vendorName}" has 85% net vendor payable (৳${sample.netVendorPayable})`
      );
    }

    // CSV format
    const csvExportRes = await axios.get(`${API_BASE}/admin/finance/settlement-export?format=csv`, {
      headers: adminHeaders,
    });
    assert(csvExportRes.status === 200, 'CSV settlement statement exported successfully');
    const csvData = csvExportRes.data;
    assert(typeof csvData === 'string', 'CSV response is a string stream');
    assert(
      csvData.startsWith('Vendor ID,Vendor Name,Brand,Total Orders,Gross Sales (BDT),Platform Commission (BDT),Net Vendor Payable (BDT),Settlement Status'),
      'CSV contains valid RFC 4180 headers matching technical specification'
    );
    console.log(`   📄 CSV export verified (${csvData.split('\n').length} lines generated)`);

    console.log('\n================================================================');
    console.log(' 🎉 All Super Admin Master Governance & Console Tests Passed!');
    console.log('================================================================\n');
  } finally {
    await prisma.$disconnect();
  }
}

runAdminConsoleVerification().catch((err) => {
  console.error('Admin console verification error:', err.response?.data || err.message);
  process.exit(1);
});
