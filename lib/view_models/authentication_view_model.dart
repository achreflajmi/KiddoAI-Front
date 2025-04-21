// lib/view_models/authentication_view_model.dart
import 'package:flutter/foundation.dart';
import '../services/authentication_service.dart';

class AuthenticationViewModel extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? m) { _errorMessage = m; notifyListeners(); }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    _setLoading(true); _setError(null);
    try {
      return await _authService.login(email, password);
    } catch (e) {
      _setError(e.toString()); return null;
    } finally {
      _setLoading(false);
    }
  }
Future<Map<String, dynamic>?> fetchCurrentUser() async {
  try {
    return await _authService.getCurrentUser();
  } catch (e) {
    print('❌ Failed to fetch current user: $e');
    return null;
  }
}

  Future<Map<String, dynamic>?> signup(
    String nom,
    String prenom,
    String email,
    String password,
    String favoriteCharacter,
    String dateOfBirth,
    String parentPhoneNumber,
    String classe,
  ) async {
    _setLoading(true); _setError(null);
    try {
      return await _authService.signup(
        nom, prenom, email, password,
        favoriteCharacter, dateOfBirth,
        parentPhoneNumber, classe,
      );
    } catch (e) {
      _setError(e.toString()); return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkLoginStatus() => _authService.isLoggedIn();
  Future<String?> getThreadId()     => _authService.getThreadId();
  Future<void> logout() async       { await _authService.logout(); notifyListeners(); }
}
