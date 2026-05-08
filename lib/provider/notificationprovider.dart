import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/notificationmodel.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;

  late final Realtime _realtime;
  RealtimeSubscription? _subscription;
  StreamSubscription? _streamSub;

  String? _subscribedUserId;

  NotificationProvider() {
    _realtime = Realtime(AppwriteConfig.client);
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => _notifications.any((n) => !n.isRead);

  // ───────────────────────────────────────────
  // HELPER — merge system fields into data map
  // ───────────────────────────────────────────
  Map<String, dynamic> _rowToMap(dynamic row) => {
        ...row.data as Map<String, dynamic>,
        '\$id': row.$id,
        '\$createdAt': row.$createdAt,
        '\$updatedAt': row.$updatedAt,
      };

  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    final res = await AppwriteConfig.functions.createExecution(
      functionId: AppwriteConfig.productFunction,
      body: json.encode(body),
    );
    return json.decode(res.responseBody) as Map<String, dynamic>;
  }

  // ===================== FETCH =====================
  Future<void> fetchNotifications({required String userId}) async {
    if (userId.isEmpty) return;

    // Prevent concurrent fetches
    if (_isLoading) return;

    try {
      _isLoading = true;
      // No notifyListeners() here — batched into the single one in finally

      final List<NotificationModel> all = [];
      const int pageSize = 100;
      const int maxPages = 5; // cap at 500 notifications max
      String? lastId;
      int pageCount = 0;

      while (pageCount < maxPages) {
        final queries = [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(pageSize),
          if (lastId != null) Query.cursorAfter(lastId),
        ];

        final res = await AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.notification,
          queries: queries,
        );

        final rows = res.rows;

        all.addAll(
          rows.map((row) => NotificationModel.fromMap(_rowToMap(row))),
        );

        pageCount++;
        if (rows.length < pageSize) break;
        lastId = rows.last.$id;
      }

      _notifications
        ..clear()
        ..addAll(all);
    } catch (e) {
      // debugPrint("FETCH NOTIFICATIONS ERROR: $e");
    } finally {
      // Single notify covers _isLoading flag + new data
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===================== MARK SINGLE READ =====================
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      final result = await _callFunction({
        'action': 'markNotificationRead',
        'userId': userId,
        'notificationId': notificationId,
      });

      if (result['status'] != true) throw Exception(result['message']);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      // debugPrint("MARK NOTIFICATION READ ERROR: $e");
    }
  }

  // ===================== MARK ALL READ =====================
  Future<void> markAllAsRead(String userId) async {
    try {
      final result = await _callFunction({
        'action': 'markAllNotificationsRead',
        'userId': userId,
      });

      if (result['status'] != true) throw Exception(result['message']);

      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      notifyListeners();
    } catch (e) {
      // debugPrint("MARK ALL READ ERROR: $e");
    }
  }

  // ===================== CLEAR ALL =====================
  Future<void> clearAllNotifications({required String userId}) async {
    try {
      final result = await _callFunction({
        'action': 'clearAllNotifications',
        'userId': userId,
      });

      if (result['status'] != true) throw Exception(result['message']);

      _notifications.removeWhere((n) => n.userId == userId);
      notifyListeners();
    } catch (e) {
      // debugPrint("CLEAR ALL NOTIFICATIONS ERROR: $e");
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // ===================== REALTIME SUBSCRIPTION =====================
  void subscribeToNotifications({required String userId}) {
    if (userId.isEmpty) return;

    if (_subscribedUserId == userId && _subscription != null) return;

    _streamSub?.cancel();
    _streamSub = null;
    _subscription?.close();
    _subscription = null;
    _subscribedUserId = null;

    _subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.tables.${AppwriteConfig.notification}.rows',
    ]);

    _subscribedUserId = userId;

    _streamSub = _subscription!.stream.listen((event) {
      final data = event.payload as Map<String, dynamic>?;
      if (data == null) return;

      final payloadUserId = (data['userId'] ?? '').toString();
      if (payloadUserId != userId) return;

      final eventType = event.events.isNotEmpty ? event.events.first : '';

      if (eventType.contains('rows.create')) {
        final notification = NotificationModel.fromMap(data);
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.insert(0, notification);
          notifyListeners();
        }
      } else if (eventType.contains('rows.update')) {
        final updated = NotificationModel.fromMap(data);
        final index = _notifications.indexWhere((n) => n.id == updated.id);
        if (index != -1) {
          _notifications[index] = updated;
          notifyListeners();
        }
      } else if (eventType.contains('rows.delete')) {
        final deletedId = (data['\$id'] ?? '').toString();
        _notifications.removeWhere((n) => n.id == deletedId);
        notifyListeners();
      }
    });
  }

  // ===================== UNSUBSCRIBE =====================
  void unsubscribe() {
    _streamSub?.cancel();
    _streamSub = null;
    _subscription?.close();
    _subscription = null;
    _subscribedUserId = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
