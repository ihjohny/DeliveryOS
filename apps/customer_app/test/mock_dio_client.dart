import 'package:customer_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

DioClient createTestMockDioClient() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;

        if (path.contains('/auth/otp/verify')) {
          final data = options.data is Map ? options.data as Map : {};
          final otp = data['otp']?.toString();
          final phone = data['phone']?.toString() ?? '+8801700000005';
          if (otp == '123456') {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {
                    'accessToken': 'test-access-token-jwt',
                    'user': {
                      'id': 'user-test-id',
                      'phone': phone,
                      'name': 'Test User',
                      'role': 'CUSTOMER',
                    },
                  },
                },
              ),
            );
          }
          return handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 400,
                data: {'message': 'Invalid OTP'},
              ),
            ),
          );
        }

        if (path.contains('/coupons/validate') || path.contains('/promotions/validate-coupon')) {
          final data = options.data is Map ? options.data as Map : {};
          final code = data['code']?.toString();
          if (code == 'WELCOME50') {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {
                    'isValid': true,
                    'discountAmount': 50.0,
                    'discount': 50.0,
                    'discountType': 'FLAT',
                    'code': 'WELCOME50',
                  },
                },
              ),
            );
          }
          return handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 400,
                data: {'message': 'Invalid coupon'},
              ),
            ),
          );
        }

        if (path.contains('/orders/validate-reorder') || path.contains('/reorder-check')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {
                  'isStoreOperational': true,
                  'hasStockChanges': false,
                  'validItems': [],
                  'unavailableItems': [],
                },
              },
            ),
          );
        }

        if (path.contains('/geo/reverse-geocode')) {
          final lat = (options.queryParameters['lat'] as num?)?.toDouble() ?? 0.0;
          String address = 'Banani Road 11, Dhaka';
          if ((lat - 23.7780).abs() < 0.01) {
            address = 'Gulshan 1 Circle, Avenue 1, Dhaka';
          } else if ((lat - 23.7465).abs() < 0.01) {
            address = 'Road 27, Dhanmondi, Dhaka';
          }
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {
                  'addressLine': address,
                  'displayName': address,
                },
              },
            ),
          );
        }

        if (path.contains('/vendors/nearby')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': [],
              },
            ),
          );
        }

        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'status': 'success', 'data': {}},
          ),
        );
      },
    ),
  );

  return DioClient(dio: dio);
}
