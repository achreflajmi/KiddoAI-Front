import 'package:flutter/material.dart';
import '../services/authentication_service.dart';

class AuthenticationViewModel extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String nom, String prenom, String email, String password, String favoriteCharacter, String dateOfBirth) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signup(nom, prenom, email, password, favoriteCharacter, dateOfBirth);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}