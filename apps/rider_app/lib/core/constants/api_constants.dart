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

  // Auth endpoints
  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String me = '/auth/me';
  static const String registerDeviceToken = '/auth/device-token';

  // Rider operations
  static const String riderProfile = '/rider/profile';
  static const String toggleDuty = '/rider/duty';
  static const String depositCash = '/rider/cash/deposit';
  static const String claimOrder = '/rider/orders'; // + /:id/claim
  static const String pickupOrder = '/rider/orders'; // + /:id/pickup
  static const String deliverOrder = '/rider/orders'; // + /:id/deliver
  static const String trips = '/rider/trips';
}
