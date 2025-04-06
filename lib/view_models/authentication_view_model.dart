import 'package:flutter/foundation.dart';
import '../services/authentication_service.dart';

class AuthenticationViewModel extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authService.login(email, password);
      return response;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> signup(String nom, String prenom, String email, 
      String password, String favoriteCharacter, String dateOfBirth, String parentPhoneNumber) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authService.signup(
        nom, prenom, email, password, favoriteCharacter, dateOfBirth, parentPhoneNumber);
      return response;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkLoginStatus() async {
    return await _authService.isLoggedIn();
  }

  Future<String?> getThreadId() async {
    return await _authService.getThreadId();
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}