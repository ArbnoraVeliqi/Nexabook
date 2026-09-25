
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient api;

  AuthProvider(this.api);

  bool loading = false;

  String? token;
  String? name;
  String? email;
  String? role;
  int? userId;

  bool get loggedIn => token != null;

  String get initials {
    final value = name?.trim() ?? '';

    if (value.isEmpty) {
      return 'N';
    }

    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();

    token = preferences.getString('token');
    name = preferences.getString('name');
    email = preferences.getString('email');
    role = preferences.getString('role');
    userId = preferences.getInt('userId');

    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password,
  ) async {
    _setLoading(true);

    try {
      final data = await api.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      await _saveSession(data);

      return true;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String firstName,
    String lastName,
    String email,
    String password,
    String phone,
  ) async {
    _setLoading(true);

    try {
      final data = await api.post(
        '/auth/register',
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'phone': phone.trim(),
        },
      );

      await _saveSession(data);

      return true;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> forgotPassword(
    String email,
  ) async {
    try {
      final data = await api.post(
        '/auth/forgot-password',
        data: {
          'email': email.trim(),
        },
      );

      return data['developmentCode']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> verifyResetCode(
    String email,
    String code,
  ) async {
    try {
      await api.post(
        '/auth/verify-reset-code',
        data: {
          'email': email.trim(),
          'code': code.trim(),
        },
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await api.post(
        '/auth/reset-password',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('token');
    await preferences.remove('name');
    await preferences.remove('email');
    await preferences.remove('role');
    await preferences.remove('userId');

    token = null;
    name = null;
    email = null;
    role = null;
    userId = null;

    notifyListeners();
  }

  Future<void> _saveSession(
    Map<String, dynamic> data,
  ) async {
    final returnedToken = data['token']?.toString();

    if (returnedToken == null || returnedToken.isEmpty) {
      throw Exception(
        'Authentication token was not returned.',
      );
    }

    token = returnedToken;
    name = data['fullName']?.toString();
    email = data['email']?.toString();
    role = data['role']?.toString();

    final returnedUserId = data['userId'];

    if (returnedUserId is int) {
      userId = returnedUserId;
    } else {
      userId = int.tryParse(
        returnedUserId?.toString() ?? '',
      );
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      'token',
      token!,
    );

    if (name != null) {
      await preferences.setString(
        'name',
        name!,
      );
    }

    if (email != null) {
      await preferences.setString(
        'email',
        email!,
      );
    }

    if (role != null) {
      await preferences.setString(
        'role',
        role!,
      );
    }

    if (userId != null) {
      await preferences.setInt(
        'userId',
        userId!,
      );
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    loading = value;
    notifyListeners();
  }
}