    // ================= FILE: product_details_screen.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  double _quantity = 1.0;

  void _addToCart() {
    var cartItem = {
      'name': widget.product['name'],
      'price': widget.product['price'],
      'unit': widget.product['unit'] ?? 'Kg',
      'qty': _quantity,
    };

    EnterpriseDatabase.activeCart.add(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ उत्पाद कार्ट में जोड़ दिया गया!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool inStock = widget.product['inStock'] ?? true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Text(widget.product['name'] ?? 'उत्पाद विवरण', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: const Icon(Icons.eco, size: 70, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 16),
            Text(widget.product['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('₹${widget.product['price']} / ${widget.product['unit'] ?? 'Kg'}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(inStock ? '🟢 In Stock (स्टॉक में उपलब्ध)' : '🔴 Out of Stock (स्टॉक समाप्त)', style: TextStyle(color: inStock ? Colors.green : Colors.red, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('मात्रा (Quantity):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFF59E0B)),
                  onPressed: () {
                    if (_quantity > 1) setState(() => _quantity -= 1);
                  },
                ),
                Text('$_quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF59E0B)),
                  onPressed: () => setState(() => _quantity += 1),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: inStock ? _addToCart : null,
              child: const Text('कार्ट में जोड़ें (Add to Cart)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
