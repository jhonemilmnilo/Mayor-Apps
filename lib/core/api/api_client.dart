
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'api_constants.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          "Content-Type": "application/json",
          "x-app-key": AppConstants.appKey,
        },
      ),
    );

    // Auto-inject JWT Bearer Token if available
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Log or handle global 401 token expiry
          return handler.next(error);
        },
      ),
    );
  }
}