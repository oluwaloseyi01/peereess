import 'dart:convert';
import 'dart:io';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:image_picker/image_picker.dart';
import 'package:peereess/provider/cloudinaryservice.dart';
import 'package:uuid/uuid.dart';

import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/adminchatmodel.dart';

class AdminChatProvider extends ChangeNotifier {
  // ───────────────────────────────────────────
  // STATE
  // ───────────────────────────────────────────
  final List<AdminChatModel> _messages = [];
  bool _isLoading = false;
  bool _isDisposed = false;

  String? _openProductId;
  String? _openUserId;

  List<AdminChatModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // ───────────────────────────────────────────
  // REALTIME
  // ───────────────────────────────────────────
  final Client client;
  late final Realtime _realtime;
  RealtimeSubscription? _subscription;

  final ImagePicker _picker = ImagePicker();

  // ───────────────────────────────────────────
  // INIT
  // ───────────────────────────────────────────
  AdminChatProvider({required this.client}) {
    _realtime = Realtime(client);
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.close();
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  // ───────────────────────────────────────────
  // HELPER — merge system fields into data map
  // ───────────────────────────────────────────
  Map<String, dynamic> _rowToMap(dynamic row) => {
        ...row.data as Map<String, dynamic>,
        '\$id': row.$id,
        '\$createdAt': row.$createdAt,
        '\$updatedAt': row.$updatedAt,
      };

  // ───────────────────────────────────────────
  // OPEN / CLOSE CHAT
  // ───────────────────────────────────────────
  void setChatOpen({required String productId, required String userId}) {
    _openProductId = productId;
    _openUserId = userId;
    _messages.clear();
    _notify();
  }

  void closeChat() {
    _openProductId = null;
    _openUserId = null;
    _messages.clear();
    _notify();
  }

  // ───────────────────────────────────────────
  // REALTIME
  // ───────────────────────────────────────────
  void _subscribeRealtime() {
    if (_subscription != null) return;

    _subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}'
          '.tables.${AppwriteConfig.chat}.rows',
    ]);

    _subscription?.stream.listen((event) async {
      final data = event.payload;

      if (data == null || _openUserId == null || _openProductId == null) return;

      final isCreate = event.events.any((e) => e.contains('.create'));
      final isUpdate = event.events.any((e) => e.contains('.update'));
      final isDelete = event.events.any((e) => e.contains('.delete'));

      // Realtime payload already includes $id, $createdAt at root level
      final normalised = {...data, 'id': data['\$id'] ?? data['id'] ?? ''};

      final senderId = normalised['userId'] as String?;
      final receiverId = normalised['receiverId'] as String?;
      final productId = normalised['productId'] as String?;

      // Only handle messages for the open conversation
      if (productId != _openProductId ||
          (_openUserId != senderId && _openUserId != receiverId)) {
        return;
      }

      if (isCreate) {
        final chat = _buildAdminChatModel(normalised);

        // Replace matching optimistic message instead of duplicating
        final optimisticIndex = _messages.indexWhere(
          (m) =>
              m.id.startsWith('temp_') &&
              m.senderId == (senderId ?? '') &&
              m.message == (normalised['message'] ?? '') &&
              m.uploadImage == normalised['uploadImage'] &&
              m.createdAt
                      .difference(
                        normalised['\$createdAt'] != null
                            ? DateTime.parse(normalised['\$createdAt'])
                            : DateTime.now(),
                      )
                      .inSeconds
                      .abs() <
                  5,
        );

        if (optimisticIndex != -1) {
          _messages[optimisticIndex] = chat;
        } else if (_messages.indexWhere((m) => m.id == chat.id) == -1) {
          _messages.add(chat);
        }
      } else if (isUpdate) {
        final index = _messages.indexWhere((m) => m.id == normalised['id']);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            message: normalised['message'] ?? _messages[index].message,
            uploadImage:
                normalised['uploadImage'] ?? _messages[index].uploadImage,
            isRead: normalised['isRead'] ?? _messages[index].isRead,
          );
        }
      } else if (isDelete) {
        _messages.removeWhere((m) => m.id == normalised['id']);
      }

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _notify();
    });
  }

  // ───────────────────────────────────────────
  // FETCH MESSAGES
  // ───────────────────────────────────────────
  Future<void> fetchMessages({
    required String productId,
    required String userId,
  }) async {
    _openProductId = productId;
    _openUserId = userId;
    _messages.clear();
    _isLoading = true;
    _notify();

    try {
      final res = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.chat,
        queries: [
          Query.equal('productId', productId),
          Query.or([
            Query.equal('userId', userId),
            Query.equal('receiverId', userId),
          ]),
          Query.orderAsc('\$createdAt'),
        ],
      );

      // ✅ merge system fields so $id and $createdAt are available in _buildAdminChatModel
      _messages
        ..addAll(res.rows.map((r) => _buildAdminChatModel(_rowToMap(r))))
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Admin fetchMessages error: $e');
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ───────────────────────────────────────────
  // SEND MESSAGE AS ADMIN  →  server function
  // ───────────────────────────────────────────
  Future<void> sendMessage({
    required String receiverId,
    required String productId,
    required String productTitle,
    String message = '',
    File? imageFile,
  }) async {
    String? uploadImageId;
    if (imageFile != null) {
      uploadImageId = await _uploadImage(imageFile);
    }

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic insert
    final tempMsg = AdminChatModel(
      id: tempId,
      senderId: 'admin',
      receiverId: receiverId,
      productId: productId,
      productTitle: productTitle,
      message: message,
      uploadImage: uploadImageId,
      isRead: false,
      createdAt: DateTime.now(),
      senderRole: 'admin',
      senderName: 'Admin',
      unreadCount: 0,
    );

    if (_openProductId == productId) {
      _messages.add(tempMsg);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _notify();
    }

    try {
      final functions = Functions(client);
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'sendMessage',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'receiverId': receiverId,
          'productId': productId,
          'productTitle': productTitle,
          'message': message,
          'uploadImage': uploadImageId,
          'senderName': 'Admin',
        }),
        method: ExecutionMethod.pOST,
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;

      if (result['status'] != true) {
        _messages.removeWhere((m) => m.id == tempId);
        _notify();
        return;
      }

      // ✅ Swap temp ID and use accurate server timestamp
      final realId = result['messageId'] as String?;
      final serverTime = result['createdAt'] as String?;

      if (realId != null) {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            id: realId,
            createdAt: serverTime != null
                ? DateTime.parse(serverTime)
                : _messages[idx].createdAt,
          );
          _notify();
        }
      }
    } catch (e) {
      debugPrint('Admin sendMessage error: $e');
      _messages.removeWhere((m) => m.id == tempId);
      _notify();
    }
  }

  // ───────────────────────────────────────────
  // MARK READ  →  server function
  // ───────────────────────────────────────────
  Future<void> markAsRead(String messageId) async {
    try {
      final functions = Functions(client);
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'markRead',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'messageId': messageId,
        }),
        method: ExecutionMethod.pOST,
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;
      if (result['status'] == true) {
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isRead: true,
            unreadCount: 0,
          );
          _notify();
        }
      }
    } catch (e) {
      debugPrint('Admin markAsRead error: $e');
    }
  }

  // ───────────────────────────────────────────
  // DELETE MESSAGE  →  server function
  // ───────────────────────────────────────────
  Future<void> deleteMessage(String messageId) async {
    try {
      final functions = Functions(client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'deleteMessage',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'messageId': messageId,
        }),
        method: ExecutionMethod.pOST,
      );
      // Realtime handles removal from _messages
    } catch (e) {
      debugPrint('Admin deleteMessage error: $e');
    }
  }

  // ───────────────────────────────────────────
  // IMAGE HELPERS
  // ───────────────────────────────────────────
  Future<File?> pickImage({required bool fromCamera}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) return File(picked.path);
    } catch (e) {
      debugPrint('Admin pickImage error: $e');
    }
    return null;
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final url = await CloudinaryService.uploadImage(file);
      return url; // returns the full secure_url string
    } catch (e) {
      debugPrint('_uploadImage error: $e');
      return null;
    }
  }

  // ───────────────────────────────────────────
  // BUILD MODEL FROM RAW ROW DATA
  // ───────────────────────────────────────────
  AdminChatModel _buildAdminChatModel(Map<String, dynamic> data) {
    final senderId = data['userId'] as String? ?? '';
    final senderRole = data['senderRole'] as String? ?? 'user';
    final senderName = data['senderName'] as String? ??
        (senderId == 'admin' ? 'Admin' : 'Unknown');

    return AdminChatModel(
      id: data['\$id'] as String? ?? data['id'] as String? ?? '',
      senderId: senderId,
      receiverId: data['receiverId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      productTitle: data['productTitle'] as String? ?? '',
      message: data['message'] as String? ?? '',
      uploadImage: data['uploadImage'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['\$createdAt'] != null
          ? DateTime.parse(data['\$createdAt'] as String)
          : DateTime.now(),
      senderRole: senderRole,
      senderName: senderName,
      unreadCount: (data['isRead'] as bool? ?? false) ? 0 : 1,
    );
  }

  // ───────────────────────────────────────────
  // MISC
  // ───────────────────────────────────────────
  void clear() {
    _messages.clear();
    _notify();
  }
}
