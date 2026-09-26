import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api/v1';
    }
    return 'http://localhost:4000/api/v1';
  }

  static String get socketUrl {
    if (kIsWeb) {
      return 'http://localhost:4000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }

  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String refreshAuth = '/auth/refresh';
  static const String registerDeviceToken = '/auth/device-token';

  static const String nearbyVendors = '/vendors/nearby';
  static const String vendorDetails = '/vendors';
  static const String searchVendors = '/vendors/search';
  static String vendorCatalog(String id) => '/vendors/$id/catalog';
  static const String activeBanners = '/banners/active';
  static const String validateCoupon = '/coupons/validate';
  static const String cartValidateCoverage = '/cart/validate-address-coverage';

  static const String customerAddresses = '/customers/addresses';
  static const String customerProfile = '/customers/profile';
  static const String initiatePayment = '/payments/initiate';
  static const String paymentStatus = '/payments/status';
  static const String checkout = '/orders/checkout';
  static const String orderHistory = '/orders/history';
  static const String orderDetails = '/orders';
  static const String validateReorder = '/orders/validate-reorder';
}
