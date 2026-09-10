import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'image_picker_helper.dart';

class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  bool _isCheckingOut = false;
  Timer? _autoFetchTimer;

  @override
  void initState() {
    super.initState();
    // 🚀 ऐप खुलते ही परमानेंट लोकल मेमोरी से पुराने ऑर्डर्स लोड कर लो (इंटरनेट खर्च 0 KB)
    CakeDatabase.loadOrdersLocally().then((_) {
      if (mounted) setState(() {});
    });

    // 🟢 अब टाइमर हर 5 सेकंड में पूरा डेटा नहीं, बल्कि सिर्फ नया सिंगल ऑर्डर चेक करेगा (डेटा बचाने के लिए)
    _autoFetchTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      var newOrder = await CakeDatabase.fetchSingleLatestOrderOnly();
      if (newOrder != null && mounted) {
        setState(() {}); // जैसे ही नया आर्डर आएगा, स्क्रीन अपने आप अपडेट हो जाएगी
      }
    });
  }

  @override
  void dispose() {
    _autoFetchTimer?.cancel(); 
    super.dispose();
  }

  // 🛒 आर्डर प्लेस करने का फंक्शन (Firebase पर भेजना)
  Future<void> _placeOrder() async {
    if (CakeDatabase.cartItems.isEmpty) return;
    setState(() => _isCheckingOut = true);
    double grandTotal = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] ?? 0.0) * (item['qty'] ?? 1.0)));

    var newOrder = {
      'orderId': 'ord_${DateTime.now().millisecondsSinceEpoch}',
      'customerName': CakeDatabase.currentCustomerName,
      'customerPhone': CakeDatabase.currentUserPhone,
      'deliveryAddress': CakeDatabase.currentDeliveryAddress,
      'pickupAddress': CakeDatabase.bakeryShop['address'] ?? 'Faridabad',
      'shopName': CakeDatabase.bakeryShop['shopName'] ?? 'Viziag Mart',
      'items': CakeDatabase.cartItems,
      'totalAmount': grandTotal,
      'orderStatus': 'Pending ⏳',
      'orderTime': DateTime.now().toIso8601String(),
    };

    try {
      final res = await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/customer_orders.json'), 
        body: json.encode(newOrder)
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          CakeDatabase.cartItems.clear();
          CakeDatabase.localOrdersCache.insert(0, newOrder);
        });
        await CakeDatabase.saveOrdersLocally(); // तुरंत लोकल सेव करें
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 आर्डर सफलतापूर्वक प्लेस हो गया!'), backgroundColor: Colors.green));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] ?? 0.0) * (item['qty'] ?? 1.0)));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Expanded(
                  child: TabBar(
                    labelColor: Color(0xFFF59E0B),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFFF59E0B),
                    tabs: [Tab(text: '🛒 मेरा कार्ट'), Tab(text: '📦 आर्डर इतिहास')],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sync, color: Color(0xFFF59E0B)),
                  onPressed: () async {
                    await CakeDatabase.fetchSingleLatestOrderOnly();
                    setState(() {});
                  },
                  tooltip: 'आर्डर रिफ्रेश करें',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // कार्ट टैब
                CakeDatabase.cartItems.isEmpty
                    ? const Center(child: Text('आपका कार्ट खाली है', style: TextStyle(color: Colors.grey)))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: CakeDatabase.cartItems.length,
                              itemBuilder: (context, index) {
                                var item = CakeDatabase.cartItems[index];
                                return Card(
                                  color: const Color(0xFF1E293B),
                                  margin: const EdgeInsets.all(8),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: buildShopOrProdImage(item['image'], 45, 45, Icons.fastfood),
                                    ),
                                    title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text('₹${item['price']} x ${item['qty']} ${item['unit']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => setState(() => CakeDatabase.cartItems.removeAt(index)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0xFF1E293B),
                            child: Row(
                              children: [
                                Text('कुल: ₹${grandTotal.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const Spacer(),
                                _isCheckingOut
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
                                        onPressed: _placeOrder,
                                        child: const Text('आर्डर दें', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                
                // आर्डर इतिहास टैब (लोकल मेमोरी से चलेगा, नेट खर्च नहीं होगा)
                CakeDatabase.localOrdersCache.isEmpty
                    ? const Center(child: Text('कोई पिछला आर्डर नहीं है', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: CakeDatabase.localOrdersCache.length,
                        itemBuilder: (context, index) {
                          var ord = CakeDatabase.localOrdersCache[index];
                          String status = ord['orderStatus'] ?? ord['status'] ?? 'Pending';

                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('आर्डर #${ord['orderId']} - ₹${(ord['grandTotal'] ?? ord['totalAmount'])?.toInt()}', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 5),
                                  Text('स्टेटस: $status', style: const TextStyle(color: Colors.amberAccent)),
                                  Text('पता: ${ord['customerAddress'] ?? ord['deliveryAddress'] ?? 'पता उपलब्ध नहीं'}', 
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
