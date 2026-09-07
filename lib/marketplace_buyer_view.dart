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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🛒 ${prod['name']} कार्ट में जुड़ गया!'), backgroundColor: const Color(0xFF10B981)));
  }

  @override
  Widget build(BuildContext context) {
    var filtered = CakeDatabase.productInventory.where((p) => selectedCategory == 'All' || p['category'] == selectedCategory).toList();
    var shop = CakeDatabase.bakeryShop;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // शुद्ध मैट ब्लैक पेपर बैकग्राउंड
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // दुकान बैनर कार्ड (मैट ब्लैक पेपर स्टाइल)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if ((shop['bannerPhotoPath'] ?? '').toString().isNotEmpty)
                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: buildShopOrProdImage(shop['bannerPhotoPath'], 110, double.infinity, Icons.store)),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: buildShopOrProdImage(shop['shopPhotoPath'] ?? shop['ownerPhotoPath'], 45, 45, Icons.store)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop['shopName'] ?? 'Tarun Fruit & Vegetable Shop', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('📍 ${shop['address'] ?? 'Faridabad'}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.sync, color: Color(0xFF34D399)), onPressed: _fetchShopProfileAndProducts),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // कैटेगरी चॉइस चिप्स
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: selectedCategory == cat,
                  selectedColor: const Color(0xFF34D399),
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(color: selectedCategory == cat ? Colors.black : Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: selectedCategory == cat ? Colors.transparent : Colors.white12)),
                  onSelected: (_) => setState(() => selectedCategory = cat),
                ),
              )).toList(),
            ),
          ),
          if (_isLoadingCloud) const LinearProgressIndicator(color: Color(0xFF34D399)),
          const SizedBox(height: 14),
          // ब्लिंकईट जैसी परफेक्ट 2-कॉलम ग्रिड व्यू (मैट ब्लैक कार्ड्स)
          filtered.isEmpty
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('कोई प्रोडक्ट नहीं मिला', style: TextStyle(color: Colors.white38))))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    var prod = filtered[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E), // मैट ब्लैक पेपर शेड कार्ड
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: buildShopOrProdImage(prod['image'], double.infinity, double.infinity, Icons.eco),
                                  ),
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('⚡ 10 MINS', style: TextStyle(color: Color(0xFF34D399), fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prod['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text('1 ${prod['unit'] ?? 'Kg'}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${prod['price']}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF262626),
                                          foregroundColor: const Color(0xFF34D399),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            side: const BorderSide(color: Color(0xFF34D399), width: 0.8),
                                          ),
                                        ),
                                        onPressed: () => _addToCart(prod, 1.0),
                                        child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
