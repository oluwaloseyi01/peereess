class DeliveryFeeModel {
  final double generalDeliveryFee;

  DeliveryFeeModel({required this.generalDeliveryFee});

  factory DeliveryFeeModel.fromMap(Map<String, dynamic> map) {
    return DeliveryFeeModel(
      generalDeliveryFee: (map['generalDeliveryFee'] ?? 0).toDouble(),
    );
  }
}
