import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/adminchatlistmodel.dart';
import 'package:peereess/model/adminchatmodel.dart';

class AdminChatListProvider extends ChangeNotifier {
  final List<AdminChatListModel> _chatList = [];
  final List<AdminChatListModel> _filteredChatList = [];
  bool _isLoading = false;

  List<AdminChatListModel> get chatList =>
      _filteredChatList.isNotEmpty ? _filteredChatList : _chatList;
  bool get isLoading => _isLoading;

  final Map<String, String?> _productImageCache = {};
  final Map<String, Map<String, String>> _userMetaCache = {};

  String? _currentProductId;
  String? _currentUserIdInChat;

  // ✅ tracks which chat is currently open to skip unread increment
  String? _openProductId;
  String? _openUserId;

  final List<AdminChatModel> _messages = [];
  List<AdminChatModel> get messages => _messages;

  late final Realtime _realtime;
  RealtimeSubscription? _subscription;

  AdminChatListProvider({required Client client}) {
    _realtime = Realtime(client);
    _subscribeRealtime();
    fetchAllChats();
  }

  Map<String, dynamic> _rowToMap(dynamic row) => {
        ...row.data as Map<String, dynamic>,
        '\$id': row.$id,
        '\$createdAt': row.$createdAt,
        '\$updatedAt': row.$updatedAt,
      };

  /// Fetches ALL rows by paginating through with offset
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

      final rows = res.rows.map((row) => _rowToMap(row)).toList();
      allRows.addAll(rows);

      // If we got fewer than pageSize, we've reached the last page
      if (rows.length < pageSize) break;

