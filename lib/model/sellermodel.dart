class Sellermodel {
  final String sellerId;
  final String sellerbrandname;
  final String sellerPhoneNumber;

  final String? sellerAddress;

  final String? status;
  final String? sellerEmail;

  Sellermodel({
    required this.sellerId,
    required this.sellerbrandname,
    required this.sellerPhoneNumber,

    this.sellerAddress,

    this.status,
    this.sellerEmail,
  });

  factory Sellermodel.fromMap(Map<String, dynamic> map) {
    return Sellermodel(
      sellerId: map['sellerId'] ?? '',
      sellerbrandname: map['sellerbrandname'] ?? '',
      sellerPhoneNumber: map['sellerPhoneNumber'] ?? '',

      sellerAddress: map['sellerAddress'],

      status: map['status'],
      sellerEmail: map['sellerEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerbrandname': sellerbrandname,
      'sellerPhoneNumber': sellerPhoneNumber,

      'sellerAddress': sellerAddress,

      'status': status,
      'sellerEmail': sellerEmail,
    };
  }

  // 🔹 CopyWith method to update only specific fields
  Sellermodel copyWith({
    String? sellerbrandname,
    String? sellerPhoneNumber,

    String? sellerAddress,

    String? status,
    String? sellerEmail,
  }) {
    return Sellermodel(
      sellerId: sellerId, // sellerId stays the same
      sellerbrandname: sellerbrandname ?? this.sellerbrandname,
      sellerPhoneNumber: sellerPhoneNumber ?? this.sellerPhoneNumber,

      sellerAddress: sellerAddress ?? this.sellerAddress,

      status: status ?? this.status,
      sellerEmail: sellerEmail ?? this.sellerEmail,
    );
  }
}
