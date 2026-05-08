import 'package:flutter/material.dart';

enum SellerRecentTab { orders, reviews }

class SellerRecentTabBar extends StatelessWidget {
  final SellerRecentTab activeTab;
  final ValueChanged<SellerRecentTab> onChanged;

  const SellerRecentTabBar({
    super.key,
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            title: "Recent Orders",
            isActive: activeTab == SellerRecentTab.orders,
            onTap: () => onChanged(SellerRecentTab.orders),
          ),
        ),
        Expanded(
          child: _tabButton(
            title: "Recent Reviews",
            isActive: activeTab == SellerRecentTab.reviews,
            onTap: () => onChanged(SellerRecentTab.reviews),
          ),
        ),
      ],
    );
  }

  Widget _tabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40, // fixed height for all tabs
        margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? const Color.fromARGB(255, 3, 59, 6)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
