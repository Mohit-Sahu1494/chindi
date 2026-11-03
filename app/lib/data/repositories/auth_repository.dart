import '../api/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> sendSignupOtp(String email) async {
    await _apiClient.post('/auth/send-signup-otp', data: {
      'email': email.trim().toLowerCase(),
    });
  }

  Future<({String token, UserModel user})> signup({
    required String name,
    required String email,
    required String password,
    required String otp,
  }) async {
    final res = await _apiClient.post('/auth/signup', data: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'otp': otp.trim(),
    });

    final token = res['token'] as String;
    final user = UserModel.fromJson(res['user']);
    await _apiClient.saveToken(token);
    await _apiClient.saveUser(user);
    return (token: token, user: user);
  }

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    final res = await _apiClient.post('/auth/login', data: {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    final token = res['token'] as String;
    final user = UserModel.fromJson(res['user']);
    await _apiClient.saveToken(token);
    await _apiClient.saveUser(user);
    return (token: token, user: user);
  }

  Future<void> sendForgotPasswordOtp(String email) async {
    await _apiClient.post('/auth/forgot-password/send-otp', data: {
      'email': email.trim().toLowerCase(),
    });
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post('/auth/forgot-password/reset', data: {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
      'newPassword': newPassword,
    });
  }

  Future<UserModel> getMe() async {
    final res = await _apiClient.get('/auth/me');
    final user = UserModel.fromJson(res['user']);
    await _apiClient.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    await _apiClient.clearAuth();
  }

  Future<String?> getSavedToken() async {
    return await _apiClient.getToken();
  }

  Future<UserModel?> getCachedUser() async {
    return await _apiClient.getCachedUser();
  }

  Future<void> saveUser(UserModel user) async {
    await _apiClient.saveUser(user);
  }
}
