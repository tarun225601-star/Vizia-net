import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'image_picker_helper.dart';

class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String selectedCategory = 'All';
  bool _isLoadingCloud = false;

  final List<String> categories = ['All', 'Fresh Fruits', 'Vegetables', 'Organic Items', 'Daily Essentials'];

  @override
  void initState() {
    super.initState();
    _fetchShopProfileAndProducts();
  }

  Future<void> _fetchShopProfileAndProducts() async {
    setState(() => _isLoadingCloud = true);
    try {
      final shopRes = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'));
      if (shopRes.statusCode == 200 && shopRes.body != 'null' && shopRes.body.isNotEmpty) {
        var decodedShop = json.decode(shopRes.body);
        if (decodedShop is Map) {
          setState(() {
            CakeDatabase.bakeryShop = Map<String, dynamic>.from(
              decodedShop.map((key, value) => MapEntry(key.toString(), value))
            );
          });
        }
      }

      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        var decodedProducts = json.decode(response.body);
        List<Map<String, dynamic>> fetchedList = [];
        if (decodedProducts is Map) {
          decodedProducts.forEach((key, value) {
            if (value is Map) {
              var item = Map<String, dynamic>.from(
                value.map((k, v) => MapEntry(k.toString(), v))
              );
              item['firebaseKey'] = key.toString();
              if (item['price'] != null) item['price'] = (item['price'] as num).toDouble();
              fetchedList.add(item);
            }
          });
        }
        setState(() => CakeDatabase.productInventory = fetchedList.reversed.toList());
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCloud = false);
    }
  }

  void _addToCart(Map<String, dynamic> prod, double qty) {
    if (CakeDatabase.bakeryShop['isOpen'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ दुकान अभी बंद है!'), backgroundColor: Colors.red));
      return;
    }
    setState(() {
      CakeDatabase.cartItems.add({
        'name': prod['name'],
        'price': prod['price'],
        'unit': prod['unit'] ?? 'Kg',
        'qty': qty,
        'image': prod['image'] ?? '',
        'shopName': CakeDatabase.bakeryShop['shopName'],
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🛒 ${prod['name']} कार्ट में जुड़ गया!'), backgroundColor: const Color(0xFFF59E0B)));
  }

  @override
  Widget build(BuildContext context) {
    var filtered = CakeDatabase.productInventory.where((p) => selectedCategory == 'All' || p['category'] == selectedCategory).toList();
    var shop = CakeDatabase.bakeryShop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                if ((shop['bannerPhotoPath'] ?? '').toString().isNotEmpty)
                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: buildShopOrProdImage(shop['bannerPhotoPath'], 120, double.infinity, Icons.store)),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      buildShopOrProdImage(shop['shopPhotoPath'] ?? shop['ownerPhotoPath'], 50, 50, Icons.store),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop['shopName'] ?? 'Tarun Fruit & Vegetable Shop', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B), fontSize: 14)),
                            Text('📍 ${shop['address'] ?? 'Faridabad'}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.sync, color: Color(0xFFF59E0B)), onPressed: _fetchShopProfileAndProducts),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 10)),
                  selected: selectedCategory == cat,
                  selectedColor: const Color(0xFFF59E0B),
                  onSelected: (_) => setState(() => selectedCategory = cat),
                ),
              )).toList(),
            ),
          ),
          if (_isLoadingCloud) const LinearProgressIndicator(color: Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              var prod = filtered[index];
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: buildShopOrProdImage(prod['image'], 45, 45, Icons.shopping_bag),
                  ),
                  title: Text(prod['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${prod['price']} / ${prod['unit'] ?? 'Kg'}', style: const TextStyle(color: Color(0xFFF59E0B))),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
                    onPressed: () => _addToCart(prod, 1.0),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
