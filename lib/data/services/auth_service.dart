import '../models/auth_models.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final ApiService _api;
  AuthService(this._api);

  Future<AuthResponse> login(String email, String password) async {
    final data = await _api.post(ApiConstants.login, {'email': email, 'password': password});
    final auth = AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
    final role = _resolveRole(auth.role);
    await _api.storeAuth(auth.token, auth.userId, role);
    return auth;
  }

  Future<AuthResponse> register(String name, String email, String phone, String password) async {
    final data = await _api.post(ApiConstants.register, {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    final auth = AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
    final role = _resolveRole(auth.role);
    await _api.storeAuth(auth.token, auth.userId, role);
    return auth;
  }

  Future<CurrentUser> getCurrentUser() async {
    final data = await _api.get(ApiConstants.me);
    return CurrentUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async => _api.clearAuth();

  String _resolveRole(dynamic role) {
    if (role is int) {
      switch (role) {
        case 1: return 'USER';
        case 2: return 'ADMIN';
        case 3: return 'AGENT';
        case 4: return 'PROVIDER';
        case 5: return 'SUPER_ADMIN';
        default: return 'UNKNOWN';
      }
    }
    return role.toString().toUpperCase();
  }
}
