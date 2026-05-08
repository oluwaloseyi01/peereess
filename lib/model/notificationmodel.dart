class NotificationModel {
  final String id;
  final String userId; // who receives the notification

  final String title;
  final String message;
  final String type; // support, order, system, promo
  final String? referenceId; // generic ref (supportId, etc)
  final String? orderId; // specific order reference
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,

    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  /// From Appwrite document
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['\$id'],
      userId: map['userId'],

      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      referenceId: map['referenceId'],
      orderId: map['orderId'],
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.parse(map['\$createdAt']),
    );
  }

  /// To Appwrite document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,

      'title': title,
      'message': message,
      'type': type,
      'referenceId': referenceId,
      'orderId': orderId,
      'isRead': isRead,
    };
  }

  /// Copy with optional changes
  NotificationModel copyWith({
    bool? isRead,
    String? title,
    String? message,
    String? type,
    String? role,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,

      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      referenceId: referenceId,
      orderId: orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
