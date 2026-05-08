import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/screens/admin/adminproductdatails.dart';
import 'package:peereess/screens/supportchatscreen.dart';
import 'package:provider/provider.dart';

class SellerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> seller;

  const SellerDetailsPage({super.key, required this.seller});

  @override
  State<SellerDetailsPage> createState() => _SellerDetailsPageState();
}

class _SellerDetailsPageState extends State<SellerDetailsPage> {
  bool isLoading = false;
  bool isUpgrading = false;
  List<Map<String, dynamic>> sellerProducts = [];
  late Map<String, dynamic> seller;

  @override
  void initState() {
    super.initState();
    seller = Map<String, dynamic>.from(widget.seller);
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerProducts() async {
    setState(() => isLoading = true);

    try {
      final sellerUserId = seller['userId']?.toString().trim();
      if (sellerUserId == null || sellerUserId.isEmpty) return;

      final result = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal("userId", sellerUserId),
          Query.orderDesc("\$createdAt"),
        ],
      );

      setState(() {
        sellerProducts =
            result.rows.map((row) => row.data..["rowId"] = row.$id).toList();
      });
    } catch (e) {
      debugPrint("FETCH SELLER PRODUCTS ERROR: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _upgradeLevel(int level) async {
    final sellerUserId = seller['userId']?.toString().trim();
    if (sellerUserId == null || sellerUserId.isEmpty) return;

    setState(() => isUpgrading = true);

    try {
      final functions = Functions(AppwriteConfig.client);
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.createUserFunction,
        body: jsonEncode({
          'action': 'upgradeLevel',
          'adminSecret': AppwriteConfig.adminPanelSecret,
          'targetUserId': sellerUserId,
          'level': level,
        }),
      );

      final result = jsonDecode(execution.responseBody) as Map<String, dynamic>;

      if (result['status'] == true) {
        setState(() => seller['level'] = level);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Seller upgraded to Level $level"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to upgrade level'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isUpgrading = false);
    }
  }

  void _showUpgradeLevelSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "Upgrade Seller Level",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Current level: ${seller['level'] ?? 1}",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // Level options 2–5
              ...List.generate(4, (i) {
                final level = i + 2; // 2, 3, 4, 5
                final isCurrent = seller['level'] == level;
                return GestureDetector(
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _upgradeLevel(level);
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCurrent ? const Color(0xFFF5EDE0) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xff9D6E2D)
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xff9D6E2D)
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "$level",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color:
                                    isCurrent ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Level $level",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrent
                                ? const Color(0xff9D6E2D)
                                : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (isCurrent)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xff9D6E2D),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text(seller['fullName'] ?? 'Seller Details'),
          ],
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🧑 SELLER INFO
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller['fullName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Phone: ${seller['phoneNumber'] ?? 'N/A'}"),
                        Text("Level: ${seller['level'] ?? 'N/A'}"),
                        Text("Address: ${seller['deliveryAddress'] ?? 'N/A'}"),
                        Text("Email: ${seller['email'] ?? 'N/A'}"),
                        10.getHeightWhiteSpacing,

                        // ── ACTION BUTTONS ─────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: AppButtons(
                                text: "Send Message",
                                onPressed: () async {
                                  try {
                                    final account =
                                        await AppwriteConfig.account.get();
                                    final adminUserId = account.$id;

                                    final sellerUserId =
                                        seller['userId']?.toString().trim() ??
                                            '';
                                    final sellerName =
                                        seller['fullName']?.toString() ??
                                            'Seller';

                                    if (sellerUserId.isEmpty) return;

                                    final existingChat =
                                        await AppwriteConfig.tablesDB.listRows(
                                      databaseId: AppwriteConfig.databaseId,
                                      tableId: AppwriteConfig.supportchat,
                                      queries: [
                                        Query.equal('userId', sellerUserId),
                                        Query.orderAsc('\$createdAt'),
                                        Query.limit(1),
                                      ],
                                    );

                                    String supportId;

                                    if (existingChat.rows.isNotEmpty) {
                                      supportId = existingChat
                                          .rows.first.data['supportId']
                                          .toString();
                                    } else {
                                      supportId = ID.unique();
                                      await AppwriteConfig.tablesDB.createRow(
                                        databaseId: AppwriteConfig.databaseId,
                                        tableId: AppwriteConfig.supportchat,
                                        rowId: ID.unique(),
                                        data: {
                                          'supportId': supportId,
                                          'userId': sellerUserId,
                                          'senderName': sellerName,
                                        },
                                      );
                                    }

                                    context
                                        .read<SupportChatProvider>()
                                        .clearUnreadForSupport(supportId);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SupportChatScreen(
                                          supportId: supportId,
                                          userId: adminUserId,
                                          userName: sellerName,
                                          role: "admin",
                                        ),
                                      ),
                                    );
                                  } catch (e, s) {
                                    debugPrint("❌ Error opening chat: $e");
                                    debugPrintStack(stackTrace: s);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: isUpgrading
                                  ? const Center(
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xff9D6E2D),
                                        ),
                                      ),
                                    )
                                  : AppButtons(
                                      text: "Upgrade Level",
                                      onPressed: _showUpgradeLevelSheet,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 🛒 SELLER PRODUCTS HEADER WITH COUNT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Seller Products",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "(${sellerProducts.length} items)",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                /// 📦 PRODUCT LIST
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : sellerProducts.isEmpty
                        ? const Center(
                            child: Text("No products found for this seller"),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sellerProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final product = sellerProducts[index];

                              String imageUrl = '';
                              if (product['imageUrl'] != null) {
                                if (product['imageUrl'] is List &&
                                    product['imageUrl'].isNotEmpty) {
                                  imageUrl = product['imageUrl'][0].toString();
                                } else if (product['imageUrl'] is String) {
                                  imageUrl = product['imageUrl'];
                                }
                              }

                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  leading: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[200],
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                  Icons.image_not_supported),
                                        )
                                      : const Icon(Icons.image_not_supported),
                                  title: Text(
                                    product['title'] ?? 'Unnamed Product',
                                  ),
                                  trailing: Text(
                                    product['status'] ?? 'pending',
                                    style: TextStyle(
                                      color: product['status'] == 'approved'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdminProductDetailPage(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
