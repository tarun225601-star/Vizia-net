// ================= FILE 7 OF 10: wishlist_and_search.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';

class WishlistAndSearchManager {
  static final List<Map<String, dynamic>> userWishlist = [];

  static void toggleWishlist(Map<String, dynamic> product) {
    String name = product['name'] ?? '';
    int index = userWishlist.indexWhere((item) => item['name'] == name);
    if (index >= 0) {
      userWishlist.removeAt(index);
    } else {
      userWishlist.add(product);
    }
  }

  static bool isFavorite(Map<String, dynamic> product) {
    return userWishlist.any((item) => item['name'] == product['name']);
  }
}

class ProductSearchDelegateView extends StatefulWidget {
  const ProductSearchDelegateView({super.key});

  @override
  State<ProductSearchDelegateView> createState() => _ProductSearchDelegateViewState();
}

class _ProductSearchDelegateViewState extends State<ProductSearchDelegateView> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var results = EnterpriseDatabase.globalInventory.where((p) {
      String name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'उत्पाद खोजें (Search fruits, vegetables)...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: results.length,
        itemBuilder: (context, index) {
          var item = results[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.eco, color: Color(0xFFF59E0B)),
              title: Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              subtitle: Text('₹${item['price']} / ${item['unit'] ?? 'Kg'}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFFF59E0B), size: 18),
                onPressed: () {
                  EnterpriseDatabase.activeCart.add({
                    'name': item['name'],
                    'price': item['price'],
                    'unit': item['unit'] ?? 'Kg',
                    'qty': 1.0,
                    'shopName': EnterpriseDatabase.activeShopProfile['shopName'],
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🛒 कार्ट में जोड़ा गया!'), duration: Duration(milliseconds: 600)),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
