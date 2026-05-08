import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/chatlist.dart';
import 'package:peereess/model/chatmodel.dart';

class ChatListProvider extends ChangeNotifier {
  final List<ChatListModel> _chatList = [];
  final List<ChatListModel> _filteredChatList = [];
  bool _isLoading = false;
  String currentUserId;

  List<ChatListModel> get chatList =>
      _filteredChatList.isNotEmpty ? _filteredChatList : _chatList;
  bool get isLoading => _isLoading;

  final Map<String, String?> _productImageCache = {};
  RealtimeSubscription? _subscription;
  late final Realtime _realtime;
  final Client client;

  int get totalUnreadCount =>
      _chatList.fold(0, (sum, chat) => sum + chat.unreadCount);

  bool isAdmin = false;

  // tracks which productId is currently open in ChatScreen
  String? _openProductId;

  ChatListProvider({required this.client, required this.currentUserId}) {
    _realtime = Realtime(client);
    if (currentUserId.isNotEmpty) {
      init(currentUserId);
    }
  }

  void setChatOpen({
    required String productId,
    required String userId,
    String? viewerId,
  }) {
    _openProductId = productId;
  }

  void setChatClosed() {
    _openProductId = null;
  }

  void init(String userId, {bool admin = false}) {
    disposeRealtime();
    currentUserId = userId;
    isAdmin = admin;
    fetchChats(userId, isAdmin: admin);
    _subscribeRealtime();
  }

  Map<String, dynamic> _rowToMap(dynamic row) => {
        ...row.data as Map<String, dynamic>,
        '\$id': row.$id,
        '\$createdAt': row.$createdAt,
        '\$updatedAt': row.$updatedAt,
      };

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

      if (rows.length < pageSize) break;

