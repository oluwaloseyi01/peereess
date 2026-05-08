import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/error.dart';
import 'package:peereess/databases/config/errorhandling.dart';

class SpinService extends ChangeNotifier {
  bool isLoading = false;
  bool spinEnabled = false;
  String? errorMessage;

  RealtimeSubscription? _subscription;

  // ── Shared database helper ─────────────────────────────────────────────────

  Databases get _db => Databases(AppwriteConfig.client);
  Realtime get _rt => Realtime(AppwriteConfig.client);

  // ── 1. Fetch current spin_enabled value ────────────────────────────────────
  /// Call this once when the app starts (e.g. in initState of HomeScreen
  /// or inside a ProxyProvider/init block).
  Future<void> fetchSpinConfig() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // debugPrint('🔵 SpinService: fetchSpinConfig');

      final doc = await _db.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.spinConfigCollection,
        documentId: AppwriteConfig.spinConfigDocumentId,
      );

      spinEnabled = doc.data['spin_enabled'] as bool? ?? false;
      // debugPrint('🟢 SpinService: spin_enabled = $spinEnabled');
    } on SocketException {
      errorMessage = 'No internet connection';
      // debugPrint('🔴 SpinService: No internet');
    } catch (e, st) {
      errorMessage = AppError.from(e).message;
      // debugPrint('🔴 SpinService fetchSpinConfig ERROR: $e\n$st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 2. Subscribe to Realtime ───────────────────────────────────────────────
  /// Call this once after fetchSpinConfig().
  /// When the admin flips spin_enabled in Appwrite → spinEnabled updates here
  /// → every widget listening via Consumer/context.watch() rebuilds instantly.
  void subscribeRealtime() {
    if (_subscription != null) return; // already subscribed

    final channel = 'databases.${AppwriteConfig.databaseId}'
        '.collections.${AppwriteConfig.spinConfigCollection}'
        '.documents.${AppwriteConfig.spinConfigDocumentId}';

    // debugPrint('🔵 SpinService: subscribing to $channel');

    _subscription = _rt.subscribe([channel]);

    _subscription!.stream.listen(
      (RealtimeMessage event) {
        final isUpdate = event.events.any(
          (e) =>
              e.contains('documents') &&
              (e.contains('update') || e.contains('create')),
        );

        if (isUpdate) {
          final bool enabled = event.payload['spin_enabled'] as bool? ?? false;
          // debugPrint('🟢 SpinService Realtime: spin_enabled → $enabled');
          spinEnabled = enabled;
          notifyListeners();
        }
      },
      onError: (e) {
        // debugPrint('🔴 SpinService Realtime error: $e');
      },
    );
  }

  // ── 3. Admin — toggle spin on / off ───────────────────────────────────────
  /// Updates the document in Appwrite.
  /// The Realtime listener above fires automatically on all users' devices.
  /// We also update locally for instant admin UI feedback.
  Future<bool> setSpinEnabled({
    required bool value,
    required String adminId, // for audit / permission check on backend
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // debugPrint('🔵 SpinService: setSpinEnabled → $value (admin: $adminId)');

      await _db.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.spinConfigCollection,
        documentId: AppwriteConfig.spinConfigDocumentId,
        data: {'spin_enabled': value},
      );

      // Optimistic local update — Realtime will confirm
      spinEnabled = value;
      // debugPrint('🟢 SpinService: spin_enabled updated to $value');
      return true;
    } on SocketException {
      errorMessage = 'No internet connection';
      // debugPrint('🔴 SpinService: No internet');
      return false;
    } catch (e, st) {
      errorMessage = AppError.from(e).message;
      // debugPrint('🔴 SpinService setSpinEnabled ERROR: $e\n$st');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}
