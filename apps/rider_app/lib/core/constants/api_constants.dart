class ApiConstants {
  static const String baseUrl = 'http://localhost:4000/api/v1';

  // Auth endpoints
  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String me = '/auth/me';

  // Rider operations
  static const String riderProfile = '/rider/profile';
  static const String toggleDuty = '/rider/duty';
  static const String claimOrder = '/rider/orders'; // + /:id/claim
  static const String pickupOrder = '/rider/orders'; // + /:id/pickup
  static const String deliverOrder = '/rider/orders'; // + /:id/deliver
}
