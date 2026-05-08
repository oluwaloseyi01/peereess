import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peereess/provider/cloudinaryservice.dart';
import 'package:uuid/uuid.dart';

import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/supportchat_model.dart';

class SupportChatProvider extends ChangeNotifier {
  // ───────────────────────────────────────────
  // STATE
  // ───────────────────────────────────────────
  final List<SupportChatModel> _messages = [];
  final List<SupportChatModel> _adminChatList = [];
  final List<SupportChatModel> _filteredAdminChatList = [];

  bool _isSearching = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  String? _openSupportId;
  String? _openUserId;

  bool _isUserTyping = false;
  bool _isAdminTyping = false;
  bool _isAiTyping = false; // ✅ AI typing indicator (client-side only)
  bool _currentlyTyping = false;
  Timer? _typingDebounce;
  Timer? _aiTypingTimeout; // ✅ Safety timeout so bubble never gets stuck
  String _currentRole = 'user';

  late final Realtime _realtime;
  RealtimeSubscription? _subscription;
  RealtimeSubscription? _typingSubscription;

  final ImagePicker _picker = ImagePicker();

  // ───────────────────────────────────────────
  // GETTERS
  // ───────────────────────────────────────────
  List<SupportChatModel> get messages => _messages;

  List<SupportChatModel> get adminChatList =>
      _isSearching ? _filteredAdminChatList : _adminChatList;

  bool get isLoading => _isLoading;

  int get totalUserUnreadCount =>
      _adminChatList.fold(0, (sum, c) => sum + c.unreadCount);

  // ✅ For users: show typing if real admin is typing OR AI is typing
  bool getIsOtherTyping({required bool isAdmin}) =>
      isAdmin ? _isUserTyping : (_isAdminTyping || _isAiTyping);

