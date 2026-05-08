import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/model/ordermodel.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/applyforrefund.dart';
import 'package:peereess/screens/home.dart';
import 'package:peereess/screens/review.dart';
import 'package:peereess/screens/trackitems.dart';
import 'package:peereess/screens/widgets/deliveryday.dart';

import 'package:peereess/screens/widgets/orderstatuswidget.dart';
import 'package:provider/provider.dart';

class OrderHistoryDetail extends StatelessWidget {
  final OrderModel order;

  const OrderHistoryDetail({super.key, required this.order});

  // ── Palette ───────────────────────────────────────────────
  static const _gradientTop = Color.fromARGB(255, 217, 194, 162);
  static const _brown = Color(0xff9D6E2D);
  static const _brownDeep = Color(0xFF6B4A1B);
  static const _cardBg = Colors.white;

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPickup = order.selectedPickup != null;
    final formatter = NumberFormat("#,##0", "en_US");
    final int totalItems = order.cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);

    final bool canReviewOrRefund = order.status.toLowerCase() == "delivered" ||
        order.status.toLowerCase() == "completed" ||
        order.status.toLowerCase() == "order placed" ||
        order.status.toLowerCase() == "shipped" || // ✅ was 'ondelivery'
        order.status.toLowerCase() == "canceled";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xff9D6E2D),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
            const Text(
              "Order summary",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientTop, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order summary card ──────────────────────
              _buildOrderSummaryCard(
                formatter,
                formattedDate,
                totalItems,
                context,
              ),
              const SizedBox(height: 14),

              // ── Status + delivery row ───────────────────
              _buildStatusRow(context, canReviewOrRefund),
              const SizedBox(height: 14),

              // ── Items label ─────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  "Items in Your Order",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _brownDeep,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // ── Item cards ──────────────────────────────
              ...order.cartItems.map(
                (item) =>
                    _buildItemCard(context, item, formatter, canReviewOrRefund),
              ),

              const SizedBox(height: 14),

              // ── Track + Return home ─────────────────────
              _buildActionsCard(context),
              const SizedBox(height: 14),

              // ── Payment + Delivery info ─────────────────
              _buildInfoCard(context, isPickup, formatter),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 217, 194, 162),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: Color(0xff9D6E2D),
                    ),
                  ),
                ),
                10.getWidthWhiteSpacing,
                const Text(
                  "Order summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Order summary card ─────────────────────────────────────
  Widget _buildOrderSummaryCard(
    NumberFormat formatter,
    String formattedDate,
    int totalItems,
    BuildContext context,
  ) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ${order.orderId}",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _brownDeep,
                      ),
                    ),
                    Text(
                      "Placed on $formattedDate",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.brown.shade100),
          const SizedBox(height: 10),
          _InfoRow(
            label: "Items",
            value: "$totalItems item${totalItems > 1 ? 's' : ''}",
          ),
          const SizedBox(height: 4),
          _InfoRow(
            label: "Subtotal",
            value: "₦${formatter.format(order.totalPrice)}",
            valueStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: _brown,
            ),
          ),
          if (order.deliveryCode != null && order.deliveryCode!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(
              label: "Delivery Code",
              value: order.deliveryCode!,
              valueStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _brownDeep,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Status + delivery row ──────────────────────────────────
  Widget _buildStatusRow(BuildContext context, bool canReviewOrRefund) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ replaced _statusBg / _statusColor container with OrderStatusBadge
          OrderStatusBadge(status: order.status),
          const SizedBox(height: 12),
          DeliveryDayWidget(deliveryDays: order.deliveryDays),
        ],
      ),
    );
  }

  // ── Item card ──────────────────────────────────────────────
  Widget _buildItemCard(
    BuildContext context,
    dynamic item,
    NumberFormat formatter,
    bool canReviewOrRefund,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final productProvider = context.read<ProductProvider>();

                    final matches = productProvider.products
                        .where((p) => p.productId == item.productId)
                        .toList();

                    if (matches.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            "Product Unavailable",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B4A1B),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.remove_shopping_cart_outlined,
                                size: 52,
                                color: Colors.brown.shade200,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "\"${item.title}\" is no longer available.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.brown.shade600,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "OK",
                                style: TextStyle(color: Color(0xff9D6E2D)),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      "/productDetails",
                      arguments: {"product": matches.first},
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: item.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.image,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.brown.shade50),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.brown.shade50,
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.brown.shade300,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.brown.shade50,
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.brown.shade300,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _brownDeep,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item.variant.isNotEmpty)
                        _MetaChip(label: item.variant),
                      if (item.color != null && item.color!.isNotEmpty)
                        _MetaChip(label: "Color: ${item.color}"),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Qty: ${item.quantity}",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.brown.shade400,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "₦${formatter.format(item.price)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _brown,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons (per item)
            if (canReviewOrRefund) ...[
              const SizedBox(height: 10),
              Divider(color: Colors.brown.shade100),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Review
                  Expanded(
                    child: _ActionButton(
                      label: "Write Review",
                      icon: Icons.star_border_rounded,
                      color: _brown,
                      bgColor: const Color(0xFFFAF0E6),
                      borderColor: _gradientTop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewPage(
                            product: ProductModel.fromMap({
                              'productId': item.productId,
                              'title': item.title,
                              'imageUrl': [item.image],
                              'description': '',
                              'quantity': 0,
                              'sellerName': '',
                              'discount': 0,
                              'likes': 0,
                              'category': '',
                              'likedBy': [],
                              'variants': [],
                              'reviews': [],
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refund
                  Expanded(
                    child: _ActionButton(
                      label: "Apply Refund",
                      icon: Icons.assignment_return_outlined,
                      color: Colors.red.shade400,
                      bgColor: Colors.red.shade50,
                      borderColor: Colors.red.shade200,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplyForRefund(order: order),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Track + Return home card ───────────────────────────────
  Widget _buildActionsCard(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          AppButtons(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Trackitems(order: order)),
            ),
            text: "Track order",
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Home()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gradientTop, width: 1.5),
              ),
              child: const Text(
                "Return home",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _brown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment + Delivery info card ───────────────────────────
  Widget _buildInfoCard(
    BuildContext context,
    bool isPickup,
    NumberFormat formatter,
  ) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment
          _SectionHeader(icon: Icons.payment_rounded, title: "Payment Method"),
          const SizedBox(height: 6),
          Text(
            order.paymentMethod ?? 'N/A',
            style: TextStyle(
              fontSize: 13,
              color: Colors.brown.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Pickup
          if (isPickup) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.brown.shade100),
            const SizedBox(height: 10),
            _SectionHeader(icon: Icons.store_outlined, title: "Pickup Station"),
            const SizedBox(height: 8),
            _InfoRow(
              label: "Station",
              value: order.selectedPickup!.pickupstation,
            ),
            const SizedBox(height: 4),
            _InfoRow(label: "Address", value: order.selectedPickup!.address),
            const SizedBox(height: 4),
            _InfoRow(label: "Phone", value: order.selectedPickup!.phoneNumber),
            const SizedBox(height: 4),
            _InfoRow(
              label: "Area",
              value:
                  "${order.selectedPickup!.region}, ${order.selectedPickup!.city}",
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _gradientTop.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.brown.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Mon–Fri 8AM–6PM  ·  Sat 9AM–6PM",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Delivery
          if (!isPickup) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.brown.shade100),
            const SizedBox(height: 10),
            _SectionHeader(
              icon: Icons.local_shipping_outlined,
              title: "Delivery Details",
            ),
            const SizedBox(height: 8),
            if (order.receiverFullName != null &&
                order.receiverFullName!.isNotEmpty)
              _InfoRow(label: "Receiver", value: order.receiverFullName!),
            const SizedBox(height: 4),
            _InfoRow(label: "Address", value: order.deliveryAddress ?? 'N/A'),
            const SizedBox(height: 4),
            _InfoRow(label: "Phone", value: order.deliveryPhoneNumber ?? 'N/A'),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.brown.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.brown.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF2C1A0E),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff9D6E2D)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B4A1B),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDE0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          color: Color(0xFF6B4A1B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
