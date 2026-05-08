class ChatModel {
  final String id;
  final String userId;
  final String receiverId;
  final String productId;
  final String productTitle;
  final String message;
  final String? imageUrl;
  final String? uploadImage;
  final double? firstVariantPrice;
  final bool isRead;
  final bool isTyping;
  final DateTime createdAt;
  final bool isMe;
  final String role;
  final String fullName;

  const ChatModel({
    required this.id,
    required this.userId,
    required this.receiverId,
    required this.productId,
    required this.productTitle,
    required this.message,
    this.imageUrl,
    this.uploadImage,
    this.firstVariantPrice,
    required this.isRead,
    required this.isTyping,
    required this.createdAt,
    required this.isMe,
    required this.role,
    required this.fullName,
  });

  ChatModel copyWith({
    String? id,
    String? userId,
    String? receiverId,
    String? productId,
    String? productTitle,
    String? message,
    String? imageUrl,
    String? uploadImage,
    double? firstVariantPrice,
    bool? isRead,
    bool? isTyping,
    DateTime? createdAt,
    bool? isMe,
    String? role,
    String? fullName,
  }) {
    return ChatModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      receiverId: receiverId ?? this.receiverId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      uploadImage: uploadImage ?? this.uploadImage,
      firstVariantPrice: firstVariantPrice ?? this.firstVariantPrice,
      isRead: isRead ?? this.isRead,
      isTyping: isTyping ?? this.isTyping,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "receiverId": receiverId,
      "productId": productId,
      "productTitle": productTitle,
      "message": message,
      "imageUrl": imageUrl,
      "uploadImage": uploadImage,
      "firstVariantPrice": firstVariantPrice,
      "isRead": isRead,
      "isTyping": isTyping,
      "\$createdAt": createdAt.toIso8601String(),
      "isMe": isMe,
      "role": role,
      "fullName": fullName,
    };
  }

  factory ChatModel.fromMap(
    Map<String, dynamic> map, {
    required String currentUserId,
    String? roleFromUserTable,
    String? fullNameFromUserTable,
  }) {
    final senderId = map["userId"] ?? "";

    // Derive role: prefer map value, then passed-in override, then guess from senderId
    final String role = (map["role"] as String?)?.isNotEmpty == true
        ? map["role"]
        : roleFromUserTable ?? (senderId == "admin" ? "admin" : "user");

    // FIX: read fullName from the map first, stripping empty strings,
    // then fall back to the passed-in override. Never default to "Unknown"
    // so that _findBuyerName can detect truly missing names.
    final rawFullName = map["fullName"];
    final String fullName;
    if (rawFullName is String && rawFullName.trim().isNotEmpty) {
      fullName = rawFullName.trim();
    } else if (fullNameFromUserTable != null &&
        fullNameFromUserTable.trim().isNotEmpty) {
      fullName = fullNameFromUserTable.trim();
    } else {
      fullName = ''; // empty string — NOT "Unknown"
    }

    return ChatModel(
      id: map["id"] ?? map["\$id"] ?? "",
      userId: senderId,
      receiverId: map["receiverId"] ?? "admin",
      productId: map["productId"] ?? "",
      productTitle: map["productTitle"] ?? "",
      message: map["message"] ?? "",
      imageUrl: map["imageUrl"],
      uploadImage: map["uploadImage"],
      firstVariantPrice: map["firstVariantPrice"] != null
          ? (map["firstVariantPrice"] as num).toDouble()
          : null,
      isRead: map["isRead"] ?? false,
      isTyping: map["isTyping"] ?? false,
      createdAt: map["\$createdAt"] != null
          ? DateTime.parse(map["\$createdAt"])
          : DateTime.now(),
      isMe: senderId == currentUserId,
      role: role,
      fullName: fullName,
    );
  }
}
