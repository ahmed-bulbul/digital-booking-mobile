import 'package:flutter/foundation.dart';
import '../data/models/auth_models.dart';
import '../data/services/auth_service.dart';
import '../data/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;

  CurrentUser? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._authService, this._apiService);

  CurrentUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _apiService.isLoggedIn;

  Future<bool> tryRestoreSession() async {
    if (!_apiService.isLoggedIn) return false;
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
      return true;
    } catch (_) {
      await _authService.logout();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.login(email, password);
      _user = await _authService.getCurrentUser();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.register(name, email, phone, password);
      _user = await _authService.getCurrentUser();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
