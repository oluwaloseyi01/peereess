import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

class Productupload extends StatefulWidget {
  const Productupload({super.key});

  @override
  State<Productupload> createState() => _ProductuploadState();
}

class _ProductuploadState extends State<Productupload> {
  final List<String> categories = const [
    "Bag",
    "Fashion",
    "Clothing",
    "Dresses",
    "Jeans",
    "Footwear",
    "Purses",
    "Fragrance",
    "Makeup",
    "Skincare",
    "Supplements",
    "Jewelry",
    "Hair",
    "Watches",
    "Heels",
    "Sneakers",
    "Accessories",
    "Wellness",
    "Beauty",
    "Gym",
    "Tops & Blouses",
    "T-Shirts",
    "Skirts",
    "Shorts",
    "Jackets & Coats",
    "Suits & Blazers",
    "Swimwear",
    "Lingerie & Sleepwear",
    "Maternity Wear",
    "Kids Clothing",
    "Women's Clothing",
    "Traditional",
    "Shoe",
    "Sandals & Slippers",
    "Boots",
    "Loafers",
    "Flats",
    "Kids Shoes",
    "Sports Shoes",
    "Luggage",
    "Belts",
    "Scarves & Wraps",
    "Sunglasses",
    "Hats & Caps",
    "Gloves",
    "Shaving",
    "Bath & Body",
    "Deodorants",
    "Hair Accessories",
    "Necklaces",
    "Bracelets",
    "Earrings",
    "Rings",
    "Anklets",
    "Fitness Equipment",
    "Medical & Safety",
    "Maternity & Baby",
    "Baby Clothing",
    "Baby Accessories",
    "Baby Care",
    "Feeding & Nursing",
    "Toys & Games",
    "Kids Accessories",
    "Home & Lifestyle",
    "Home Decor",
    "Kitchen & Dining",
    "Bedding & Bath",
    "Storage & Organization",
    "Candles & Aromatherapy",
    "Cleaning Supplies",
    "Furniture",
    "Garden & Outdoor",
    "Pet Supplies",
    "Tech & Gadgets",
    "Phones & Accessories",
    "Laptops & Computers",
    "Audio & Headphones",
    "Smart Devices",
    "Cameras & Photography",
    "Gaming",
    "Cables & Chargers",
    "Wearable Tech",
    "Gifts Collections",
    "Seasonal Categories",
    "Valentine's Collection",
    "Christmas Collection",
    "Back to School",
    "Bridal",
    "Events",
    "Eco & Sustainable",
    "Luxury & Premium",
    "Vintage & Thrifted",
    "Books",
    "Art & Craft",
    "Stationery",
    "Beverages",
    "Foods",
    "Car Accessories",
    "Motorcycle Accessories",
    "Others",
  ];

