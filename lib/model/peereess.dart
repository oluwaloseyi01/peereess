class Peereess {
  final String id; // Appwrite document ID
  final String pickupstation;
  final String phoneNumber;
  final String address;
  final int fee;
  final String region;
  final String city;

  Peereess({
    required this.id,
    required this.pickupstation,
    required this.phoneNumber,
    required this.address,
    required this.fee,
    required this.region,
    required this.city,
  });

  /// FROM APPWRITE MAP
  factory Peereess.fromMap(Map<String, dynamic> map, {String? id}) {
    return Peereess(
      id: id ?? '', // use provided id or empty string
      pickupstation: map['pickupstation'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      fee: map['fee'] is int
          ? map['fee']
          : int.tryParse(map['fee'].toString()) ?? 0,
      region: map['region'] ?? '',
      city: map['city'] ?? '',
    );
  }

  /// TO MAP (for saving back to Appwrite)
  Map<String, dynamic> toMap() {
    return {
      'pickupstation': pickupstation,
      'phoneNumber': phoneNumber,
      'address': address,
      'fee': fee,
      'region': region,
      'city': city,
    };
  }

  /// COPY WITH
  Peereess copyWith({
    String? id,
    String? pickupstation,
    String? phoneNumber,
    String? address,
    int? fee,
    String? region,
    String? city,
  }) {
    return Peereess(
      id: id ?? this.id,
      pickupstation: pickupstation ?? this.pickupstation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      fee: fee ?? this.fee,
      region: region ?? this.region,
      city: city ?? this.city,
    );
  }
}
