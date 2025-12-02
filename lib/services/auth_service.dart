import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  User? _currentUser;
  String? _token;

  /// Usuario actual autenticado
  User? get currentUser => _currentUser;
  
  /// Token de autenticación
  String? get token => _token;
  
  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Inicializa el servicio cargando los datos guardados
  Future<void> initialize() async {
    await _loadStoredAuth();
  }

  /// Carga datos de autenticación guardados
  Future<void> _loadStoredAuth() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      final userData = await _storage.read(key: _userKey);
      
      if (_token != null && userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      await clearAuth();
    }
  }

  /// Guarda datos de autenticación
  Future<void> _saveAuth(String token, User user) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      _token = token;
      _currentUser = user;
    } catch (e) {
      print('Error saving auth: $e');
      throw Exception('Error al guardar credenciales');
    }
  }

  /// Limpia datos de autenticación
  Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    _token = null;
    _currentUser = null;
  }

  /// Registra un nuevo usuario
  Future<User> register(String email, String password) async {
    try {
      final response = await _apiService.register(email, password);
      // El registro retorna el usuario pero no el token, hay que hacer login después
      return User.fromJson(response);
    } catch (e) {
      print('Error en registro: $e');
      rethrow;
    }
  }

  /// Inicia sesión
  Future<User> login(String email, String password) async {
    try {
      final authResponse = await _apiService.login(email, password);
      await _saveAuth(authResponse.accessToken, authResponse.user);
      return authResponse.user;
    } catch (e) {
      print('Error en login: $e');
      rethrow;
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    await clearAuth();
  }

  /// Obtiene información del usuario actual
  Future<User> getCurrentUser() async {
    if (_token == null) {
      throw Exception('No autenticado');
    }
    
    try {
      final userData = await _apiService.getCurrentUser(_token!);
      final user = User.fromJson(userData);
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      // Si el token es inválido, limpiar autenticación
      await clearAuth();
      rethrow;
    }
  }

  /// Valida si el token sigue siendo válido
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}
