import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => 'AuthFailure: $message';
}

class _LocalUser {
  final String email;
  final String password;
  final String name;

  const _LocalUser({required this.email, required this.password, required this.name});

  Map<String, dynamic> toJson() => {'email': email, 'password': password, 'name': name};

  static _LocalUser? fromJson(Map<String, dynamic> json) {
    try {
      final email = (json['email'] as String?)?.trim().toLowerCase() ?? '';
      final password = (json['password'] as String?) ?? '';
      final name = (json['name'] as String?)?.trim() ?? '';
      if (email.isEmpty || password.isEmpty) return null;
      return _LocalUser(email: email, password: password, name: name.isEmpty ? email.split('@').first : name);
    } catch (_) {
      return null;
    }
  }
}

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _userName = '';
  String _userEmail = '';
  bool _isPremium = false;

  static const _usersPrefsKey = 'auth_users_v1';
  static const _sessionPrefsKey = 'auth_session_v1';

  SharedPreferences? _prefsCache;
  Future<SharedPreferences> get _prefs async => _prefsCache ??= await SharedPreferences.getInstance();

  AuthProvider() {
    _hydrateFromPrefs();
  }

  bool get isAuthenticated => _isAuthenticated;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isPremium => _isPremium;
  bool get needsOnboarding => _isAuthenticated && _userName.isEmpty;

  void togglePremium() {
    _isPremium = !_isPremium;
    notifyListeners();
  }

  Future<List<_LocalUser>> _loadUsers() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_usersPrefsKey);
      if (raw == null || raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final users = <_LocalUser>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final u = _LocalUser.fromJson(e);
          if (u != null) users.add(u);
        } else if (e is Map) {
          final u = _LocalUser.fromJson(e.map((k, v) => MapEntry(k.toString(), v)));
          if (u != null) users.add(u);
        }
      }
      return users;
    } catch (e) {
      debugPrint('AuthProvider: failed to load users: $e');
      return [];
    }
  }

  Future<void> _saveUsers(List<_LocalUser> users) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_usersPrefsKey, jsonEncode(users.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('AuthProvider: failed to save users: $e');
    }
  }

  Future<void> _saveSession({required String email}) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_sessionPrefsKey, jsonEncode({'email': email}));
    } catch (e) {
      debugPrint('AuthProvider: failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_sessionPrefsKey);
    } catch (e) {
      debugPrint('AuthProvider: failed to clear session: $e');
    }
  }

  Future<void> _hydrateFromPrefs() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_sessionPrefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final email = (decoded['email'] as String?)?.trim().toLowerCase() ?? '';
      if (email.isEmpty) return;

      final users = await _loadUsers();
      final existing = users.where((u) => u.email == email).toList();
      if (existing.isEmpty) return;
      _isAuthenticated = true;
      _userEmail = email;
      _userName = existing.first.name;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: failed to hydrate session: $e');
    }
  }

  Future<void> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) throw const AuthFailure('Email is required.');
    if (password.isEmpty) throw const AuthFailure('Password is required.');

    // Simulate network latency for nicer UX.
    await Future.delayed(const Duration(milliseconds: 600));

    final users = await _loadUsers();
    final match = users.where((u) => u.email == normalizedEmail).toList();
    if (match.isEmpty) throw const AuthFailure("No account found for that email.");
    if (match.first.password != password) throw const AuthFailure('Incorrect password.');

    _isAuthenticated = true;
    _userEmail = normalizedEmail;
    _userName = match.first.name;
    await _saveSession(email: normalizedEmail);
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) throw const AuthFailure('Email is required.');
    if (password.length < 6) throw const AuthFailure('Password must be at least 6 characters.');

    await Future.delayed(const Duration(milliseconds: 600));

    final users = await _loadUsers();
    if (users.any((u) => u.email == normalizedEmail)) {
      throw const AuthFailure('An account with that email already exists.');
    }

    final updated = [...users, _LocalUser(email: normalizedEmail, password: password, name: '')];
    await _saveUsers(updated);

    _isAuthenticated = true;
    _userEmail = normalizedEmail;
    _userName = '';
    await _saveSession(email: normalizedEmail);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw const AuthFailure('Name is required.');
    if (!_isAuthenticated) throw const AuthFailure('Not authenticated.');

    await Future.delayed(const Duration(milliseconds: 300));

    final users = await _loadUsers();
    final updatedUsers = users.map((u) {
      if (u.email == _userEmail) {
        return _LocalUser(email: u.email, password: u.password, name: trimmedName);
      }
      return u;
    }).toList();

    await _saveUsers(updatedUsers);
    _userName = trimmedName;
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userEmail = '';
    _userName = '';
    await _clearSession();
    notifyListeners();
  }
}
