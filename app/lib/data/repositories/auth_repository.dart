import '../api/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<({String token, UserModel user})> signup({
    required String name,
    required String emailOrMobile,
    required String password,
  }) async {
    final res = await _apiClient.post('/auth/signup', data: {
      'name': name,
      'emailOrMobile': emailOrMobile,
      'password': password,
    });

    final token = res['token'] as String;
    final user = UserModel.fromJson(res['user']);
    await _apiClient.saveToken(token);
    await _apiClient.saveUser(user);
    return (token: token, user: user);
  }

  Future<({String token, UserModel user})> login({
    required String emailOrMobile,
    required String password,
  }) async {
    final res = await _apiClient.post('/auth/login', data: {
      'emailOrMobile': emailOrMobile,
      'password': password,
    });

    final token = res['token'] as String;
    final user = UserModel.fromJson(res['user']);
    await _apiClient.saveToken(token);
    await _apiClient.saveUser(user);
    return (token: token, user: user);
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
