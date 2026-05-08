class AdminChatModel {
  final String id; // message id

  final String senderId; // user / agent id
  final String receiverId; // admin id

  final String productId;
  final String productTitle;

  final String message;
  final String? uploadImage;

  final bool isRead;
  final DateTime createdAt;

  /// Sender info
  final String senderRole; // 'user' | 'agent' | 'admin'
  final String senderName;

  /// Admin meta
  final int unreadCount;
  final bool isFlagged;
  final bool isBanned;

  const AdminChatModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.productId,
    required this.productTitle,
    required this.message,
    this.uploadImage,
    required this.isRead,
    required this.createdAt,
    required this.senderRole,
    required this.senderName,
    required this.unreadCount,
    this.isFlagged = false,
    this.isBanned = false,
  });

  /// --------------------
  /// COPY WITH
  /// --------------------
  AdminChatModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? productId,
    String? productTitle,
    String? message,
    String? uploadImage,
    bool? isRead,
    DateTime? createdAt,
    String? senderRole,
    String? senderName,
    int? unreadCount,
    bool? isFlagged,
    bool? isBanned,
  }) {
    return AdminChatModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      message: message ?? this.message,
      uploadImage: uploadImage ?? this.uploadImage,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      unreadCount: unreadCount ?? this.unreadCount,
      isFlagged: isFlagged ?? this.isFlagged,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  /// --------------------
  /// FROM MAP
  /// --------------------
  factory AdminChatModel.fromMap(
    Map<String, dynamic> map, {
    required int unreadCount,
    String? roleFromUserTable,
    String? nameFromUserTable,
  }) {
    return AdminChatModel(
      id: map["\$id"] ?? "",
      senderId: map["userId"] ?? "",
      receiverId: map["receiverId"] ?? "",
      productId: map["productId"] ?? "",
      productTitle: map["productTitle"] ?? "",
      message: map["message"] ?? "",
      uploadImage: map["uploadImage"],
      isRead: map["isRead"] ?? false,
      createdAt: map["\$createdAt"] != null
          ? DateTime.parse(map["\$createdAt"])
          : DateTime.now(),
      senderRole: roleFromUserTable ?? map["role"] ?? "Admin",
      senderName: nameFromUserTable ?? map["fullName"] ?? "Unknown",
      unreadCount: unreadCount,
      isFlagged: map["isFlagged"] ?? false,
      isBanned: map["isBanned"] ?? false,
    );
  }

  /// --------------------
  /// TO MAP
  /// --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": senderId,
      "receiverId": receiverId,
      "productId": productId,
      "productTitle": productTitle,
      "message": message,
      "uploadImage": uploadImage,
      "isRead": isRead,
      "\$createdAt": createdAt.toIso8601String(),
      "role": senderRole,
      "fullName": senderName,
      "unreadCount": unreadCount,
      "isFlagged": isFlagged,
      "isBanned": isBanned,
    };
  }
}
