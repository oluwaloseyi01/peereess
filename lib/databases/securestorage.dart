import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing authentication data
/// Install: flutter_secure_storage: ^9.0.0
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginTimeKey = 'last_login_time';

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save user email (for quick biometric login)
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  /// Get saved user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Save last login time
  Future<void> saveLastLoginTime() async {
    await _storage.write(
      key: _lastLoginTimeKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Get last login time
  Future<DateTime?> getLastLoginTime() async {
    final value = await _storage.read(key: _lastLoginTimeKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Check if session is still valid (within 7 days)
  Future<bool> isSessionValid({int maxDays = 7}) async {
    final lastLogin = await getLastLoginTime();
    if (lastLogin == null) return false;

    final difference = DateTime.now().difference(lastLogin);
    return difference.inDays < maxDays;
  }

  /// Save complete login data
  Future<void> saveLoginData({
    required String authToken,
    String? refreshToken,
    String? email,
  }) async {
    await saveAuthToken(authToken);
    if (refreshToken != null) await saveRefreshToken(refreshToken);
    if (email != null) await saveUserEmail(email);
    await saveLastLoginTime();
  }

  /// Clear all authentication data (logout)
  Future<void> clearAll() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _lastLoginTimeKey);
    await _storage.delete(key: _biometricEnabledKey);
  }

  /// Clear only tokens (keep biometric preference)
  Future<void> clearTokens() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _lastLoginTimeKey);
  }

  /// Check if user has previously logged in
  Future<bool> hasLoginData() async {
    final token = await getAuthToken();
    return token != null;
  }
}
