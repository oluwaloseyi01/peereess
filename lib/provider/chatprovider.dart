import 'dart:convert';
import 'dart:io';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peereess/provider/cloudinaryservice.dart';

import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/chatmodel.dart';
import 'package:peereess/provider/chatlistprovider.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatModel> _messages = [];
  bool _isLoading = false;
  bool _isDisposed = false;

  String? _openProductId;
  String? _openUserId;
  String? _viewerId;
  bool _isAdmin = false;

  late final Realtime _realtime;
  RealtimeSubscription? _subscription;

  final Client client;
  final ImagePicker _picker = ImagePicker();

  List<ChatModel> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider({required this.client}) {
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

  Map<String, dynamic> _rowToMap(dynamic row) => {
        ...row.data as Map<String, dynamic>,
        '\$id': row.$id,
        '\$createdAt': row.$createdAt,
        '\$updatedAt': row.$updatedAt,
      };

  void setChatOpen({
    required String productId,
    required String userId,
    String? viewerId,
    bool isAdmin = false,
  }) {
    if (_openProductId == productId && _openUserId == userId) return;
    _openProductId = productId;
    _openUserId = userId;
    _viewerId = viewerId ?? userId;
    _isAdmin = isAdmin;
    _messages.clear();
    _notify();
  }

  void closeChat() {
    _openProductId = null;
    _openUserId = null;
    _viewerId = null;
    _messages.clear();
    _notify();
  }

  void _subscribeRealtime() {
    if (_subscription != null) return;

    _subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}'
          '.tables.${AppwriteConfig.chat}.rows',
    ]);

    _subscription!.stream.listen((event) {
      final payload = event.payload;
      if (payload == null || _openUserId == null) return;

      final isCreate = event.events.any((e) => e.contains('.create'));
      final isUpdate = event.events.any((e) => e.contains('.update'));
      final isDelete = event.events.any((e) => e.contains('.delete'));

      final normalised = {
        ...payload,
        'id': payload['\$id'] ?? payload['id'] ?? '',
      };

      final msg = ChatModel.fromMap(
        normalised,
        currentUserId: _viewerId ?? _openUserId!,
      );

      // Only handle messages belonging to the currently open conversation
      if (_openProductId != msg.productId ||
          (_openUserId != msg.userId && _openUserId != msg.receiverId)) {
        return;
      }

      final index = _messages.indexWhere((m) => m.id == msg.id);

      // Use raw payload '$id' directly — msg.id may be empty if
      // ChatModel.fromMap loses the '$' key from the realtime spread.
      final String rawRowId = (payload['\$id'] as String? ?? '').isNotEmpty
          ? payload['\$id'] as String
          : msg.id;
      // Mark incoming message as read when chat is open.
      // We can't rely on msg.isMe (based on userId field = conversation owner,
      // not actual sender) or msg.receiverId (may be 'admin' both ways).
      // Instead: for buyer, the incoming message is always from admin (role='admin').
      //          for admin, the incoming message is always from user (role!='admin').
      // senderRole is the reliable field — 'admin' when admin sent the message.
      // msg.role maps to the 'role' DB column which stores the conversation
      // owner's role, not the sender's role. senderRole is explicit.
      final String senderRole =
          (payload['senderRole'] as String? ?? '').toLowerCase();

      final bool isIncomingMessage =
          _isAdmin ? senderRole != 'admin' : senderRole == 'admin';

      // Mark as read if:
      //   - it's a new create event (not update/delete)
      //   - it's an incoming message (not sent by the current viewer)
      //   - we have a valid row ID
      //   - message is not already marked read in the DB
      final bool alreadyRead = payload['isRead'] == true;

      if (isCreate &&
          isIncomingMessage &&
          rawRowId.isNotEmpty &&
          !alreadyRead) {
        _markSingleMessageAsRead(rawRowId);
      }

      if (isCreate && index == -1) {
        // Check if this is confirming an optimistic/temp message we already added
        final optimisticIndex = _messages.indexWhere(
          (m) =>
              m.id.startsWith('temp_') &&
              m.userId == msg.userId &&
              m.productId == msg.productId && // FIX: added product check
              m.receiverId == msg.receiverId && // FIX: added receiver check
              m.message == msg.message &&
              m.uploadImage == msg.uploadImage &&
              m.createdAt.difference(msg.createdAt).inSeconds.abs() <
                  10, // FIX: widened from 5→10
        );

        if (optimisticIndex != -1) {
          // Replace temp with confirmed server message
          _messages[optimisticIndex] = msg;
        } else {
          // FIX: extra guard — don't add if a real (non-temp) message with the
          // same content already exists (prevents duplicate on fast realtime events)
          final alreadyExists = _messages.any(
            (m) =>
                !m.id.startsWith('temp_') &&
                m.userId == msg.userId &&
                m.message == msg.message &&
                m.uploadImage == msg.uploadImage &&
                m.createdAt.difference(msg.createdAt).inSeconds.abs() < 10,
          );
          if (!alreadyExists) {
            _messages.add(msg);
          }
        }
      }
      if (isUpdate && index != -1) _messages[index] = msg;
      if (isDelete && index != -1) _messages.removeAt(index);

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      // Apply any pending read flags to messages that just landed in the list
      _applyPendingReads();
      _notify();
    });
  }

  Future<void> fetchMessages({
    required String productId,
    required String userId,
    String? viewerId,
    bool isAdmin = false,
  }) async {
    final alreadyLoaded = _messages.isNotEmpty &&
        _openProductId == productId &&
        _openUserId == userId;

    if (alreadyLoaded) return;

    _openProductId = productId;
    _openUserId = userId;
    _viewerId = viewerId ?? userId;
    _isAdmin = isAdmin;

    // Preserve any optimistic temp messages added before fetch completes,
    // then clear non-temp messages so we don't double-add server results
    final tempMessages =
        _messages.where((m) => m.id.startsWith('temp_')).toList();
    _messages.clear();
    _messages.addAll(tempMessages);

    _isLoading = true;
    _notify();

    final String currentId = _viewerId!;

    try {
      final results = await Future.wait([
        AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.chat,
          queries: [
            Query.equal('productId', productId),
            Query.equal('userId', userId),
            Query.orderAsc('\$createdAt'),
            Query.limit(500),
          ],
        ),
        AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.chat,
          queries: [
            Query.equal('productId', productId),
            Query.equal('receiverId', userId),
            Query.orderAsc('\$createdAt'),
            Query.limit(500),
          ],
        ),
      ]);

      final sentRows = results[0].rows;
      final receivedRows = results[1].rows;

      // Use a map to deduplicate by ID — prevents any message appearing twice
      final Map<String, ChatModel> seen = {};

      for (final r in sentRows) {
        final msg = ChatModel.fromMap(_rowToMap(r), currentUserId: currentId);
        seen[msg.id] = msg;
      }
      for (final r in receivedRows) {
        final msg = ChatModel.fromMap(_rowToMap(r), currentUserId: currentId);
        seen.putIfAbsent(msg.id, () => msg);
      }

      // Remove any temp messages that now have a real server counterpart
      // (matched by userId + message text + close timestamp)
      _messages.removeWhere((temp) {
        if (!temp.id.startsWith('temp_')) return false;
        return seen.values.any(
          (real) =>
              real.userId == temp.userId &&
              real.message == temp.message &&
              real.uploadImage == temp.uploadImage &&
              real.createdAt.difference(temp.createdAt).inSeconds.abs() < 10,
        );
      });

      // Add all server messages that aren't already in the list
      for (final msg in seen.values) {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      }

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      // debugPrint('fetchMessages error: $e');
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> markMessagesAsRead({
    required String productId,
    required String userId,
    bool isAdmin = false,
  }) async {
    try {
      // Use correct receiverId — 'admin' string for admin, actual UID for users
      final String receiverQuery = isAdmin ? 'admin' : userId;

      final res = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.chat,
        queries: [
          Query.equal('productId', productId),
          Query.equal('receiverId', receiverQuery),
          Query.equal('isRead', false),
          Query.limit(500),
        ],
      );

      for (final row in res.rows) {
        await AppwriteConfig.tablesDB.updateRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.chat,
          rowId: row.$id,
          data: {'isRead': true},
        );
      }

      bool changed = false;
      for (int i = 0; i < _messages.length; i++) {
        if (!_messages[i].isRead && _messages[i].receiverId == receiverQuery) {
          _messages[i] = _messages[i].copyWith(isRead: true);
          changed = true;
        }
      }

      if (changed) _notify();
    } catch (e) {
      // debugPrint('markMessagesAsRead error: $e');
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String productId,
    required String productTitle,
    String? message,
    File? imageFile,
    double? firstVariantPrice,
    String senderRole = 'user',
    String? senderName,
    ChatListProvider? chatListProvider,
  }) async {
    final msgText = message ?? '';

    String? uploadImageId;

    if (imageFile != null) {
      uploadImageId = await _uploadImage(imageFile);
      if (uploadImageId == null) {
        // debugPrint('sendMessage: image upload failed, aborting');
        return;
      }
    }

    final bool isAdmin = senderRole == 'admin';

    String? jwt;
    if (!isAdmin) {
      jwt = await _getUserJwt();
      if (jwt == null) {
        // debugPrint('sendMessage: could not get JWT');
        return;
      }
    }

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempMsg = ChatModel(
      id: tempId,
      userId: senderId,
      receiverId: receiverId,
      productId: productId,
      productTitle: productTitle,
      message: msgText,
      uploadImage: uploadImageId,
      firstVariantPrice: firstVariantPrice,
      isRead: false,
      isTyping: false,
      createdAt: DateTime.now(),
      isMe: true,
      role: senderRole,
      fullName: senderName ?? (isAdmin ? 'Admin' : 'Customer'),
    );

    // FIX: also guard _openUserId — if it's null the chat isn't ready yet
    // and adding optimistically would create a stray message
    if (_openProductId == productId && _openUserId != null) {
      _messages.add(tempMsg);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _notify();
    }

    // Update chat list preview immediately
    if (chatListProvider != null) {
      chatListProvider.onLocalMessageSent(tempMsg);
    }

    try {
      final functions = Functions(client);

      final Map<String, dynamic> requestBody = {
        'action': 'sendMessage',
        if (isAdmin) ...{
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'senderId': senderId,
        } else
          'jwt': jwt,
        'receiverId': receiverId,
        'productId': productId,
        'productTitle': productTitle,
        'message': msgText,
        'uploadImage': uploadImageId,
        'senderName': senderName ?? (isAdmin ? 'Admin' : 'Customer'),
        'senderRole': senderRole,
        'firstVariantPrice': firstVariantPrice,
      };

      final execution = await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode(requestBody),
        method: ExecutionMethod.pOST,
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;

      if (result['status'] != true) {
        // debugPrint('sendMessage server error: ${result['message']}');
        _messages.removeWhere((m) => m.id == tempId);
        _notify();
        return;
      }

      // Replace temp message ID with real server ID
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

      // Update chat list with confirmed server timestamp
      if (chatListProvider != null && realId != null) {
        chatListProvider.onLocalMessageSent(
          ChatModel(
            id: realId,
            userId: senderId,
            receiverId: receiverId,
            productId: productId,
            productTitle: productTitle,
            message: msgText,
            uploadImage: uploadImageId,
            firstVariantPrice: firstVariantPrice,
            isRead: false,
            isTyping: false,
            createdAt: serverTime != null
                ? DateTime.parse(serverTime)
                : DateTime.now(),
            isMe: true,
            role: senderRole,
            fullName: senderName ?? (isAdmin ? 'Admin' : 'Customer'),
          ),
        );
      }
    } catch (e) {
      // debugPrint('sendMessage error: $e');
      _messages.removeWhere((m) => m.id == tempId);
      _notify();
    }
  }

  Future<void> markAsRead(String messageId) async {
    final String? jwt = await _getUserJwt();
    if (jwt == null) return;

    try {
      final functions = Functions(client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'markRead',
          'jwt': jwt,
          'messageId': messageId,
        }),
        method: ExecutionMethod.pOST,
      );
    } catch (e) {
      // debugPrint('markAsRead error: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final String? jwt = await _getUserJwt();
    if (jwt == null) return;

    try {
      final functions = Functions(client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'deleteMessage',
          'jwt': jwt,
          'messageId': messageId,
        }),
        method: ExecutionMethod.pOST,
      );
    } catch (e) {
      // debugPrint('deleteMessage error: $e');
    }
  }

  Future<File?> pickImage({required bool fromCamera}) async {
    final x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    return x != null ? File(x.path) : null;
  }

  /// Marks a single incoming message as read in the DB and flips its local
  /// isRead flag — called automatically when a new message arrives while
  /// ChatScreen is open so the sender sees blue double-ticks immediately.
  Future<void> _markSingleMessageAsRead(String rowId) async {
    // Flip the local isRead flag immediately so the UI updates at once —
    // the message may not be in _messages yet (realtime arrives before add),
    // so we also store the rowId and flip it after the message is added.
    _pendingReadRowIds.add(rowId);
    _applyPendingReads();

    try {
      await AppwriteConfig.tablesDB.updateRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.chat,
        rowId: rowId,
        data: {'isRead': true},
      );
      _pendingReadRowIds.remove(rowId);
    } catch (e) {
      // debugPrint('_markSingleMessageAsRead error: $e');
      _pendingReadRowIds.remove(rowId);
    }
  }

  // Holds row IDs that should be marked read as soon as they appear in _messages
  final Set<String> _pendingReadRowIds = {};

  void _applyPendingReads() {
    if (_pendingReadRowIds.isEmpty) return;
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_pendingReadRowIds.contains(_messages[i].id) &&
          !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) _notify();
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final url = await CloudinaryService.uploadImage(file);
      return url;
    } catch (e) {
      // debugPrint('_uploadImage error: $e');
      return null;
    }
  }

  Future<String?> _getUserJwt() async {
    try {
      final account = Account(client);
      final token = await account.createJWT();
      return token.jwt;
    } catch (e) {
      // debugPrint('_getUserJwt error: $e');
      return null;
    }
  }
}
