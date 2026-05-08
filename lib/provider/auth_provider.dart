import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart' hide Permission;
import 'package:appwrite/enums.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/error.dart';
import 'package:peereess/databases/config/errorhandling.dart';
import 'package:peereess/model/user.dart';
import 'package:peereess/provider/verifyemailsignup.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthProvider extends ChangeNotifier {
  // ===================== CONTROLLERS =====================
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController phoneCodeController = TextEditingController();
  final TextEditingController receiverFullNameController =
      TextEditingController();
  final TextEditingController statesController = TextEditingController();
  final TextEditingController deliveryAddressController =
      TextEditingController();
  final TextEditingController deliveryPhoneNumberController =
      TextEditingController();

  // ===================== STATE (IN-MEMORY ONLY) ==========
  bool isLoading = false;
  bool isLoggedIn = false;
  bool isInitialized = false;
  bool isConnected = true;
  String? errorMessage;

  String? _userId;
  String? _rowId;
  String userType = 'user';

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  UserModel? currentUserData;

  // ===================== SESSION TIMER ===================
  Timer? _sessionTimer;

  // Session duration — must match your Appwrite session TTL
  static const Duration _sessionDuration = Duration(hours: 8);

  void _startSessionTimer(BuildContext? context) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionDuration, () {
      // debugPrint('⏱ SESSION EXPIRED: auto logout triggered');
      if (context != null && context.mounted) {
        logOut(context);
      } else {
        logOutWithoutContext();
      }
    });
  }

  void _cancelSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // ===================== CONNECTIVITY ====================
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  AuthProvider() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final wasConnected = isConnected;
      isConnected = result != ConnectivityResult.none;

      if (wasConnected != isConnected) {
        if (isConnected && isLoggedIn) {
          clearError();
          fetchUserData();
        } else {
          setError('No internet connection');
        }
        notifyListeners();
      }
    });
  }

  // ===================== GETTERS ========================
  String? get userId => currentUserData?.userId ?? _userId;
  String get role => userType;
  String? get rowId => _rowId;
  String? get receiverFullName => currentUserData?.receiverFullName;
  String? get deliveryAddress => currentUserData?.deliveryAddress;
  String? get state => currentUserData?.state;
  String? get deliveryPhoneNumber => currentUserData?.deliveryPhoneNumber;
  bool get hasAddress => deliveryAddress?.isNotEmpty == true;

  // ===================== INIT ===========================
  /// Called once on app start. Checks if an Appwrite session already exists
  /// (cookie/token is managed by the Appwrite SDK — no SharedPreferences needed).
  Future<void> initAuth() async {
    if (isInitialized) return; // ✅ guard: only run once

    isLoading = true;
    notifyListeners();

    try {
      final currentUser = await ApiHelper.guard(
        () => AppwriteConfig.account.get(),
      );

      if (currentUser != null) {
        _userId = currentUser.$id;

        final results = await Future.wait([
          _callFunction({'action': 'getProfile', 'userId': _userId}),
          _callFunction({'action': 'getRole', 'userId': _userId}),
        ]);

        final profileResult = results[0];
        final roleResult = results[1];

        if (profileResult['status'] == true) {
          final profileData = profileResult['data'] as Map<String, dynamic>;
          _rowId = profileData['rowId'] as String;
          currentUserData = UserModel.fromMap(profileData);
        }

        userType = roleResult['status'] == true
            ? (roleResult['data']['role'] as String? ?? 'user').toLowerCase()
            : 'user';

        isLoggedIn = true;
        _populateControllers();
        _startSessionTimer(null);

        // debugPrint('✅ initAuth: session restored for $_userId role=$userType');
      } else {
        isLoggedIn = false;
        // debugPrint('ℹ️ initAuth: no active session found');
      }
    } on SocketException {
      isLoggedIn = false;
      setError('No internet connection. Please connect and restart.');
    } catch (e) {
      isLoggedIn = false;
      // debugPrint('⚠️ initAuth error: $e');
    }

    isInitialized = true;
    isLoading = false;
    notifyListeners();
  }

  // ===================== REGISTER =======================
  Future<void> register(BuildContext context) async {
    try {
      isLoading = true;
      clearError();
      notifyListeners();

      final String email = emailController.text.trim();
      final String fullName = fullNameController.text.trim();
      final String password = passwordController.text.trim();

      // debugPrint('📧 REGISTER: Starting for $email');

      // 1️⃣ Check email via server
      final checkResult = await _callFunction({
        'action': 'checkEmail',
        'email': email,
      });

      if (checkResult['status'] != true) {
        throw Exception(checkResult['message'] ?? 'Email already registered.');
      }

      // 2️⃣ Create Appwrite auth account
      // ✅ isAuthAction: true — rethrows 400/409 so the real error shows to the user
      final user = await ApiHelper.guard(
        () => AppwriteConfig.account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: fullName,
        ),
        isAuthAction: true,
      );
      if (user == null) return;

      // 3️⃣ Create DB row via server
      final createResult = await _callFunction({
        'action': 'createAccount',
        'userId': user.$id,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumberController.text.trim(),
        'lastActive': DateTime.now().toIso8601String(),
        'phoneCode': phoneCodeController.text.trim(),
        'receiverFullName': receiverFullNameController.text.trim(),
        'state': statesController.text.trim(),
        'deliveryAddress': deliveryAddressController.text.trim(),
        'deliveryPhoneNumber': deliveryPhoneNumberController.text.trim(),
      });

      if (createResult['status'] != true) {
        try {
          await ApiHelper.guard(() => AppwriteConfig.account.deleteSessions());
        } catch (_) {}
        throw Exception(createResult['message'] ?? 'Failed to create account.');
      }

      // 4️⃣ Save IDs in memory only
      _userId = user.$id;
      _rowId = createResult['data']['rowId'] as String;

      // 5️⃣ Send OTP
      await EmailVerificationService.sendOtp(email);

      if (!context.mounted) return;
      Navigator.pushNamed(
        context,
        '/verifyemail',
        arguments: {'email': email, 'password': password, 'userId': user.$id},
      );
    } catch (e, st) {
      // debugPrint('❌ REGISTER ERROR: $e\n$st');
      if (!context.mounted) return;
      ErrorNotifier.show(context, AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleSignIn(BuildContext context) async {
    try {
      isLoading = true;
      clearError();
      notifyListeners();

      // 1️⃣ Trigger Appwrite OAuth2 Google session
      await AppwriteConfig.account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: 'https://peereess.com',
        failure: 'https://peereess.com',
      );

      // 2️⃣ Get the created Appwrite user
      final currentUser = await ApiHelper.guard(
        () => AppwriteConfig.account.get(),
      );
      if (currentUser == null) return;

      _userId = currentUser.$id;
      final email = currentUser.email;
      final fullName = currentUser.name;

      // 3️⃣ Upsert user row in your DB via function
      final result = await _callFunction({
        'action': 'googleSignIn',
        'userId': _userId,
        'email': email,
        'fullName': fullName,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Google sign-in failed.');
      }

      // 4️⃣ Fetch full profile and role
      final results = await Future.wait([
        _callFunction({'action': 'getProfile', 'userId': _userId}),
        _callFunction({'action': 'getRole', 'userId': _userId}),
        _callFunction({'action': 'updateLastActive', 'userId': _userId}),
      ]);

      final profileResult = results[0];
      final roleResult = results[1];

      if (profileResult['status'] == true) {
        final profileData = profileResult['data'] as Map<String, dynamic>;
        _rowId = profileData['rowId'] as String;
        currentUserData = UserModel.fromMap(profileData);
      }

      userType = roleResult['status'] == true
          ? (roleResult['data']['role'] as String? ?? 'user').toLowerCase()
          : 'user';

      isLoggedIn = true;
      _populateControllers();
      _startSessionTimer(context);

      if (!context.mounted) return;

      // ✅ Skip email verification entirely — go straight to notification permission page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/pushnotification', // ✅ your notification permission page route
          (_) => false,
        );
      });
    } catch (e, st) {
      // debugPrint('❌ GOOGLE SIGN IN ERROR: $e\n$st');
      if (!context.mounted) return;
      ErrorNotifier.show(context, AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== LOGIN ==========================
  // ===============================================
  // UPDATED AUTH PROVIDER WITH LAST ACTIVE
  // ===============================================

  Future<void> login(BuildContext context) async {
    try {
      isLoading = true;
      clearError();
      notifyListeners();

      // ✅ isAuthAction: true — rethrows 401 so "Invalid email or password" shows
      await ApiHelper.guard(
        () => AppwriteConfig.account.createEmailPasswordSession(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        ),
        isAuthAction: true,
      );

      final currentUser = await ApiHelper.guard(
        () => AppwriteConfig.account.get(),
      );
      if (currentUser == null) return;

      _userId = currentUser.$id;
      // debugPrint('✅ LOGIN: Session created for userId: $_userId');

      final results = await Future.wait([
        _callFunction({'action': 'getProfile', 'userId': _userId}),
        _callFunction({'action': 'getRole', 'userId': _userId}),
        // ✅ Update last active on login
        _callFunction({'action': 'updateLastActive', 'userId': _userId}),
      ]);

      final profileResult = results[0];
      final roleResult = results[1];
      // results[2] is lastActive update (we don't need to check it)

      if (profileResult['status'] != true) {
        throw Exception(profileResult['message'] ?? 'User profile not found.');
      }

      final profileData = profileResult['data'] as Map<String, dynamic>;
      _rowId = profileData['rowId'] as String;
      currentUserData = UserModel.fromMap(profileData);

      userType = roleResult['status'] == true
          ? (roleResult['data']['role'] as String? ?? 'user').toLowerCase()
          : 'user';

      // debugPrint("✅ LOGIN: role='$userType' rowId='$_rowId'");

      isLoggedIn = true;
      _populateControllers();
      _startSessionTimer(context);

      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _navigateByRole(context),
      );
    } catch (e, st) {
      // debugPrint('❌ LOGIN ERROR: $e\n$st');
      if (!context.mounted) return;
      ErrorNotifier.show(context, AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Add this method to update last active anytime
  Future<void> updateLastActive() async {
    if (_userId == null || _userId!.isEmpty) return;

    try {
      await _callFunction({'action': 'updateLastActive', 'userId': _userId});
      // debugPrint('✅ Last active updated');
    } catch (e) {
      // debugPrint('❌ Failed to update last active: $e');
      // Don't throw - this is a background operation
    }
  }

  /// Returns true if the old password is correct, false otherwise.
  Future<bool> verifyOldPassword(String oldPassword) async {
    if (_userId == null || currentUserData?.email == null) return false;

    try {
      // Try to create a session with current email and provided old password
      await ApiHelper.guard(
        () => AppwriteConfig.account.createEmailPasswordSession(
          email: currentUserData!.email!,
          password: oldPassword,
        ),
        isAuthAction: true, // so Appwrite errors (like 401) are caught
      );

      // If no exception, old password is correct
      // Delete the temporary session we just created
      await ApiHelper.guard(() => AppwriteConfig.account.deleteSessions());
      return true;
    } catch (_) {
      // Any error = wrong password
      return false;
    }
  }

  // ===================== FETCH USER DATA ================
  Future<void> fetchUserData() async {
    if (isLoading) return; // ✅ prevent double-fetch loops

    isLoading = true;
    notifyListeners();

    try {
      if (!isConnected) {
        setError('No internet connection');
        isLoading = false;
        notifyListeners();
        return;
      }

      if (_userId == null) return;

      final results = await Future.wait([
        _callFunction({'action': 'getProfile', 'userId': _userId}),
        _callFunction({'action': 'getRole', 'userId': _userId}),
      ]);

      final profileResult = results[0];
      final roleResult = results[1];

      if (profileResult['status'] == true) {
        final profileData = profileResult['data'] as Map<String, dynamic>;
        _rowId = profileData['rowId'] as String;
        currentUserData = UserModel.fromMap(profileData);
      }

      if (roleResult['status'] == true) {
        userType =
            (roleResult['data']['role'] as String? ?? 'user').toLowerCase();
      }

      _populateControllers();
    } on SocketException {
      setError('No internet connection');
    } catch (e) {
      setError(AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== COMPLETE REGISTRATION ================
  Future<void> completeRegistration(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUser = await ApiHelper.guard(
        () => AppwriteConfig.account.get(),
      );
      if (currentUser == null) return;
      _userId = currentUser.$id;

      final results = await Future.wait([
        _callFunction({'action': 'getProfile', 'userId': _userId}),
        _callFunction({'action': 'getRole', 'userId': _userId}),
      ]);

      final profileResult = results[0];
      final roleResult = results[1];

      if (profileResult['status'] == true) {
        final profileData = profileResult['data'] as Map<String, dynamic>;
        _rowId = profileData['rowId'] as String;
        currentUserData = UserModel.fromMap(profileData);
      }

      userType = roleResult['status'] == true
          ? (roleResult['data']['role'] as String? ?? 'user').toLowerCase()
          : 'user';

      isLoggedIn = true;
      _populateControllers();
      _startSessionTimer(context);

      // debugPrint("✅ completeRegistration: isLoggedIn=true role=$userType");
    } catch (e) {
      // debugPrint("❌ completeRegistration ERROR: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== UPDATE USER ROW ================
  Future<void> updateUserRow({
    bool updateFullName = false,
    bool updateEmail = false,
    bool updatePhoneNumber = false,
    bool updateReceiverName = false,
    bool updatePhoneCode = false,
    bool updateState = false,
    bool updateDeliveryAddress = false,
    bool updateDeliveryPhoneNumber = false,
  }) async {
    try {
      isLoading = true;
      clearError();
      notifyListeners();

      if (_userId == null || _rowId == null) return;

      final Map<String, dynamic> profilePayload = {
        'action': 'updateProfile',
        'userId': _userId,
        'rowId': _rowId,
      };
      if (updateFullName)
        profilePayload['fullName'] = fullNameController.text.trim();
      if (updatePhoneNumber)
        profilePayload['phoneNumber'] = phoneNumberController.text.trim();
      if (updatePhoneCode)
        profilePayload['phoneCode'] = phoneCodeController.text.trim();

      final Map<String, dynamic> addressPayload = {
        'action': 'updateAddress',
        'userId': _userId,
        'rowId': _rowId,
      };
      if (updateReceiverName)
        addressPayload['receiverFullName'] =
            receiverFullNameController.text.trim();
      if (updateState) addressPayload['state'] = statesController.text.trim();
      if (updateDeliveryAddress)
        addressPayload['deliveryAddress'] =
            deliveryAddressController.text.trim();
      if (updateDeliveryPhoneNumber)
        addressPayload['deliveryPhoneNumber'] =
            deliveryPhoneNumberController.text.trim();

      final futures = <Future>[];
      if (profilePayload.length > 3) futures.add(_callFunction(profilePayload));
      if (addressPayload.length > 3) futures.add(_callFunction(addressPayload));

      if (futures.isEmpty) return;

      final results = await Future.wait(futures);
      for (final result in results) {
        if (result['status'] != true) {
          throw Exception(result['message'] ?? 'Failed to update.');
        }
      }

      currentUserData = currentUserData?.copyWith(
        fullName: updateFullName ? fullNameController.text.trim() : null,
        phoneNumber:
            updatePhoneNumber ? phoneNumberController.text.trim() : null,
        phoneCode: updatePhoneCode ? phoneCodeController.text.trim() : null,
        receiverFullName:
            updateReceiverName ? receiverFullNameController.text.trim() : null,
        state: updateState ? statesController.text.trim() : null,
        deliveryAddress: updateDeliveryAddress
            ? deliveryAddressController.text.trim()
            : null,
        deliveryPhoneNumber: updateDeliveryPhoneNumber
            ? deliveryPhoneNumberController.text.trim()
            : null,
      );

      notifyListeners();
    } catch (e) {
      setError(AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== DELETE ADDRESS =================
  Future<void> deleteAddress() async {
    try {
      isLoading = true;
      clearError();
      notifyListeners();

      if (_userId == null || _rowId == null) return;

      final result = await _callFunction({
        'action': 'deleteAddress',
        'userId': _userId,
        'rowId': _rowId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to delete address.');
      }

      receiverFullNameController.clear();
      deliveryAddressController.clear();
      statesController.clear();
      deliveryPhoneNumberController.clear();

      currentUserData = currentUserData?.copyWith(
        receiverFullName: '',
        deliveryAddress: '',
        state: '',
        deliveryPhoneNumber: '',
      );

      notifyListeners();
    } catch (e) {
      setError(AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== UPDATE PASSWORD ================
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (currentUserData == null) {
      setError('Please login again.');
      notifyListeners();
      return;
    }

    try {
      isLoading = true;
      clearError();
      notifyListeners();

      // ✅ isAuthAction: true — rethrows 401 (wrong old password) to show real error
      await ApiHelper.guard(
        () => AppwriteConfig.account.updatePassword(
          password: newPassword,
          oldPassword: oldPassword,
        ),
        isAuthAction: true,
      );
    } catch (e) {
      setError(AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== DELETE ACCOUNT =================
  Future<void> deleteAccount(BuildContext context) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (_userId == null || _rowId == null) return;

      final result = await _callFunction({
        'action': 'deleteAccount',
        'userId': _userId,
        'rowId': _rowId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to delete account.');
      }

      _clearMemory();

      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    } catch (e) {
      setError(AppError.from(e).message);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== LOGOUT =========================
  Future<void> logOut(BuildContext context) async {
    try {
      await ApiHelper.guard(() => AppwriteConfig.account.deleteSessions());
    } catch (_) {}

    clearControllers();
    _clearMemory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    });
  }

  Future<void> logOutWithoutContext() async {
    try {
      await ApiHelper.guard(() => AppwriteConfig.account.deleteSessions());
    } catch (_) {}
    _clearMemory();
  }

  // ===================== NOTIFICATIONS ==================
  Future<void> loadNotificationPreference() async {
    final status = await Permission.notification.status;
    _notificationsEnabled = status.isGranted;
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      _notificationsEnabled = status.isGranted;
      if (status.isPermanentlyDenied) await openAppSettings();
    } else {
      _notificationsEnabled = false;
    }
    notifyListeners();
  }

  // ===================== LOCAL SETTERS ==================
  void updateDeliveryAddress(String value) {
    deliveryAddressController.text = value;
    currentUserData = currentUserData?.copyWith(deliveryAddress: value);
    notifyListeners();
  }

  void updateReceiverFullName(String value) {
    receiverFullNameController.text = value;
    currentUserData = currentUserData?.copyWith(receiverFullName: value);
    notifyListeners();
  }

  void updatePhoneCode(String value) {
    phoneCodeController.text = value;
    currentUserData = currentUserData?.copyWith(phoneCode: value);
    notifyListeners();
  }

  void updateState(String value) {
    statesController.text = value;
    currentUserData = currentUserData?.copyWith(state: value);
    notifyListeners();
  }

  void updateDeliveryPhoneNumber(String value) {
    deliveryPhoneNumberController.text = value;
    currentUserData = currentUserData?.copyWith(deliveryPhoneNumber: value);
    notifyListeners();
  }

  // ===================== ERROR HELPERS ==================
  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
  }

  // ===================== PRIVATE HELPERS ================
  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    // debugPrint('🔵 _callFunction: ${body['action']} → ${json.encode(body)}');
    try {
      final res = await ApiHelper.guard(
        () => AppwriteConfig.functions.createExecution(
          functionId: AppwriteConfig.createUserFunction,
          body: json.encode(body),
        ),
      );
      if (res == null) {
        throw Exception('Session expired. Please log in again.');
      }

      return json.decode(res.responseBody) as Map<String, dynamic>;
    } catch (e, st) {
      // debugPrint('🔴 _callFunction ERROR [${body['action']}]: $e\n$st');
      rethrow;
    }
  }

  void _populateControllers() {
    fullNameController.text = currentUserData?.fullName ?? '';
    emailController.text = currentUserData?.email ?? '';
    phoneNumberController.text = currentUserData?.phoneNumber ?? '';
    receiverFullNameController.text = currentUserData?.receiverFullName ?? '';
    phoneCodeController.text = currentUserData?.phoneCode ?? '';
    statesController.text = currentUserData?.state ?? '';
    deliveryAddressController.text = currentUserData?.deliveryAddress ?? '';
    deliveryPhoneNumberController.text =
        currentUserData?.deliveryPhoneNumber ?? '';
  }

  /// Clears all in-memory auth state and cancels the session timer.
  void _clearMemory() {
    _cancelSessionTimer();
    isLoggedIn = false;
    currentUserData = null;
    _userId = null;
    _rowId = null;
    userType = 'user';
    notifyListeners();
  }

  void _navigateByRole(BuildContext context) {
    if (userType == 'admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/adminhome', (_) => false);
    } else if (userType == 'seller') {
      Navigator.pushNamedAndRemoveUntil(context, '/sellerhome', (_) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  void clearControllers() {
    errorMessage = null;
    fullNameController.clear();
    emailController.clear();
    statesController.clear();
    deliveryAddressController.clear();
    passwordController.clear();
    phoneNumberController.clear();
    receiverFullNameController.clear();
    phoneCodeController.clear();
    deliveryPhoneNumberController.clear();
  }

  @override
  void dispose() {
    _cancelSessionTimer();
    _connectivitySubscription.cancel();
    fullNameController.dispose();
    emailController.dispose();
    statesController.dispose();
    deliveryAddressController.dispose();
    passwordController.dispose();
    phoneNumberController.dispose();
    receiverFullNameController.dispose();
    phoneCodeController.dispose();
    deliveryPhoneNumberController.dispose();
    super.dispose();
  }
}
