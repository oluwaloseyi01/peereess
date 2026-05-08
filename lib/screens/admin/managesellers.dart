import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/admin/adminsellerproductdetails.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/adminprovider.dart';

class ManageSellerPage extends StatefulWidget {
  const ManageSellerPage({super.key});

  @override
  State<ManageSellerPage> createState() => _ManageSellerPageState();
}

class _ManageSellerPageState extends State<ManageSellerPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// fetch sellers after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchSellers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            Text("Manage sellers", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                /// 🔍 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: adminProvider.searchSellers,
                    decoration: InputDecoration(
                      hintText: "Search seller by name",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                /// 📋 SELLER LIST
                Expanded(
                  child: adminProvider.isLoadingSellers
                      ? const Center(child: CircularProgressIndicator())
                      : adminProvider.filteredSellers.isEmpty
                          ? const Center(child: Text("No sellers found"))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: adminProvider.filteredSellers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final seller =
                                    adminProvider.filteredSellers[index];

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(
                                        IconsaxPlusLinear.shop,
                                        color: Color(0xff9D6E2D),
                                      ),
                                    ),
                                    title: Text(
                                      seller['fullName'] ?? "Unnamed Seller",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          "Phone: ${seller['phoneNumber'] ?? 'N/A'}",
                                        ),
                                        Text(
                                          "Address: ${seller['deliveryAddress'] ?? 'N/A'}",
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SellerDetailsPage(seller: seller),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
