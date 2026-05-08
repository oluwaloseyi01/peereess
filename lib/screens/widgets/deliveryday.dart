import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryDayWidget extends StatelessWidget {
  final int? deliveryDays; // base delivery days
  final TextStyle? style;

  const DeliveryDayWidget({super.key, this.deliveryDays, this.style});

  String getDeliveryText() {
    final today = DateTime.now();

    // Set min and max days
    final int min = deliveryDays ?? 3;
    final int max = deliveryDays != null ? min + 3 : 5;

    // Single day case
    if (min == max) {
      final deliveryDate = today.add(Duration(days: min));
      final formattedDate = DateFormat('EEEE, MMM d').format(deliveryDate);
      if (min == 0) return "Delivery today ($formattedDate)";
      if (min == 1) return "Delivery tomorrow ($formattedDate)";
      return "Delivery in $min days ($formattedDate)";
    }

    // Range case
    final startDate = today.add(Duration(days: min));
    final endDate = today.add(Duration(days: max));
    final formattedStart = DateFormat('EEEE, MMM d').format(startDate);
    final formattedEnd = DateFormat('EEEE, MMM d').format(endDate);

    return "Delivery between $formattedStart – $formattedEnd";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getDeliveryText(),
      maxLines: 2,
      style: style ?? const TextStyle(fontSize: 12, color: Colors.black54),
    );
  }
}
