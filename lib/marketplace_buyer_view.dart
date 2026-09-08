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
  
  // 🔍 सर्च और हाइपरलोकल फिल्टर के लिए कंट्रोलर और वेरिएबल
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _targetCity = 'Faridabad'; // केवल फरीदाबाद के लिए रेस्ट्रिक्शन

  final List<String> categories = ['All', 'Fresh Fruits', 'Vegetables', 'Organic Items', 'Daily Essentials'];

  @override
  void initState() {
    super.initState();
    _loadInstantDataAndFetch();
  }

  // ⚡ 0 सेकंड में लोड करने के लिए लोकल डेटा पहले दिखाओ, फिर क्लाउड से सिंक करो
  Future<void> _loadInstantDataAndFetch() async {
    // 1. पहले लोकल मेमोरी से तुरंत प्रोडक्ट्स लोड करके स्क्रीन दिखाओ (0 Sec Load)
    await CakeDatabase.loadInventoryLocally();
    if (mounted) setState(() {});

    // 2. इसके बाद बैकग्राउंड में क्लाउड/फायरबेस से ताज़ा डेटा खींचकर अपडेट करो
    _fetchShopProfileAndProducts();
  }

  Future<void> _fetchShopProfileAndProducts() async {
    if (CakeDatabase.productInventory.isEmpty) {
      setState(() => _isLoadingCloud = true);
    }
    
    try {
      final shopRes = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'));
      if (shopRes.statusCode == 200 && shopRes.body != 'null' && shopRes.body.isNotEmpty) {
        var decodedShop = json.decode(shopRes.body);
        if (decodedShop is Map) {
          if (mounted) {
            setState(() {
              CakeDatabase.bakeryShop = Map<String, dynamic>.from(
                decodedShop.map((key, value) => MapEntry(key.toString(), value))
              );
            });
          }
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
        
        CakeDatabase.productInventory = fetchedList.reversed.toList();
        
        // 🚀 नया डेटा आते ही उसे लोकल स्टोरेज में भी सेव कर लो ताकि अगली बार और तेज़ खुले
        await CakeDatabase.saveInventoryLocally();

        if (mounted) setState(() {});
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🛒 ${prod['name']} कार्ट में जुड़ गया!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    var shop = CakeDatabase.bakeryShop;
    
    // 📍 हाइपरलोकल चेक: अगर दुकान फरीदाबाद के बाहर की है तो प्रोडक्ट्स नहीं दिखेंगे
    String shopAddress = (shop['address'] ?? 'Faridabad').toString();
    bool isLocalFaridabadShop = shopAddress.toLowerCase().contains(_targetCity.toLowerCase());

    // 🔍 कैटेगरी, सर्च और फरीदाबाद लोकेशन के हिसाब से फ़िल्टरिंग
    var filtered = CakeDatabase.productInventory.where((p) {
      if (!isLocalFaridabadShop) return false; 

      bool matchesCategory = (selectedCategory == 'All' || p['category'] == selectedCategory);
      
      String productName = (p['name'] ?? '').toString().toLowerCase();
      bool matchesSearch = productName.contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // 🔍 शानदार सर्च बार (Search Bar)
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'फल, सब्ज़ी या आइटम खोजें (फरीदाबाद 5km)...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // दुकान बैनर कार्ड
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if ((shop['bannerPhotoPath'] ?? '').toString().isNotEmpty)
                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: buildShopOrProdImage(shop['bannerPhotoPath'], 110, double.infinity, Icons.store)),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: buildShopOrProdImage(shop['shopPhotoPath'] ?? shop['ownerPhotoPath'], 45, 45, Icons.store)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop['shopName'] ?? 'Tarun Fruit & Vegetable Shop', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('📍 ${shop['address'] ?? 'Faridabad (5km Range)'}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.sync, color: Colors.green), onPressed: _fetchShopProfileAndProducts),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // कैटेगरी चॉइस चिप्स
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: selectedCategory == cat,
                  selectedColor: Colors.green.shade700,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: selectedCategory == cat ? Colors.white : Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: selectedCategory == cat ? Colors.transparent : Colors.grey.shade300),
                  ),
                  onSelected: (_) => setState(() => selectedCategory = cat),
                ),
              )).toList(),
            ),
          ),
          if (_isLoadingCloud) const LinearProgressIndicator(color: Colors.green),
          const SizedBox(height: 10),

          // प्रोडक्ट्स ग्रिड व्यू
          filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      !isLocalFaridabadShop 
                          ? '⚠️ यह दुकान फरीदाबाद के बाहर की है, इसलिए यहाँ नहीं दिखेगी।' 
                          : 'कोई प्रोडक्ट नहीं मिला',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    var prod = filtered[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.12),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                                      decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('⚡ 9 MINS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prod['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text('1 ${prod['unit'] ?? 'Kg'}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${prod['price']}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                                    SizedBox(
                                      height: 28,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green.shade700,
                                          side: BorderSide(color: Colors.green.shade700, width: 1.2),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
