import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Exception khusus untuk penanganan kesalahan jaringan dan API Laravel Sanctum
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class NetworkTimeoutException extends ApiException {
  const NetworkTimeoutException()
      : super(
          message: 'Koneksi internet tidak stabil / waktu habis (timeout). Harap periksa sinyal pesisir Anda.',
          statusCode: 408,
        );
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super(
          message: 'Sesi login telah kedaluwarsa. Silakan masuk kembali.',
          statusCode: 401,
        );
}

/// Client HTTP Dio dengan timeout handling & interceptor token Sanctum otomatis.
class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    String? baseUrl,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConstants.defaultBaseUrl,
                connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
                receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
                sendTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(_createAuthInterceptor());
  }

  Dio get dio => _dio;
  FlutterSecureStorage get secureStorage => _secureStorage;

  /// Interceptor untuk menyisipkan header Authorization: Bearer <token>
  Interceptor _createAuthInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _secureStorage.read(key: AppConstants.keyAuthToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        final transformedException = _handleDioError(error);
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: transformedException,
            message: transformedException.message,
          ),
        );
      },
    );
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkTimeoutException();
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Tidak dapat terhubung ke server Laravel SPBN. Pastikan server aktif dan terjangkau.',
      );
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      if (statusCode == 401) {
        return const UnauthorizedException();
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String? ?? 'Terjadi kesalahan pada server (${response.statusCode}).';
        final errors = data['errors'];
        return ApiException(
          message: message,
          statusCode: statusCode,
          errors: errors,
        );
      }

      return ApiException(
        message: 'Respon server bermasalah (${response.statusCode}).',
        statusCode: statusCode,
      );
    }

    return ApiException(message: error.message ?? 'Terjadi kesalahan jaringan tak terduga.');
  }

  // Token Management
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: AppConstants.keyAuthToken);
  }

  // HTTP Method Wrappers
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Provider instance DioClient
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});