      offset += pageSize;
    }

    return allRows;
  }

  void _subscribeRealtime() {
    if (_subscription != null) return;

    _subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}'
          '.tables.${AppwriteConfig.chat}.rows',
    ]);

    _subscription?.stream.listen((event) {
      final data = event.payload;
      final eventType = event.events.first;
      if (data == null) return;

      final normalised = {...data, 'id': data['\$id'] ?? data['id'] ?? ''};
      _handleRealtimeChatList(normalised, eventType);
    });
  }

  void _handleRealtimeChatList(Map<String, dynamic> data, String eventType) {
    // FIX: for admin, accept all messages; for user, only messages they are part of
    if (!isAdmin &&
        data['userId'] != currentUserId &&
        data['receiverId'] != currentUserId) {
      return;
    }

    final message = ChatModel.fromMap(data, currentUserId: currentUserId);
    final index = _chatList.indexWhere((c) => c.productId == message.productId);

    final lastMessageText =
        (message.uploadImage != null && message.uploadImage!.isNotEmpty)
            ? "Image"
            : message.message;

    final isCurrentlyOpen = _openProductId == message.productId;

    // FIX: check receiverId directly — admin receives where receiverId == 'admin',
    // users receive where receiverId == their actual userId
    final String myReceiverId = isAdmin ? 'admin' : currentUserId;
    final shouldIncrement =
        message.receiverId == myReceiverId && !isCurrentlyOpen;

    final String buyerId;
    final String? buyerName;

    if (message.role == 'admin') {
      buyerId = message.receiverId;
      buyerName = index != -1 ? _chatList[index].senderName : null;
    } else {
      buyerId = message.userId;
      buyerName = message.fullName.isNotEmpty ? message.fullName : null;
    }

    if (index != -1) {
      final chat = _chatList.removeAt(index);
      _chatList.insert(
        0,
        chat.copyWith(
          lastMessage: lastMessageText,
          lastMessageAt: message.createdAt,
          unreadCount:
              shouldIncrement ? chat.unreadCount + 1 : chat.unreadCount,
          senderId: buyerId.isNotEmpty ? buyerId : chat.senderId,
          senderName: buyerName ?? chat.senderName,
        ),
      );
    } else {
      _chatList.insert(
        0,
        ChatListModel(
          productId: message.productId,
          productTitle: message.productTitle,
          imageUrl: message.imageUrl,
          firstVariantPrice: message.firstVariantPrice,
          lastMessage: lastMessageText,
          lastMessageAt: message.createdAt,
          unreadCount: shouldIncrement ? 1 : 0,
          senderId: buyerId.isNotEmpty ? buyerId : null,
          senderName: buyerName,
        ),
      );
    }

    _filteredChatList.clear();
    notifyListeners();
  }

  Future<void> fetchChats(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _fetchAllRows(
        tableId: AppwriteConfig.chat,
        queries: [Query.orderDesc('\$createdAt')],
      );

      final messages = rows
          .map((row) => ChatModel.fromMap(row, currentUserId: userId))
          .where((msg) {
        if (isAdmin) return true;
        return msg.userId == userId || msg.receiverId == userId;
      }).toList();

      final Map<String, List<ChatModel>> grouped = {};
      for (final msg in messages) {
        grouped.putIfAbsent(msg.productId, () => []);
        grouped[msg.productId]!.add(msg);
      }

      final List<ChatListModel> result = [];

      for (final entry in grouped.entries) {
        final productId = entry.key;
        final msgs = entry.value;
        msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final lastMessage = msgs.first;

        // FIX: admin receives messages where receiverId == 'admin' (literal string),
        // not the admin's actual UID — so use the correct receiver to count unread
        final String receiverQuery = isAdmin ? 'admin' : userId;
        final unreadCount = msgs
            .where((m) => !m.isRead && m.receiverId == receiverQuery)
            .length;

        String? productImageUrl;
        if (_productImageCache.containsKey(productId)) {
          productImageUrl = _productImageCache[productId];
        } else {
          try {
            final productRow = await AppwriteConfig.tablesDB.getRow(
              databaseId: AppwriteConfig.databaseId,
              tableId: AppwriteConfig.product,
              rowId: productId,
            );
            if (productRow.data['imageUrl'] != null &&
                (productRow.data['imageUrl'] as List).isNotEmpty) {
              final firstFile = (productRow.data['imageUrl'] as List).first;
              productImageUrl =
                  firstFile is String && firstFile.startsWith('http')
                      ? firstFile
                      : AppwriteConfig.getFileUrl(
                          AppwriteConfig.bucketId,
                          fileId: firstFile,
                        );
            }
          } catch (e) {
            // debugPrint("Error fetching product image for $productId: $e");
          }
          _productImageCache[productId] = productImageUrl;
        }

        final lastMessageText = (lastMessage.uploadImage != null &&
                lastMessage.uploadImage!.isNotEmpty)
            ? "Image"
            : lastMessage.message;

        final buyerId = _resolveBuyerId(msgs);

        String? buyerName;
        if (isAdmin && buyerId.isNotEmpty) {
          buyerName = await _fetchUserName(buyerId);
        }
        buyerName ??= _findBuyerName(msgs);

        result.add(
          ChatListModel(
            productId: productId,
            productTitle: lastMessage.productTitle,
            imageUrl: productImageUrl,
            firstVariantPrice: lastMessage.firstVariantPrice,
            lastMessage: lastMessageText,
            lastMessageAt: lastMessage.createdAt,
            unreadCount: unreadCount,
            senderId: buyerId.isNotEmpty ? buyerId : null,
            senderName: buyerName,
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

  String _resolveBuyerId(List<ChatModel> msgs) {
    for (final m in msgs) {
      if (m.role != 'admin') return m.userId;
    }
    for (final m in msgs) {
      if (m.receiverId.isNotEmpty && m.receiverId != 'admin') {
        return m.receiverId;
      }
    }
    return '';
  }

  final Map<String, String?> _userNameCache = {};

  Future<String?> _fetchUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId];
    try {
      final rows = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      if (rows.rows.isNotEmpty) {
        final name = rows.rows.first.data['fullName'] as String?;
        final trimmed = name?.trim();
        _userNameCache[userId] =
            (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
        return _userNameCache[userId];
      }
    } catch (e) {
      // debugPrint('_fetchUserName error for $userId: $e');
    }
    _userNameCache[userId] = null;
    return null;
  }

  String? _findBuyerName(List<ChatModel> msgs) {
    const placeholders = {'you', 'user', 'customer', 'unknown', 'admin', ''};
    for (final m in msgs) {
      if (m.role != 'admin' &&
          !placeholders.contains(m.fullName.toLowerCase())) {
        return m.fullName;
      }
    }
    for (final m in msgs) {
      if (!placeholders.contains(m.fullName.toLowerCase())) {
        return m.fullName;
      }
    }
    return null;
  }

  Future<void> markChatAsRead({
    required String productId,
    required String userId,
  }) async {
    // Immediately clear badge in UI before async DB call
    for (int i = 0; i < _chatList.length; i++) {
      if (_chatList[i].productId == productId) {
        _chatList[i] = _chatList[i].copyWith(unreadCount: 0);
        break;
      }
    }
    for (int i = 0; i < _filteredChatList.length; i++) {
      if (_filteredChatList[i].productId == productId) {
        _filteredChatList[i] = _filteredChatList[i].copyWith(unreadCount: 0);
        break;
      }
    }
    notifyListeners();

    try {
      // FIX: admin receives messages where receiverId == 'admin' (literal string),
      // not the admin's actual UID
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
    } catch (e) {
      // debugPrint("markChatAsRead error: $e");
    }
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
                chat.lastMessage.toLowerCase().contains(query.toLowerCase()) ||
                (chat.senderName?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          ),
        );
    }
    notifyListeners();
  }

  void disposeRealtime() {
    _subscription?.close();
    _subscription = null;
  }

  // Synchronous update so chat list preview changes instantly on send
  void onLocalMessageSent(ChatModel message) {
    final lastMessageText =
        (message.uploadImage != null && message.uploadImage!.isNotEmpty)
            ? "Image"
            : message.message;

    final String buyerId =
        message.role != 'admin' ? message.userId : message.receiverId;
    final String? buyerName =
        message.role != 'admin' && message.fullName.isNotEmpty
            ? message.fullName
            : null;

    final index = _chatList.indexWhere((c) => c.productId == message.productId);

    if (index != -1) {
      final chat = _chatList.removeAt(index);
      _chatList.insert(
        0,
        chat.copyWith(
          lastMessage: lastMessageText,
          lastMessageAt: message.createdAt,
          senderId: buyerId.isNotEmpty ? buyerId : chat.senderId,
          senderName: buyerName ?? chat.senderName,
        ),
      );
    } else {
      _chatList.insert(
        0,
        ChatListModel(
          productId: message.productId,
          productTitle: message.productTitle,
          imageUrl: message.imageUrl,
          firstVariantPrice: message.firstVariantPrice,
          lastMessage: lastMessageText,
          lastMessageAt: message.createdAt,
          unreadCount: 0,
          senderId: buyerId.isNotEmpty ? buyerId : null,
          senderName: buyerName,
        ),
      );
    }

    _filteredChatList.clear();
    notifyListeners();
  }

  Future<void> deleteChat(String productId, String userId) async {
    try {
      final rows = await _fetchAllRows(
        tableId: AppwriteConfig.chat,
        queries: [
          Query.equal('productId', productId),
          Query.equal('userId', userId),
        ],
      );

      for (final row in rows) {
        await AppwriteConfig.tablesDB.deleteRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.chat,
          rowId: row['\$id'],
        );
      }

      final receiverRows = await _fetchAllRows(
        tableId: AppwriteConfig.chat,
        queries: [
          Query.equal('productId', productId),
          Query.equal('receiverId', userId),
        ],
      );

      for (final row in receiverRows) {
        await AppwriteConfig.tablesDB.deleteRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.chat,
          rowId: row['\$id'],
        );
      }

      _chatList.removeWhere((chat) => chat.productId == productId);
      _filteredChatList.removeWhere((chat) => chat.productId == productId);

      notifyListeners();
    } catch (e) {
      // debugPrint("deleteChat error: $e");
    }
  }
}