  // ───────────────────────────────────────────
  // INIT
  // ───────────────────────────────────────────
  SupportChatProvider() {
    _realtime = Realtime(AppwriteConfig.client);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _typingDebounce?.cancel();
    _aiTypingTimeout?.cancel();
    _subscription?.close();
    _typingSubscription?.close();
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  // ───────────────────────────────────────────
  // AI TYPING HELPERS
  // ───────────────────────────────────────────
  void _showAiTyping() {
    _isAiTyping = true;
    _notify();

    // Safety: auto-clear after 15s if no AI reply arrives (e.g. Gemini error)
    _aiTypingTimeout?.cancel();
    _aiTypingTimeout = Timer(const Duration(seconds: 15), () {
      if (_isAiTyping) {
        _isAiTyping = false;
        _notify();
      }
    });
  }

  void _clearAiTyping() {
    if (!_isAiTyping) return;
    _aiTypingTimeout?.cancel();
    _isAiTyping = false;
    _notify();
  }

  // ───────────────────────────────────────────
  // PAGINATION HELPER
  // ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchAllRows({
    required String tableId,
    required List<String> queries,
  }) async {
    const int pageSize = 500;
    int offset = 0;
    final List<Map<String, dynamic>> allRows = [];

    while (true) {
      final res = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        queries: [...queries, Query.limit(pageSize), Query.offset(offset)],
      );

      for (final row in res.rows) {
        allRows.add({
          ...row.data,
          '\$id': row.$id,
          '\$createdAt': row.$createdAt,
          '\$updatedAt': row.$updatedAt,
        });
      }

      if (res.rows.length < pageSize) break;
      offset += pageSize;
    }

    return allRows;
  }

  // ───────────────────────────────────────────
  // OPEN / CLOSE CHAT
  // ───────────────────────────────────────────
  Future<void> openChat({
    required String supportId,
    required String userId,
    required String userName,
    bool isAdmin = false,
  }) async {
    if (_openSupportId == supportId && _openUserId == userId) return;

    _openSupportId = supportId;
    _openUserId = userId;
    _currentRole = isAdmin ? 'admin' : 'user';

    if (isAdmin) {
      await _setAdminActive(supportId: supportId, isActive: true);
    }

    await fetchMessages(supportId: supportId, userId: userId);
    _subscribeRealtime();
    _subscribeTypingRealtime(supportId);

    // ✅ If no messages yet and this is a user opening, trigger AI greeting
    if (!isAdmin && _messages.isEmpty) {
      await _triggerAiGreeting(
        supportId: supportId,
        userId: userId,
        userName: userName,
      );
    }
  }

  void closeChat({bool isAdmin = false}) {
    _typingDebounce?.cancel();
    _aiTypingTimeout?.cancel();

    if (_currentlyTyping && _openSupportId != null) {
      _setTypingOnServer(supportId: _openSupportId!, isTyping: false);
    }
    _currentlyTyping = false;

    if (isAdmin && _openSupportId != null) {
      _setAdminActive(supportId: _openSupportId!, isActive: false);
    }

    _isUserTyping = false;
    _isAdminTyping = false;
    _isAiTyping = false;

    _typingSubscription?.close();
    _typingSubscription = null;

    _openSupportId = null;
    _openUserId = null;
    _messages.clear();
  }

  // ───────────────────────────────────────────
  // AI GREETING — calls server to let Gemini greet
  // ───────────────────────────────────────────
  Future<void> _triggerAiGreeting({
    required String supportId,
    required String userId,
    required String userName,
  }) async {
    try {
      final jwt = await _getUserJwt();
      if (jwt == null) return;

      // ✅ Show AI typing while greeting is being generated
      _showAiTyping();

      final functions = Functions(AppwriteConfig.client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'sendAiGreeting',
          'jwt': jwt,
          'supportId': supportId,
          'userId': userId,
          'userName': userName,
        }),
        method: ExecutionMethod.pOST,
      );
      // ✅ The realtime subscription will clear _isAiTyping when the
      // greeting message arrives. The 15s timeout is the fallback.
    } catch (e) {
      // debugPrint('_triggerAiGreeting error: $e');
      _clearAiTyping();
    }
  }

  // ───────────────────────────────────────────
  // TYPING
  // ───────────────────────────────────────────
  void onTypingChanged(String value) {
    if (_openSupportId == null) return;

    final bool hasText = value.isNotEmpty;

    if (hasText && !_currentlyTyping) {
      _currentlyTyping = true;
      _setTypingOnServer(supportId: _openSupportId!, isTyping: true);
    }

    if (!hasText && _currentlyTyping) {
      _typingDebounce?.cancel();
      _currentlyTyping = false;
      _setTypingOnServer(supportId: _openSupportId!, isTyping: false);
      return;
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_currentlyTyping && _openSupportId != null) {
        _currentlyTyping = false;
        _setTypingOnServer(supportId: _openSupportId!, isTyping: false);
      }
    });
  }

  // ───────────────────────────────────────────
  // FETCH MESSAGES
  // ───────────────────────────────────────────
  Future<void> fetchMessages({
    required String supportId,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _notify();

      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.supportchat,
        queries: [
          Query.equal('supportId', supportId),
          Query.equal('userId', userId),
          Query.orderAsc('\$createdAt'),
        ],
      );

      _messages
        ..clear()
        ..addAll(allRows.map((r) => SupportChatModel.fromMap(r)));
    } catch (e) {
      // debugPrint('fetchMessages error: $e');
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ───────────────────────────────────────────
  // REALTIME — messages
  // ───────────────────────────────────────────
  void _subscribeRealtime() {
    if (_subscription != null) return;

    _subscription = _realtime.subscribe([
      // ✅ collections.documents channel — fires for db.createDocument()
      'databases.${AppwriteConfig.databaseId}'
          '.collections.${AppwriteConfig.supportchat}.documents',
    ]);

    _subscription!.stream.listen((event) {
      if (_isDisposed) return;

      final payload = event.payload;
      if (payload == null || _openSupportId == null || _openUserId == null) {
        return;
      }

      final normalised = {
        ...payload,
        'id': payload['\$id'] ?? payload['id'] ?? '',
      };

      final msg = SupportChatModel.fromMap(normalised);

      if (msg.supportId != _openSupportId || msg.userId != _openUserId) return;

      final isCreate = event.events.any((e) => e.endsWith('.create'));
      final isUpdate = event.events.any((e) => e.endsWith('.update'));
      final isDelete = event.events.any((e) => e.endsWith('.delete'));

      final index = _messages.indexWhere((m) => m.id == msg.id);

      if (isCreate && index == -1) {
        // ✅ Only suppress optimistic duplicates from THIS user, never
        //    from admin/AI so AI replies always show immediately.
        final isOptimisticDuplicate = msg.senderId == _openUserId &&
            _messages.any(
              (m) =>
                  m.message == msg.message &&
                  m.senderId == msg.senderId &&
                  msg.createdAt.difference(m.createdAt).inSeconds.abs() < 10,
            );

        if (!isOptimisticDuplicate) {
          _messages.add(msg);

          // ✅ Clear AI typing bubble the moment an admin/AI reply arrives
          if (!msg.isFromUser) {
            _clearAiTyping();
          }
        }
      }
      if (isUpdate && index != -1) _messages[index] = msg;
      if (isDelete && index != -1) _messages.removeAt(index);

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _updateAdminChatListFromMessage(msg);
      _notify();
    });
  }

  // ───────────────────────────────────────────
  // REALTIME — typing
  // ───────────────────────────────────────────
  void _subscribeTypingRealtime(String supportId) {
    _typingSubscription?.close();
    _typingSubscription = null;

    final String docId = 'typing_$supportId';

    _typingSubscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}'
          '.collections.${AppwriteConfig.typingCollection}'
          '.documents.$docId',
    ]);

    _typingSubscription!.stream.listen((event) {
      if (_isDisposed) return;

      final payload = event.payload;
      if (payload == null) return;

      final bool newUserTyping = payload['isUserTyping'] as bool? ?? false;
      final bool newAdminTyping = payload['isAdminTyping'] as bool? ?? false;

      if (newUserTyping != _isUserTyping || newAdminTyping != _isAdminTyping) {
        _isUserTyping = newUserTyping;
        _isAdminTyping = newAdminTyping;
        _notify();
      }
    });
  }

  void _updateAdminChatListFromMessage(SupportChatModel msg) {
    final keyIndex = _adminChatList.indexWhere(
      (c) => c.supportId == msg.supportId && c.userId == msg.userId,
    );

    final unreadCount = _messages
        .where((m) => m.supportId == msg.supportId && m.userId == msg.userId)
        .where((m) => m.isFromUser && !m.isRead)
        .length;

    final chatEntry = msg.copyWith(unreadCount: unreadCount);

    if (keyIndex != -1) {
      _adminChatList[keyIndex] = chatEntry;
    } else {
      _adminChatList.add(chatEntry);
    }

    _adminChatList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ───────────────────────────────────────────
  // SEND MESSAGE
  // ───────────────────────────────────────────
  Future<void> sendMessage({
    required String supportId,
    required String userId,
    required String senderId,
    required String senderName,
    required String role,
    String message = '',
    File? imageFile,
    required bool isFromUser,
  }) async {
    _typingDebounce?.cancel();
    if (_currentlyTyping) {
      _currentlyTyping = false;
      _setTypingOnServer(supportId: supportId, isTyping: false);
    }

    String? imageFileId;
    if (imageFile != null) {
      imageFileId = await _uploadImage(imageFile);
    }

    final Map<String, dynamic> authFields;
    if (role == 'admin') {
      authFields = {'adminSecret': AppwriteConfig.adminPanelSecret};
    } else {
      final jwt = await _getUserJwt();
      if (jwt == null) {
        // debugPrint('sendSupportMessage: could not get JWT');
        return;
      }
      authFields = {'jwt': jwt};
    }

    final tempId = const Uuid().v4();
    final optimistic = SupportChatModel(
      id: tempId,
      supportId: supportId,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      role: role,
      message: message,
      imageFileId: imageFileId,
      isFromUser: isFromUser,
      isRead: !isFromUser,
      unreadCount: 0,
      createdAt: DateTime.now(),
    );

    _messages.add(optimistic);
    _updateAdminChatListFromMessage(optimistic);

    // ✅ Show AI typing bubble as soon as the user sends a message.
    //    Only for user messages (not admin replies to themselves).
    if (isFromUser) {
      _showAiTyping();
    }

    _notify();

    try {
      final functions = Functions(AppwriteConfig.client);
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'sendSupportMessage',
          ...authFields,
          'supportId': supportId,
          'userId': userId,
          'senderName': senderName,
          'message': message,
          'imageFileId': imageFileId,
        }),
        method: ExecutionMethod.pOST,
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;
      if (result['status'] != true) {
        // debugPrint('sendSupportMessage server error: ${result['message']}');
        _messages.removeWhere((m) => m.id == tempId);
        // ✅ Clear AI typing if the send itself failed
        _clearAiTyping();
        _notify();
      } else {
        final realId = result['messageId'] as String?;
        if (realId != null) {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(id: realId);
            _notify();
          }
        }
      }
    } catch (e) {
      // debugPrint('sendSupportMessage error: $e');
      _messages.removeWhere((m) => m.id == tempId);
      // ✅ Clear AI typing on exception too
      _clearAiTyping();
      _notify();
    }
  }

  // ───────────────────────────────────────────
  // MARK READ
  // ───────────────────────────────────────────
  Future<void> markMessagesAsReadForSupport(
    String supportId, {
    required bool isAdmin,
  }) async {
    final unread = _messages.where((m) {
      if (m.supportId != supportId) return false;
      return isAdmin ? m.isFromUser && !m.isRead : !m.isFromUser && !m.isRead;
    }).toList();

    if (unread.isEmpty) return;

    for (int i = 0; i < _messages.length; i++) {
      if (unread.any((u) => u.id == _messages[i].id)) {
        _messages[i] = _messages[i].copyWith(isRead: true);
      }
    }
    final adminIndex = _adminChatList.indexWhere(
      (c) => c.supportId == supportId,
    );
    if (adminIndex != -1) {
      _adminChatList[adminIndex] = _adminChatList[adminIndex].copyWith(
        unreadCount: 0,
      );
    }
    _notify();

    final Map<String, dynamic> authFields;
    if (isAdmin) {
      authFields = {'adminSecret': AppwriteConfig.adminPanelSecret};
    } else {
      final jwt = await _getUserJwt();
      if (jwt == null) return;
      authFields = {'jwt': jwt};
    }

    try {
      final functions = Functions(AppwriteConfig.client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'markSupportRead',
          ...authFields,
          'messageIds': unread.map((m) => m.id).toList(),
        }),
        method: ExecutionMethod.pOST,
      );
    } catch (e) {
      // debugPrint('markMessagesAsReadForSupport error: $e');
    }
  }

  Future<void> clearUnreadForSupport(String supportId) async {
    await markMessagesAsReadForSupport(supportId, isAdmin: true);
  }

  // ───────────────────────────────────────────
  // REQUEST HUMAN AGENT
  // ───────────────────────────────────────────
  Future<void> requestHumanAgent({
    required String supportId,
    required String userId,
    required String userName,
  }) async {
    await sendMessage(
      supportId: supportId,
      userId: userId,
      senderId: userId,
      senderName: userName,
      role: 'user',
      message: 'I would like to speak to an agent please.',
      isFromUser: true,
    );
  }

  // ───────────────────────────────────────────
  // SET TYPING ON SERVER
  // ───────────────────────────────────────────
  Future<void> _setTypingOnServer({
    required String supportId,
    required bool isTyping,
  }) async {
    try {
      final Map<String, dynamic> authFields;
      if (_currentRole == 'admin') {
        authFields = {'adminSecret': AppwriteConfig.adminPanelSecret};
      } else {
        final jwt = await _getUserJwt();
        if (jwt == null) return;
        authFields = {'jwt': jwt};
      }

      final functions = Functions(AppwriteConfig.client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'setTyping',
          ...authFields,
          'supportId': supportId,
          'isTyping': isTyping,
        }),
        method: ExecutionMethod.pOST,
      );
    } catch (e) {
      // debugPrint('_setTypingOnServer error: $e');
    }
  }

  // ───────────────────────────────────────────
  // SET ADMIN ACTIVE
  // ───────────────────────────────────────────
  Future<void> _setAdminActive({
    required String supportId,
    required bool isActive,
  }) async {
    try {
      final functions = Functions(AppwriteConfig.client);
      await functions.createExecution(
        functionId: AppwriteConfig.messagingFunctionId,
        body: jsonEncode({
          'action': 'setAdminActive',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'supportId': supportId,
          'isActive': isActive,
        }),
        method: ExecutionMethod.pOST,
      );
    } catch (e) {
      // debugPrint('_setAdminActive error: $e');
    }
  }

  // ───────────────────────────────────────────
  // ADMIN CHAT LIST
  // ───────────────────────────────────────────
  Future<void> fetchAdminChatList() async {
    try {
      _isLoading = true;
      _notify();

      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.supportchat,
        queries: [Query.orderDesc('\$createdAt')],
      );

      final allMessages =
          allRows.map((r) => SupportChatModel.fromMap(r)).toList();

      final Map<String, SupportChatModel> latestChats = {};
      for (final msg in allMessages) {
        final key = '${msg.supportId}_${msg.userId}';
        if (!latestChats.containsKey(key) ||
            msg.createdAt.isAfter(latestChats[key]!.createdAt)) {
          latestChats[key] = msg;
        }
      }

      _adminChatList
        ..clear()
        ..addAll(
          latestChats.values.map((msg) {
            final unread = allMessages
                .where(
                  (m) =>
                      m.supportId == msg.supportId &&
                      m.userId == msg.userId &&
                      m.isFromUser &&
                      !m.isRead,
                )
                .length;
            return msg.copyWith(unreadCount: unread);
          }),
        )
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void searchAdminChats(String query) {
    if (query.trim().isEmpty) {
      _isSearching = false;
      _filteredAdminChatList.clear();
    } else {
      _isSearching = true;
      _filteredAdminChatList
        ..clear()
        ..addAll(
          _adminChatList.where(
            (c) =>
                c.senderName.toLowerCase().contains(query.toLowerCase()) ||
                c.message.toLowerCase().contains(query.toLowerCase()),
          ),
        );
    }
    _notify();
  }

  // ───────────────────────────────────────────
  // IMAGE HELPERS
  // ───────────────────────────────────────────
  Future<File?> pickImage({required bool fromCamera}) async {
    final x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    return x != null ? File(x.path) : null;
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

  // ───────────────────────────────────────────
  // GET USER JWT
  // ───────────────────────────────────────────
  Future<String?> _getUserJwt() async {
    try {
      final token = await Account(AppwriteConfig.client).createJWT();
      return token.jwt;
    } catch (e) {
      // debugPrint('_getUserJwt error: $e');
      return null;
    }
  }
}
