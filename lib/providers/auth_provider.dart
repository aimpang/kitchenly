import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _userName = '';
  String _userEmail = '';
  bool _isPremium = false;

  bool get isAuthenticated => _isAuthenticated;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isPremium => _isPremium;

  void togglePremium() {
    _isPremium = !_isPremium;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // Mock login
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    _userEmail = email;
    _userName = email.split('@').first;
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userEmail = '';
    _userName = '';
    notifyListeners();
  }
}
