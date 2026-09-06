// ================= FILE 6 OF 10: product_details_screen.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required.data, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  double _selectedQty = 1.0;
  final TextEditingController _customNoteController = TextEditingController();

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  void _addCurrentProductToCart() {
    String name = widget.product['name'] ?? 'Item';
    int index = EnterpriseDatabase.activeCart.indexWhere((item) => item['name'] == name);

    setState(() {
      if (index >= 0) {
        EnterpriseDatabase.activeCart[index]['qty'] = _selectedQty;
        EnterpriseDatabase.activeCart[index]['customNote'] = _customNoteController.text.trim();
      } else {
        EnterpriseDatabase.activeCart.add({
          'name': name,
          'price': widget.product['price'] ?? 0.0,
          'unit': widget.product['unit'] ?? 'Kg',
          'qty': _selectedQty,
          'customNote': _customNoteController.text.trim(),
          'shopName': EnterpriseDatabase.activeShopProfile['shopName'],
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 $_selectedQty ${widget.product['unit'] ?? 'Kg'} $name कार्ट में जोड़ा गया!'),
        backgroundColor: const Color(0xFFF59E0B),
        duration: const Duration(milliseconds: 900),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var p = widget.product;
    bool inStock = p['inStock'] ?? true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Text(p['name'] ?? 'Product Details', style: const TextStyle(fontSize: 14, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: const Icon(Icons.shopping_bag, size: 64, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  p['name'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: inStock ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: inStock ? Colors.green : Colors.red),
                ),
                child: Text(
                  inStock ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inStock ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${p['price']} / ${p['unit'] ?? 'Kg'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          const Text('मात्रा चुनें (Select Quantity):', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [0.5, 1.0, 2.0, 5.0].map((val) {
              bool isSelected = _selectedQty == val;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
                      foregroundColor: isSelected ? Colors.black : Colors.white,
                      elevation: isSelected ? 4 : 0,
                    ),
                    onPressed: () => setState(() => _selectedQty = val),
                    child: Text('$val ${p['unit'] ?? 'Kg'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customNoteController,
            decoration: const InputDecoration(
              labelText: 'विशेष निर्देश (Special Note for Vendor)',
              hintText: 'जैसे: ताजे और अच्छे फल देना...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ).asButton(
              onPressed: inStock ? _addCurrentProductToCart : null,
              child: const Text('कार्ट में जोड़ें (Add to Cart)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

extension on ButtonStyle {
  Widget asButton({required VoidCallback? onPressed, required Widget child}) {
    return ElevatedButton(style: this, onPressed: onPressed, child: child);
  }
}
