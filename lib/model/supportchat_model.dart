class SupportChatModel {
  final String id;
  final String supportId;
  final String userId;
  final String senderId;
  final String senderName;
  final String role;
  final String message;
  final String? imageFileId;
  final bool isFromUser;
  final bool isRead;
  final int unreadCount;
  final DateTime createdAt;

  SupportChatModel({
    required this.id,
    required this.supportId,
    required this.userId,
    required this.senderId,
    required this.senderName,
    required this.role,
    required this.message,
    this.imageFileId,
    required this.isFromUser,
    required this.isRead,
    this.unreadCount = 0,
    required this.createdAt,
  });

  /// FROM APPWRITE DOCUMENT
  factory SupportChatModel.fromMap(Map<String, dynamic> map) {
    // ✅ Try $createdAt (Appwrite ISO string) first, then fall back to
    //    legacy millisecond field, then DateTime.now() as last resort.
    DateTime parsedDate;
    final raw = map['\$createdAt'] ?? map['createdAt'];

    if (raw == null) {
      parsedDate = DateTime.now();
    } else if (raw is String) {
      // Appwrite returns ISO-8601 UTC — parse then convert to local time
      parsedDate = DateTime.parse(raw).toLocal();
    } else if (raw is int) {
      // Legacy millisecond epoch fallback
      parsedDate = DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    } else {
      // Handles the edge case where raw is a double (e.g. 1718000000000.0)
      parsedDate = DateTime.fromMillisecondsSinceEpoch(raw.toInt()).toLocal();
    }

    return SupportChatModel(
      id: (map['\$id'] ?? map['id'] ?? '').toString(),
      supportId: map['supportId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      message: map['message']?.toString() ?? '',
      imageFileId: map['imageFileId']?.toString(),
      isFromUser: map['isFromUser'] as bool? ?? true,
      isRead: map['isRead'] as bool? ?? false,
      unreadCount: map['unreadCount'] != null
          ? (map['unreadCount'] is double
              ? (map['unreadCount'] as double).toInt()
              : map['unreadCount'] as int)
          : 0,
      createdAt: parsedDate,
    );
  }

  /// TO APPWRITE DOCUMENT
  /// ✅ Do NOT include $createdAt here — Appwrite sets it automatically.
  ///    We only store createdAt as millis for any legacy local usage.
  Map<String, dynamic> toMap() {
    return {
      'supportId': supportId,
      'userId': userId,
      'senderId': senderId,
      'senderName': senderName,
      'role': role,
      'message': message,
      'imageFileId': imageFileId,
      'isFromUser': isFromUser,
      'isRead': isRead,
      'unreadCount': unreadCount,
    };
  }

  /// COPY WITH
  SupportChatModel copyWith({
    String? id,
    String? supportId,
    String? userId,
    String? senderId,
    String? senderName,
    String? role,
    String? message,
    String? imageFileId,
    bool? isFromUser,
    bool? isRead,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return SupportChatModel(
      id: id ?? this.id,
      supportId: supportId ?? this.supportId,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      role: role ?? this.role,
      message: message ?? this.message,
      imageFileId: imageFileId ?? this.imageFileId,
      isFromUser: isFromUser ?? this.isFromUser,
      isRead: isRead ?? this.isRead,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
