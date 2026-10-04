// import 'package:flutter/material.dart';

// import '../models/user_model.dart';
// import '../services/auth_service.dart';

// class AuthProvider extends ChangeNotifier {
//   final AuthService _authService = AuthService();

//   UserModel? _user;

//   bool _isLoading = false;

//   String? _errorMessage;

//   UserModel? get user => _user;

//   bool get isLoading => _isLoading;

//   String? get errorMessage => _errorMessage;

//   bool get isLoggedIn => _user != null;

//   Future<bool> register({
//     required String name,
//     required String email,
//     required String password,
//   }) async {
//     _setLoading(true);

//     try {
//       _errorMessage = null;

//       _user = await _authService.register(
//         name: name,
//         email: email,
//         password: password,
//       );

//       _setLoading(false);

//       return _user != null;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst(
//         'Exception: ',
//         '',
//       );

//       _setLoading(false);

//       return false;
//     }
//   }

//   Future<bool> login({
//     required String email,
//     required String password,
//   }) async {
//     _setLoading(true);

//     try {
//       _errorMessage = null;

//       _user = await _authService.login(
//         email: email,
//         password: password,
//       );

//       _setLoading(false);

//       return _user != null;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst(
//         'Exception: ',
//         '',
//       );

//       _setLoading(false);

//       return false;
//     }
//   }

//   Future<void> logout() async {
//     await _authService.logout();

//     _user = null;

//     notifyListeners();
//   }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;

  bool _isLoading = false;

  String? _errorMessage;

  // =========================
  // GETTERS
  // =========================

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _user != null;

  // =========================
  // REGISTER
  // =========================

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _user = await _authService
          .register(name: name, email: email, password: password)
          .timeout(const Duration(seconds: 20));

      return _user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _user = await _authService
          .login(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      debugPrint(_user!.email.toLowerCase());

      return _user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<bool> logout() async {
    try {
      await _authService.logout();

      _user = null;
      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      notifyListeners();

      return false;
    }
  }

  // =========================
  // CLEAR ERROR
  // =========================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }
}
