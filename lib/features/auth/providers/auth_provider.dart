import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.post(
        AppConstants.loginEndpoint,
        data: {
          "email": email.trim(),
          "password": password,
        },
      );

      if (response.data["success"] == true) {
        final token = response.data["token"] as String;
        final user = UserModel.fromJson(response.data["user"]);
        await TokenStorage.saveToken(token);
        state = AsyncValue.data(user);
        return {"success": true};
      } else {
        final errorMsg = response.data["error"] ?? "Invalid email or password.";
        // Reset state to data(null) so UI stays on LoginScreen instead of crashing into red screen!
        state = const AsyncValue.data(null);
        return {"success": false, "error": errorMsg};
      }
    } on DioException catch (dioErr) {
      String message = "Unable to connect to the server. Please check your network.";
      if (dioErr.response?.data is Map && dioErr.response?.data["error"] != null) {
        message = dioErr.response?.data["error"];
      } else if (dioErr.type == DioExceptionType.connectionTimeout ||
          dioErr.type == DioExceptionType.receiveTimeout) {
        message = "Connection timed out. Please check your internet connection.";
      }
      state = const AsyncValue.data(null);
      return {"success": false, "error": message};
    } catch (e) {
      final message = e.toString().replaceFirst("Exception: ", "");
      state = const AsyncValue.data(null);
      return {"success": false, "error": message};
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = const AsyncValue.data(null);
  }
}
