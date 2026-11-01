import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/notification_service.dart';

// Dependency injection providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});

// Auth state class
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isInitialized == isInitialized;
  }

  @override
  int get hashCode => Object.hash(user, isLoading, error, isInitialized);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SocketService _socketService;
  final ApiClient _apiClient;

  AuthNotifier(this._repository, this._socketService, this._apiClient)
      : super(const AuthState()) {
    _apiClient.onUnauthorized = handleUnauthorized;
    init();
  }

  Future<void> init() async {
    try {
      final token = await _repository.getSavedToken();
      final cachedUser = await _repository.getCachedUser();

      if (token != null && token.isNotEmpty) {
        // 1. Immediately restore state from cache so user never sees login screen
        if (cachedUser != null) {
          state = state.copyWith(user: cachedUser, isInitialized: true);
          _socketService.connect(token);
        }

        // 2. Validate/refresh profile with server in background
        try {
          final freshUser = await _repository.getMe().timeout(const Duration(seconds: 3));
          _socketService.connect(token);
          state = state.copyWith(user: freshUser, isInitialized: true);
          return;
        } on ApiException catch (apiErr) {
          if (apiErr.statusCode == 401) {
            // Strictly 401: Token expired or invalid
            await _repository.logout();
            state = state.copyWith(isInitialized: true, clearUser: true);
            return;
          }
          // Network/other error: keep cached user session
          if (cachedUser != null) return;
        } catch (_) {
          // Network offline / connection refused: keep cached user session
          if (cachedUser != null) return;
        }
      }
    } catch (_) {}

    state = state.copyWith(isInitialized: true, clearUser: state.user == null);
  }

  String _formatError(dynamic e) {
    if (e is ApiException) return e.message;
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }

  Future<bool> login(String emailOrMobile, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.login(
        emailOrMobile: emailOrMobile,
        password: password,
      );
      _socketService.connect(result.token);
      NotificationService().init(apiClient: _apiClient).catchError((_) {});
      NotificationService().registerDeviceToken(_apiClient).catchError((_) {});
      state = state.copyWith(user: result.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _formatError(e));
      return false;
    }
  }

  Future<bool> signup(String name, String emailOrMobile, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.signup(
        name: name,
        emailOrMobile: emailOrMobile,
        password: password,
      );
      _socketService.connect(result.token);
      NotificationService().init(apiClient: _apiClient).catchError((_) {});
      NotificationService().registerDeviceToken(_apiClient).catchError((_) {});
      state = state.copyWith(user: result.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _formatError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await NotificationService().removeDeviceToken(_apiClient);
    _socketService.disconnect();
    await _repository.logout();
    state = state.copyWith(clearUser: true);
  }

  void handleUnauthorized() {
    _socketService.disconnect();
    state = state.copyWith(clearUser: true);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(repo, socket, client);
});