      offset += pageSize;
    }

    return allRows;
  }

  // ✅ call from AdminChatScreen initState
  void setChatOpen({required String productId, required String userId}) {
    _openProductId = productId;
    _openUserId = userId;
    _currentProductId = productId;
    _currentUserIdInChat = userId;
  }

  // ✅ call from AdminChatScreen dispose
  void setChatClosed() {
    _openProductId = null;
    _openUserId = null;
  }

  void setCurrentChat({required String productId, required String userId}) {
    _currentProductId = productId;
    _currentUserIdInChat = userId;
    _messages.clear();
    notifyListeners();
    fetchMessagesForCurrentChat();
  }

  void _subscribeRealtime() {
    if (_subscription != null) return;

    _subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.tables.${AppwriteConfig.chat}.rows',
    ]);

    _subscription!.stream.listen((event) async {
      final payload = event.payload;
      if (payload == null) return;

      final normalised = {
        ...payload,
        'id': payload['\$id'] ?? payload['id'] ?? '',
      };

      final isCreate = event.events.any((e) => e.endsWith('.create'));
      final isUpdate = event.events.any((e) => e.endsWith('.update'));
      final isDelete = event.events.any((e) => e.endsWith('.delete'));

      await _handleRealtimeChatList(normalised);

      if (_currentProductId == null || _currentUserIdInChat == null) return;

      final msg = AdminChatModel.fromMap(normalised, unreadCount: 0);

      final belongsToOpenChat = msg.productId == _currentProductId &&
          (msg.senderId == _currentUserIdInChat ||
              msg.receiverId == _currentUserIdInChat);

      if (!belongsToOpenChat) return;

      final index = _messages.indexWhere((m) => m.id == msg.id);

      if (isCreate && index == -1) {
        _messages.add(msg);
      } else if (isUpdate && index != -1) {
        _messages[index] = msg;
      } else if (isDelete && index != -1) {
        _messages.removeAt(index);
      }

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    });
  }

  Future<void> _handleRealtimeChatList(Map<String, dynamic> payload) async {
    final senderId = payload['userId'];
    final receiverId = payload['receiverId'];
    final productId = payload['productId'];

    if (senderId == null || receiverId == null || productId == null) return;
    if (senderId != 'admin' && receiverId != 'admin') return;

    final chatUserId = senderId == 'admin' ? receiverId : senderId;
    final key = "$productId|$chatUserId";

    final index = _chatList.indexWhere(
      (c) => "${c.productId}|${c.userId}" == key,
    );

    final userMeta = await _getUserRoleAndFullName(chatUserId);
    final productImage = await _getProductImage(productId);

    final lastMessageText =
        payload['uploadImage'] != null ? 'Image' : payload['message'] ?? '';

    final lastMessageAt = payload['\$createdAt'] != null
        ? DateTime.parse(payload['\$createdAt'] as String)
        : DateTime.now();

    // ✅ don't increment unread if this chat is currently open by admin
    final isCurrentlyOpen =
        _openProductId == productId && _openUserId == chatUserId;
    final isIncoming = receiverId == 'admin';
    final isUnread = payload['isRead'] == false;
    final shouldIncrement = isIncoming && isUnread && !isCurrentlyOpen;

    if (index != -1) {
      final old = _chatList[index];
      _chatList[index] = old.copyWith(
        lastMessage: lastMessageText,
        lastMessageAt: lastMessageAt,
        unreadCount: shouldIncrement ? old.unreadCount + 1 : old.unreadCount,
        lastSenderRole: userMeta['role'],
        lastSenderName: userMeta['fullName'],
        productImageUrl: productImage,
      );
    } else {
      _chatList.add(
        AdminChatListModel(
          productId: productId,
          productTitle: payload['productTitle'] ?? '',
          userId: chatUserId,
          userName: userMeta['fullName'] ?? 'Unknown',
          productImageUrl: productImage,
          firstVariantPrice: payload['firstVariantPrice'] != null
              ? (payload['firstVariantPrice'] as num).toDouble()
              : null,
          lastMessage: lastMessageText,
          lastMessageAt: lastMessageAt,
          unreadCount: shouldIncrement ? 1 : 0,
          lastSenderRole: userMeta['role'] ?? 'user',
          lastSenderName: userMeta['fullName'] ?? 'Unknown',
        ),
      );
    }

    _chatList.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    _filteredChatList.clear();
    notifyListeners();
  }

  Future<void> fetchAllChats() async {
    try {
      _isLoading = true;
      notifyListeners();

      // ✅ paginated fetch instead of single listRows
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.chat,
        queries: [Query.orderDesc('\$createdAt')],
      );

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (final msg in allRows) {
        final senderId = msg['userId'];
        final receiverId = msg['receiverId'];
        final productId = msg['productId'];

        if (senderId == null || receiverId == null || productId == null)
          continue;
        if (senderId != 'admin' && receiverId != 'admin') continue;

        final chatUserId = senderId == 'admin' ? receiverId : senderId;
        final key = "$productId|$chatUserId";

        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(msg);
      }

      final List<AdminChatListModel> result = [];

      for (final entry in grouped.entries) {
        final msgs = entry.value
          ..sort(
            (a, b) => DateTime.parse(
              b['\$createdAt'],
            ).compareTo(DateTime.parse(a['\$createdAt'])),
          );

        final last = msgs.first;
        final chatUserId =
            last['userId'] == 'admin' ? last['receiverId'] : last['userId'];

        final unreadCount = msgs
            .where((m) => m['receiverId'] == 'admin' && m['isRead'] == false)
            .length;

        final userMeta = await _getUserRoleAndFullName(chatUserId);
        final productImage = await _getProductImage(last['productId']);

        result.add(
          AdminChatListModel(
            productId: last['productId'],
            productTitle: last['productTitle'] ?? '',
            userId: chatUserId,
            userName: userMeta['fullName'] ?? 'Unknown',
            productImageUrl: productImage,
            firstVariantPrice: last['firstVariantPrice'] != null
                ? (last['firstVariantPrice'] as num).toDouble()
                : null,
            lastMessage:
                last['uploadImage'] != null ? 'Image' : last['message'] ?? '',
            lastMessageAt: DateTime.parse(last['\$createdAt']),
            unreadCount: unreadCount,
            lastSenderRole: userMeta['role'] ?? 'user',
            lastSenderName: userMeta['fullName'] ?? 'Unknown',
          ),
        );
      }

      _chatList
        ..clear()
        ..addAll(result);
      _filteredChatList.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessagesForCurrentChat() async {
    if (_currentProductId == null || _currentUserIdInChat == null) return;

    // ✅ paginated fetch for messages
    final allRows = await _fetchAllRows(
      tableId: AppwriteConfig.chat,
      queries: [
        Query.equal('productId', _currentProductId!),
        Query.or([
          Query.equal('userId', _currentUserIdInChat!),
          Query.equal('receiverId', _currentUserIdInChat!),
        ]),
        Query.orderAsc('\$createdAt'),
      ],
    );

    _messages
      ..clear()
      ..addAll(allRows.map((r) => AdminChatModel.fromMap(r, unreadCount: 0)));

    notifyListeners();
  }

  Future<void> markChatAsRead({
    required String productId,
    required String userId,
  }) async {
    try {
      // ✅ 500 limit is fine here — unlikely to have 500+ unread at once
      final res = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.chat,
        queries: [
          Query.equal('productId', productId),
          Query.equal('receiverId', 'admin'),
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

      // ✅ reset unread count in list
      final index = _chatList.indexWhere(
        (c) => c.productId == productId && c.userId == userId,
      );
      if (index != -1) {
        _chatList[index] = _chatList[index].copyWith(unreadCount: 0);
      }
      final fIndex = _filteredChatList.indexWhere(
        (c) => c.productId == productId && c.userId == userId,
      );
      if (fIndex != -1) {
        _filteredChatList[fIndex] = _filteredChatList[fIndex].copyWith(
          unreadCount: 0,
        );
      }

      // ✅ update isRead on local messages so read tick shows immediately
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].productId == productId && !_messages[i].isRead) {
          _messages[i] = _messages[i].copyWith(isRead: true);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("markChatAsRead error: $e");
    }
  }

  Future<String?> _getProductImage(String productId) async {
    if (_productImageCache.containsKey(productId)) {
      return _productImageCache[productId];
    }

    final res = await AppwriteConfig.tablesDB.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.product,
      queries: [Query.equal('\$id', productId), Query.limit(1)],
    );

    if (res.rows.isEmpty) return null;

    final data = res.rows.first.data;
    final image =
        data['imageUrl'] is List ? data['imageUrl']?.first : data['imageUrl'];

    _productImageCache[productId] = image;
    return image;
  }

  Future<Map<String, String>> _getUserRoleAndFullName(String userId) async {
    if (_userMetaCache.containsKey(userId)) return _userMetaCache[userId]!;

    if (userId == 'admin') {
      return _userMetaCache[userId] = {'role': 'admin', 'fullName': 'Admin'};
    }

    final res = await AppwriteConfig.tablesDB.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.userCollection,
      queries: [Query.equal('userId', userId), Query.limit(1)],
    );

    final data = res.rows.isEmpty ? {} : res.rows.first.data;

    return _userMetaCache[userId] = {
      'role': (data['role'] ?? 'user').toString(),
      'fullName': (data['fullName'] ?? 'Unknown').toString(),
    };
  }

  void searchChats(String query) {
    if (query.isEmpty) {
      _filteredChatList.clear();
    } else {
      _filteredChatList
        ..clear()
        ..addAll(
          _chatList.where(
            (chat) =>
                chat.productTitle.toLowerCase().contains(query.toLowerCase()) ||
                chat.userName.toLowerCase().contains(query.toLowerCase()) ||
                chat.lastMessage.toLowerCase().contains(query.toLowerCase()),
          ),
        );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.close();
    _subscription = null;
    super.dispose();
  }
}
