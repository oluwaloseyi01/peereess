class AdminChatListModel {
  final String productId; // related product
  final String productTitle; // product title
  final String userId; // user this chat belongs to
  final String userName; // user's full name
  final String? productImageUrl; // optional product image
  final double? firstVariantPrice; // optional product price
  final String lastMessage; // last message in chat
  final DateTime lastMessageAt; // timestamp of last message
  final int unreadCount; // number of unread messages for admin
  final String lastSenderRole; // 'user' or 'admin'
  final String lastSenderName; // last sender's name

  const AdminChatListModel({
    required this.productId,
    required this.productTitle,
    required this.userId,
    required this.userName,
    this.productImageUrl,
    this.firstVariantPrice,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.lastSenderRole,
    required this.lastSenderName,
  });

  /// --------------------
  /// COPY WITH
  /// --------------------
  AdminChatListModel copyWith({
    String? productId,
    String? productTitle,
    String? userId,
    String? userName,
    String? productImageUrl,
    double? firstVariantPrice,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? lastSenderRole,
    String? lastSenderName,
  }) {
    return AdminChatListModel(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      firstVariantPrice: firstVariantPrice ?? this.firstVariantPrice,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSenderRole: lastSenderRole ?? this.lastSenderRole,
      lastSenderName: lastSenderName ?? this.lastSenderName,
    );
  }

  /// --------------------
  /// TO MAP
  /// --------------------
  Map<String, dynamic> toMap() {
    return {
      "productId": productId,
      "productTitle": productTitle,
      "userId": userId,
      "userName": userName,
      "productImageUrl": productImageUrl,
      "firstVariantPrice": firstVariantPrice,
      "lastMessage": lastMessage,
      "\$createdAt": lastMessageAt.toIso8601String(),
      "unreadCount": unreadCount,
      "lastSenderRole": lastSenderRole,
      "lastSenderName": lastSenderName,
    };
  }

  /// --------------------
  /// FROM MAP
  /// --------------------
  factory AdminChatListModel.fromMap(Map<String, dynamic> map) {
    return AdminChatListModel(
      productId: map["productId"] ?? "",
      productTitle: map["productTitle"] ?? "",
      userId: map["userId"] ?? "",
      userName: map["userName"] ?? "Unknown",
      productImageUrl: map["productImageUrl"],
      firstVariantPrice: map["firstVariantPrice"] != null
          ? (map["firstVariantPrice"] as num).toDouble()
          : null,
      lastMessage: map["lastMessage"] ?? "",
      lastMessageAt: map["\$createdAt"] != null
          ? DateTime.parse(map["\$createdAt"])
          : DateTime.now(),
      unreadCount: map["unreadCount"] ?? 0,
      lastSenderRole: map["lastSenderRole"] ?? "user",
      lastSenderName: map["lastSenderName"] ?? "Unknown",
    );
  }
}
