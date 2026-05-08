class ChatListModel {
  final String productId;
  final String productTitle;
  final String? imageUrl;
  final double? firstVariantPrice;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? senderId;
  final String? senderName;

  ChatListModel({
    required this.productId,
    required this.productTitle,
    this.imageUrl,
    this.firstVariantPrice,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.senderId,
    this.senderName,
  });

  ChatListModel copyWith({
    String? productId,
    String? productTitle,
    String? imageUrl,
    double? firstVariantPrice,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? senderId,
    String? senderName,
  }) {
    return ChatListModel(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      firstVariantPrice: firstVariantPrice ?? this.firstVariantPrice,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
    );
  }
}