  void _openCategorySheet(
    BuildContext context,
    ProductUploadProvider provider,
  ) {
    final TextEditingController searchController = TextEditingController();
    List<String> filtered = List.from(categories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'poppins',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search category...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xff9D6E2D),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5EDE0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          filtered = categories
                              .where(
                                (c) =>
                                    c.toLowerCase().contains(val.toLowerCase()),
                              )
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final cat = filtered[i];
                        final isSelected =
                            provider.categoryController.text == cat;
                        return InkWell(
                          onTap: () {
                            provider.categoryController.text = cat;
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF5EDE0)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[100]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xff9D6E2D)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xff9D6E2D),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
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
        child: Center(child: LogoLoadingIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ProductUploadProvider(),
      child: Consumer<ProductUploadProvider>(
        builder: (context, provider, _) {
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
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xff9D6E2D),
                        ),
                      ),
                    ),
                  ),
                  20.getWidthWhiteSpacing,
                  const Text(
                    "Upload a product",
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── IMAGES ─────────────────────────────────────────────────
                    _buildSectionLabel("Product Images"),
                    8.getHeightWhiteSpacing,
                    GestureDetector(
                      onTap: provider.pickImages,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: provider.webImages.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                itemCount: provider.webImages.length < 6
                                    ? provider.webImages.length + 1
                                    : provider.webImages.length,
                                itemBuilder: (context, index) {
                                  if (index < provider.webImages.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          provider.webImages[index],
                                          width: 155,
                                          height: 155,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: provider.pickImages,
                                    child: Container(
                                      width: 155,
                                      height: 155,
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 28,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Add",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 36,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap to select up to 6 images",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    24.getHeightWhiteSpacing,

                    // ── BASIC INFO ──────────────────────────────────────────────
                    _buildSectionLabel("Basic Info"),
                    12.getHeightWhiteSpacing,
                    _buildField(
                      controller: provider.titleController,
                      label: "Product Title",
                      icon: Icons.title,
                    ),
                    12.getHeightWhiteSpacing,
                    _buildField(
                      controller: provider.descriptionController,
                      label: "Description",
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    24.getHeightWhiteSpacing,

                    // ── PRICING & DETAILS ───────────────────────────────────────
                    _buildSectionLabel("Pricing & Details"),
                    12.getHeightWhiteSpacing,
                    _buildField(
                      controller: provider.discountController,
                      label: "Discount (%)",
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                    ),
                    12.getHeightWhiteSpacing,

                    // Searchable Category
                    GestureDetector(
                      onTap: () => _openCategorySheet(context, provider),
                      child: AbsorbPointer(
                        child: AnimatedBuilder(
                          animation: provider.categoryController,
                          builder: (_, __) => _buildField(
                            controller: provider.categoryController,
                            label: "Category",
                            icon: Icons.category_outlined,
                            suffix: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xff9D6E2D),
                            ),
                            readOnly: true,
                            hint: "Tap to select category",
                          ),
                        ),
                      ),
                    ),
                    12.getHeightWhiteSpacing,

                    // Refundable Dropdown
                    _buildDropdown(
                      label: "Refundable",
                      icon: Icons.replay_outlined,
                      value: provider.refundableController.text.isEmpty
                          ? null
                          : provider.refundableController.text,
                      items: const [
                        DropdownMenuItem(
                          value: "refundable",
                          child: Text("Refundable"),
                        ),
                        DropdownMenuItem(
                          value: "nonrefundable",
                          child: Text("Non-refundable"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          provider.refundableController.text = val;
                      },
                    ),
                    12.getHeightWhiteSpacing,
                    _buildField(
                      controller: provider.shippedFromController,
                      label: "Shipped From",
                      icon: Icons.flight_land_outlined,
                      hint: "Nigeria / Abroad (optional)",
                    ),
                    12.getHeightWhiteSpacing,
                    _buildField(
                      controller: provider.deliveryDaysController,
                      label: "Delivery Days",
                      icon: Icons.local_shipping_outlined,
                      hint: "e.g. 2, 3",
                      keyboardType: TextInputType.number,
                    ),
                    12.getHeightWhiteSpacing,
                    _buildField(
                      controller: provider.colorsController,
                      label: "Colors",
                      icon: Icons.palette_outlined,
                      hint: "Comma separated e.g. Red, Blue",
                    ),
                    24.getHeightWhiteSpacing,

                    // ── VARIANTS ────────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionLabel("Variants"),
                        TextButton.icon(
                          onPressed: provider.addVariant,
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xff9D6E2D),
                            size: 18,
                          ),
                          label: const Text(
                            "Add",
                            style: TextStyle(
                              color: Color(0xff9D6E2D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    4.getHeightWhiteSpacing,
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.variants.length,
                      itemBuilder: (context, index) {
                        final variant = provider.variants[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Variant ${index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xff9D6E2D),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          provider.removeVariant(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                10.getHeightWhiteSpacing,
                                _buildField(
                                  controller: variant.descriptionController,
                                  label: "Description",
                                  hint: "e.g. size, color",
                                  icon: Icons.label_outline,
                                ),
                                10.getHeightWhiteSpacing,
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: variant.priceController,
                                        label: "Price",
                                        hint: "No comma",
                                        icon: Icons.money,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    12.getWidthWhiteSpacing,
                                    Expanded(
                                      child: _buildField(
                                        controller: variant.stockController,
                                        label: "Stock",
                                        hint: "e.g. 10",
                                        icon: Icons.inventory_2_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    24.getHeightWhiteSpacing,

                    // ── UPLOAD BUTTON ───────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.createProduct(
                                  context,
                                  authProvider.userId,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff9D6E2D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Upload Product",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'poppins',
                                ),
                              ),
                      ),
                    ),
                    40.getHeightWhiteSpacing,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── HELPER WIDGETS ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        fontFamily: 'poppins',
        color: Color(0xff6B4A1E),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xff9D6E2D), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff9D6E2D), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xff9D6E2D), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff9D6E2D), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }
}
