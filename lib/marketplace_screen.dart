// ================= FILE 3 OF 10: marketplace_screen.dart =================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String selectedCategory = 'All';
  bool _isSyncing = false;

  final List<String> categories = [
    'All',
    'Fresh Fruits',
    'Vegetables',
    'Organic Items',
    'Daily Essentials',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCloudData();
  }

  Future<void> _fetchCloudData() async {
    setState(() => _isSyncing = true);
    try {
      final response = await http.get(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        var decoded = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is Map) {
              var item = Map<String, dynamic>.from(value);
              item['firebaseKey'] = key;
              if (item['price'] != null) item['price'] = (item['price'] as num).toDouble();
              list.add(item);
            }
          });
        }
        setState(() => EnterpriseDatabase.globalInventory = list.reversed.toList());
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _addItemToCart(Map<String, dynamic> product) {
    String name = product['name'] ?? 'Item';
    int index = EnterpriseDatabase.activeCart.indexWhere((element) => element['name'] == name);

    setState(() {
      if (index >= 0) {
        EnterpriseDatabase.activeCart[index]['qty'] = (EnterpriseDatabase.activeCart[index]['qty'] as num) + 1;
      } else {
        EnterpriseDatabase.activeCart.add({
          'name': name,
          'price': product['price'] ?? 0.0,
          'unit': product['unit'] ?? 'Kg',
          'qty': 1.0,
          'shopName': EnterpriseDatabase.activeShopProfile['shopName'],
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛒 $name कार्ट में जोड़ा गया!'), duration: const Duration(milliseconds: 700), backgroundColor: const Color(0xFFF59E0B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = EnterpriseDatabase.globalInventory.where((p) {
      if (selectedCategory == 'All') return true;
      return p['category'] == selectedCategory;
    }).toList();

    var shop = EnterpriseDatabase.activeShopProfile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop['shopName'], style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('📍 ${shop['address']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sync, color: Color(0xFFF59E0B)),
                  onPressed: _fetchCloudData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                bool isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : Colors.white70)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF59E0B),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) => setState(() => selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (_isSyncing) const LinearProgressIndicator(color: Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65,
            ),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              var product = filteredList[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(product['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('₹${product['price']} / ${product['unit'] ?? 'Kg'}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 24,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => _addItemToCart(product),
                        child: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
