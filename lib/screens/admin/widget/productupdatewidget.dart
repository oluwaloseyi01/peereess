import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:provider/provider.dart';

class EditProductDetailPage extends StatefulWidget {
  final ProductModel product;
  const EditProductDetailPage({super.key, required this.product});
  @override
  State<EditProductDetailPage> createState() => _EditProductDetailPageState();
}

class _EditProductDetailPageState extends State<EditProductDetailPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStatus;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;
  late TextEditingController _colorsController;
  late TextEditingController _deliveryDaysController;
  late TextEditingController _shippedFromController;
  late TextEditingController _deliveryFeeController; // NEW
  late TextEditingController _ratingController; // NEW
  late TextEditingController _statusController; // NEW

  String _refundable = 'nonrefundable';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _selectedStatus = p.status; // <-- ADD THIS
    _statusController = TextEditingController(text: p.status);
    _titleController = TextEditingController(text: p.title);
    _descriptionController = TextEditingController(text: p.description);
    _quantityController = TextEditingController(text: p.quantity.toString());
    _categoryController = TextEditingController(text: p.category);
    _colorsController = TextEditingController(text: p.colors.join(','));
    _deliveryDaysController = TextEditingController(
      text: p.deliveryDays?.toString() ?? '',
    );
    _shippedFromController = TextEditingController(text: p.shippedFrom ?? '');
    _deliveryFeeController = TextEditingController(
      text: p.deliveryFee?.toString() ?? '',
    ); // NEW
    _ratingController = TextEditingController(
      text: p.rating?.toString() ?? '',
    ); //// NEW
    _refundable = p.refundable?.toLowerCase() == 'refundable'
        ? 'refundable'
        : 'nonrefundable';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _colorsController.dispose();
    _deliveryDaysController.dispose();
    _shippedFromController.dispose();
    _deliveryFeeController.dispose(); // NEW
    _ratingController.dispose(); // NEW
    _statusController.dispose(); // NEW

    super.dispose();
  }

  Future<void> _updateProduct(ProductUploadProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    final Map<String, dynamic> updatedFields = {
      'status': _selectedStatus!, // <-- guaranteed non-null now
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'category': _categoryController.text.trim(),
      'colors': _colorsController.text.split(',').map((e) => e.trim()).toList(),
      'deliveryDays': int.tryParse(_deliveryDaysController.text) ?? 0,
      'shippedFrom': _shippedFromController.text.trim(),
      'refundable': _refundable,
      'deliveryFee': int.tryParse(_deliveryFeeController.text.trim()) ?? 0,
      'rating': double.tryParse(_ratingController.text.trim()) ?? 0.0, // NEW
    };
    try {
      final userId = context.read<AuthProvider>().userId ?? '';
      await provider.updateProductPartial(
        productId: widget.product.productId,
        userId: userId,
        updatedFields: updatedFields,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update product')));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductUploadProvider>(context, listen: false);
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
            const Text('Update product', style: TextStyle(fontSize: 16)),
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
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'out_of_stock',
                      child: Text('Out of Stock'),
                    ),
                    DropdownMenuItem(value: 'removed', child: Text('Removed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || int.tryParse(v) == null ? 'Invalid' : null,
                ),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextFormField(
                  controller: _colorsController,
                  decoration: const InputDecoration(
                    labelText: 'Colors (comma separated)',
                  ),
                ),
                TextFormField(
                  controller: _deliveryDaysController,
                  decoration: const InputDecoration(labelText: 'Delivery Days'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _deliveryFeeController,
                  decoration: const InputDecoration(labelText: 'Delivery Fee'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && int.tryParse(v) == null)
                      return 'Must be a whole number';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ratingController,
                  decoration: const InputDecoration(
                    labelText: 'Rating (0 - 5)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null) return 'Must be a number';
                    if (val < 0 || val > 5) return 'Must be between 0 and 5';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _shippedFromController,
                  decoration: const InputDecoration(labelText: 'Shipped From'),
                ),
                DropdownButtonFormField<String>(
                  value: _refundable,
                  items: const [
                    DropdownMenuItem(
                      value: 'refundable',
                      child: Text('Refundable'),
                    ),
                    DropdownMenuItem(
                      value: 'nonrefundable',
                      child: Text('Non-Refundable'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _refundable = v);
                  },
                  decoration: const InputDecoration(labelText: 'Refundable'),
                ),
                const SizedBox(height: 12),
                AppButtons(
                  text: _isUpdating ? 'Updating...' : 'Update Product',
                  onPressed: () => _updateProduct(provider),
                ),
                50.getHeightWhiteSpacing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
