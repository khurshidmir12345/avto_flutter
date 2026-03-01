import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<({bool success, String message})> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.login(phone, password);
    if (result.success) {
      _user = result.user;
    }

    _isLoading = false;
    notifyListeners();

    return (success: result.success, message: result.message);
  }

  Future<({bool success, String message})> register(
      String name, String phone, String password, String passwordConfirmation) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.register(name, phone, password, passwordConfirmation);

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.verifyOtp(phone, code);
    if (result.success) {
      _user = result.user;
    }

    _isLoading = false;
    notifyListeners();

    return result.success;
  }

  Future<void> loadUser() async {
    _user = await _apiService.getCurrentUser();
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    notifyListeners();
  }
}
