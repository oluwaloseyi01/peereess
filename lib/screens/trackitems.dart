import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/ordermodel.dart';

class Trackitems extends StatefulWidget {
  final OrderModel order;

  const Trackitems({super.key, required this.order});

  @override
  State<Trackitems> createState() => _TrackitemsState();
}

class _TrackitemsState extends State<Trackitems>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  List<Map<String, String>> decodeStatus(List<String>? rawList) {
    if (rawList == null || rawList.isEmpty) return [];
    final List<Map<String, String>> decoded = [];
    for (var e in rawList) {
      try {
        final map = jsonDecode(e);
        if (map is Map) {
          decoded.add(map.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      } catch (err) {
        debugPrint("Failed to decode delivery status: $err");
      }
    }
    return decoded;
  }

  int get currentStep {
    switch (widget.order.status.toLowerCase()) {
      case "shiped":
        return 1;
      case "intransist":
        return 2;
      case "delivered":
        return 3;
      case "completed":
        return 4;
      default:
        return 0; // order placed
    }
  }

  bool get isCanceled =>
      widget.order.status.toLowerCase() == "cancelled" ||
      widget.order.status.toLowerCase() == "canceled";

  bool get isRejected => widget.order.status.toLowerCase() == "rejected";
  bool get isRefunded =>
      widget.order.status.toLowerCase() == "refunded" ||
      widget.order.status.toLowerCase() == "refund";

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case "shiped":
        return "Shipped";
      case "intransist":
        return "In Transit";
      case "delivered":
        return "Delivered";
      case "completed":
        return "Completed";
      case "cancelled":
      case "canceled":
        return "Cancelled";
      case "rejected":
        return "Rejected";
      case "refunded":
      case "refund":
        return "Refund";
      default:
        return "Order Placed";
    }
  }

  Color _bannerColor(String status) {
    switch (status.toLowerCase()) {
      case "shiped":
        return const Color(0xFF1A6B3C);
      case "intransist":
        return const Color(0xFF1A4A8B);
      case "delivered":
        return const Color(0xFF2E7D32);
      case "completed":
        return const Color(0xFF1A3A6B);
      case "cancelled":
      case "canceled":
      case "rejected":
        return const Color(0xFFC62828);
      case "refunded":
      case "refund":
        return const Color(0xFF5C3D8B);
      default:
        return const Color(0xff9D6E2D); // order placed
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color active = Color(0xff9D6E2D);
    const Color done = Color(0xFF2E7D32);
    final Color pending = Colors.grey.shade300;
    const Color error = Color(0xFFC62828);

    // ✅ 5 steps: order placed → shipped → in transit → delivered → completed
    final List<Map<String, dynamic>> steps = [
      {
        "title": "Order Placed",
        "subtitle": "Your order has been received",
        "icon": Icons.receipt_long_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus1),
      },
      {
        "title": "Shipped",
        "subtitle": "Your order has been shipped",
        "icon": Icons.local_shipping_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus2),
      },
      {
        "title": "In Transit",
        "subtitle": "Your order is on its way",
        "icon": Icons.directions_transit_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus2),
      },
      {
        "title": "Delivered",
        "subtitle": "Package has arrived",
        "icon": Icons.inventory_2_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus3),
      },
      {
        "title": "Completed",
        "subtitle": "Order successfully completed",
        "icon": Icons.check_circle_outline,
        "statuses": decodeStatus(widget.order.deliveryStatus3),
      },
    ];

    if (isCanceled) {
      steps.add({
        "title": "Cancelled",
        "subtitle": "This order was cancelled",
        "icon": Icons.cancel_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus3),
        "isError": true,
      });
    }
    if (isRejected) {
      steps.add({
        "title": "Rejected",
        "subtitle": "This order was rejected",
        "icon": Icons.block_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus3),
        "isError": true,
      });
    }
    if (isRefunded) {
      steps.add({
        "title": "Refund",
        "subtitle": "A refund has been issued",
        "icon": Icons.currency_exchange_outlined,
        "statuses": decodeStatus(widget.order.deliveryStatus3),
        "isError": true,
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              "Your Order",
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status banner ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffB0864C).withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Blinking banner icon
                    AnimatedBuilder(
                      animation: _blinkAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _blinkAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _bannerColor(
                                widget.order.status,
                              ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: _bannerColor(widget.order.status),
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tracking Status",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatStatus(widget.order.status),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _bannerColor(widget.order.status),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Blinking status pill
                    AnimatedBuilder(
                      animation: _blinkAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _blinkAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _bannerColor(
                                widget.order.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _bannerColor(widget.order.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _formatStatus(widget.order.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _bannerColor(widget.order.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "ORDER TIMELINE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              // ── Steps ────────────────────────────────────────
              ...List.generate(steps.length, (index) {
                final step = steps[index];
                final statuses = step["statuses"] as List<Map<String, String>>;
                final bool isErrorStep = step["isError"] == true;
                final bool isDone = index < currentStep;
                final bool isActive = index == currentStep;
                final bool isLast = index == steps.length - 1;

                Color stepColor;
                if (isErrorStep) {
                  stepColor = error;
                } else {
                  stepColor = isDone ? done : (isActive ? active : pending);
                }

                Widget stepCircle = Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDone || isActive || isErrorStep)
                        ? stepColor
                        : Colors.white,
                    border: Border.all(color: stepColor, width: 2),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: stepColor.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    step["icon"] as IconData,
                    size: 18,
                    color: (isDone || isActive || isErrorStep)
                        ? Colors.white
                        : stepColor,
                  ),
                );

                if (isActive) {
                  stepCircle = AnimatedBuilder(
                    animation: _blinkAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 1 - _blinkAnimation.value,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stepColor.withOpacity(0.18),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: _blinkAnimation.value * 0.5,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stepColor.withOpacity(0.25),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: stepCircle,
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left: icon + connector ───────────────
                      SizedBox(
                        width: 52,
                        child: Column(
                          children: [
                            stepCircle,
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: isDone ? done : Colors.grey.shade200,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ── Right: content ───────────────────────
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 20,
                            top: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              isActive
                                  ? AnimatedBuilder(
                                      animation: _blinkAnimation,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: 0.5 +
                                              (_blinkAnimation.value * 0.5),
                                          child: child,
                                        );
                                      },
                                      child: Text(
                                        step["title"] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: stepColor,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      step["title"] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: (isDone || isErrorStep)
                                            ? stepColor
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                step["subtitle"] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (isDone || isActive || isErrorStep)
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300,
                                ),
                              ),
                              if (statuses.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...statuses.map((s) {
                                  String time = "";
                                  if (s["time"] != null &&
                                      s["time"]!.isNotEmpty) {
                                    try {
                                      time = DateFormat.yMMMd().add_jm().format(
                                            DateTime.parse(s["time"]!),
                                          );
                                    } catch (_) {
                                      time = s["time"]!;
                                    }
                                  }
                                  final message = s["message"] ?? "";
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stepColor.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: stepColor.withOpacity(0.15),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 5),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: stepColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF2C2C2C),
                                                ),
                                              ),
                                              if (time.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  time,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
