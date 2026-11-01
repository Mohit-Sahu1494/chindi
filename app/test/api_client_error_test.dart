import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hisaab_app/data/api/api_client.dart';

void main() {
  group('ApiClient Error Handling Tests', () {
    test('converts 404 Email not found response into clean ApiException', () {
      final dio = Dio();
      final client = ApiClient(dio: dio);

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 404,
          data: {'success': false, 'message': 'Email not found'},
        ),
      );

      try {
        throw client.handleError(dioException);
      } catch (e) {
        expect(e, isA<ApiException>());
        final apiErr = e as ApiException;
        expect(apiErr.message, 'Email not found');
        expect(apiErr.statusCode, 404);
        expect(apiErr.toString(), 'Email not found');
      }
    });

    test('converts 401 Incorrect password response into clean ApiException', () {
      final dio = Dio();
      final client = ApiClient(dio: dio);

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'success': false, 'message': 'Email and password is incorrect'},
        ),
      );

      try {
        throw client.handleError(dioException);
      } catch (e) {
        expect(e, isA<ApiException>());
        final apiErr = e as ApiException;
        expect(apiErr.message, 'Email and password is incorrect');
        expect(apiErr.statusCode, 401);
      }
    });

    test('extracts detailed validation errors instead of generic "Validation error"', () {
      final dio = Dio();
      final client = ApiClient(dio: dio);

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/signup'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/signup'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Validation error',
            'errors': [
              {'field': 'password', 'message': 'Password must be at least 6 characters'}
            ]
          },
        ),
      );

      try {
        throw client.handleError(dioException);
      } catch (e) {
        expect(e, isA<ApiException>());
        final apiErr = e as ApiException;
        expect(apiErr.message, 'Password must be at least 6 characters');
        expect(apiErr.statusCode, 400);
      }
    });

    test('handles network connection error cleanly', () {
      final dio = Dio();
      final client = ApiClient(dio: dio);

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/groups'),
        type: DioExceptionType.connectionError,
        error: 'SocketException: Connection refused',
      );

      try {
        throw client.handleError(dioException);
      } catch (e) {
        expect(e, isA<ApiException>());
        final apiErr = e as ApiException;
        expect(apiErr.message, contains('Server se connect nahi ho paya'));
      }
    });
  });
}
