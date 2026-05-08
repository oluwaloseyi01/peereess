import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/filter_provider.dart';
import 'package:provider/provider.dart';

class Filter extends StatefulWidget {
  const Filter({super.key});

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  double? minPriceInput;
  double? maxPriceInput;

  @override
  Widget build(BuildContext context) {
    final filterProvider = context.watch<ProductFilterProvider>();

    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                child: Row(
                  children: [
                    // Back button
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

                    // Center title
                    Expanded(
                      child: Center(
                        child: const Text(
                          "Filter",
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Right side
                    GestureDetector(
                      onTap: () => filterProvider.clearAll(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.red.shade200, width: 1),
                        ),
                        child: Text(
                          "Clear all",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // ── Scrollable body ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 11),
                      // ── Sort By ──────────────────────────────
                      _SectionCard(
                        title: "Sort By",
                        icon: Icons.sort_rounded,
                        child: Column(
                          children: [
                            _FilterChipRow(
                              options: const ['popularity', 'new', 'rating'],
                              labels: const [
                                'Popularity',
                                'New In',
                                'Best Rating',
                              ],
                              selected: filterProvider.sortBy,
                              onSelect: filterProvider.setSortBy,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Price ────────────────────────────────
                      _SectionCard(
                        title: "Price Range (₦)",
                        icon: Icons.payments_outlined,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _PriceField(
                                    label: "Min",
                                    hint: "e.g. 500",
                                    initialValue:
                                        filterProvider.minPrice?.toString(),
                                    onChanged: (val) {
                                      minPriceInput = double.tryParse(val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "—",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PriceField(
                                    label: "Max",
                                    hint: "e.g. 50,000",
                                    initialValue:
                                        filterProvider.maxPrice?.toString(),
                                    onChanged: (val) {
                                      maxPriceInput = double.tryParse(val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  filterProvider.setPrice(
                                    minPriceInput,
                                    maxPriceInput,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff9D6E2D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Apply Price",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Discount ─────────────────────────────
                      _SectionCard(
                        title: "Discount",
                        icon: Icons.local_offer_outlined,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [50, 40, 30, 20, 10].map((val) {
                            final isSelected = filterProvider.discount == val;
                            return GestureDetector(
                              onTap: () => filterProvider.setDiscount(val),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xff9D6E2D)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xff9D6E2D)
                                        : Colors.grey.shade300,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xff9D6E2D,
                                            ).withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      "$val% or more",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // ── Shipped From ─────────────────────────
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xff9D6E2D)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1A0E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Filter Chip Row ───────────────────────────────────────────────────────────
class _FilterChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String? selected;
  final void Function(String) onSelect;

  const _FilterChipRow({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final isSelected = selected == options[i];
        return GestureDetector(
          onTap: () => onSelect(options[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xff9D6E2D) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? const Color(0xff9D6E2D) : Colors.grey.shade300,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xff9D6E2D).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Price Field ───────────────────────────────────────────────────────────────
class _PriceField extends StatelessWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final void Function(String) onChanged;

  const _PriceField({
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: TextInputType.number,
          initialValue: initialValue,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xff9D6E2D),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
