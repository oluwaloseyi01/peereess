import 'dart:convert';

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? deliveryAddress;
  final String? deliveryPhoneNumber;
  final String? receiverFullName;
  final String? phoneCode;
  final String? state;
  final int level; // ✅ NEW

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.deliveryAddress,
    this.deliveryPhoneNumber,
    this.receiverFullName,
    this.phoneCode,
    this.state,
    this.level = 1, // ✅ NEW
  });

  // ===============================
  // MAP
  // ===============================
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      deliveryAddress: map['deliveryAddress'],
      deliveryPhoneNumber: map['deliveryPhoneNumber'],
      receiverFullName: map['receiverFullName'],
      phoneCode: map['phoneCode'],
      state: map['state'],
      level: int.tryParse(map['level']?.toString() ?? '1') ?? 1, // ✅ NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'deliveryAddress': deliveryAddress,
      'deliveryPhoneNumber': deliveryPhoneNumber,
      'receiverFullName': receiverFullName,
      'phoneCode': phoneCode,
      'state': state,
      'level': level, // ✅ NEW
    };
  }

  // ===============================
  // JSON (FOR OFFLINE CACHE)
  // ===============================
  String toJson() {
    return jsonEncode(toMap());
  }

  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(jsonDecode(source));
  }

  // ===============================
  // COPY WITH
  // ===============================
  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? deliveryAddress,
    String? deliveryPhoneNumber,
    String? receiverFullName,
    String? phoneCode,
    String? state,
    int? level, // ✅ NEW
  }) {
    return UserModel(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPhoneNumber: deliveryPhoneNumber ?? this.deliveryPhoneNumber,
      receiverFullName: receiverFullName ?? this.receiverFullName,
      phoneCode: phoneCode ?? this.phoneCode,
      state: state ?? this.state,
      level: level ?? this.level, // ✅ NEW
    );
  }
}
