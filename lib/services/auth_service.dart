// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check hardcoded credentials
    if (email == "andrew@gmail.com" && password == "123456") {
      _currentUser = User(
        id: "1",
        name: "Andrew",
        email: "andrew@gmail.com",
        avatar: "https://via.placeholder.com/150",
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
