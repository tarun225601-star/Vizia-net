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
    CakeDatabase.loadOrdersLocally().then((_) {
      if (mounted) setState(() {});
    });

    _autoFetchTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      var newOrder = await CakeDatabase.fetchSingleLatestOrderOnly();
      if (newOrder != null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _autoFetchTimer?.cancel(); 
    super.dispose();
  }

  double _calculateGrandTotal() {
    double total = 0.0;
    for (var item in CakeDatabase.cartItems) {
      double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      double qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1.0;
      total += (price * qty);
    }
    return total;
  }

  Future<void> _placeOrder() async {
    if (CakeDatabase.cartItems.isEmpty) return;
    setState(() => _isCheckingOut = true);
    
    double grandTotal = _calculateGrandTotal();

    var newOrder = {
      'orderId': 'ord_${DateTime.now().millisecondsSinceEpoch}',
      'customerName': CakeDatabase.currentCustomerName,
      'customerPhone': CakeDatabase.currentUserPhone,
      'customerAddress': CakeDatabase.currentDeliveryAddress.isEmpty ? 'पता उपलब्ध नहीं' : CakeDatabase.currentDeliveryAddress,
      'shopName': CakeDatabase.bakeryShop['shopName'] ?? 'Viziag Mart',
      'shopAddress': CakeDatabase.bakeryShop['shopAddress'] ?? CakeDatabase.bakeryShop['address'] ?? 'Faridabad',
      'items': CakeDatabase.cartItems,
      'grandTotal': grandTotal,
      'totalAmount': grandTotal,
      'status': 'Pending',
      'orderTime': DateTime.now().toIso8601String(),
    };

    try {
      final res = await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'), 
        body: json.encode(newOrder)
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          CakeDatabase.cartItems.clear();
          CakeDatabase.localOrdersCache.insert(0, newOrder);
        });
        await CakeDatabase.saveOrdersLocally();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 आर्डर सफलतापूर्वक प्लेस हो गया!'), backgroundColor: Colors.green));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = _calculateGrandTotal();

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
                // 1st Tab: Cart View
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
                                    title: Text(item['name'] ?? 'Item', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text('₹${item['price']} x ${item['qty']} ${item['unit'] ?? ''}'),
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
                
                // 2nd Tab: Order History View (Full implementation)
                CakeDatabase.localOrdersCache.isEmpty
                    ? const Center(child: Text('कोई पिछला आर्डर नहीं है', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: CakeDatabase.localOrdersCache.length,
                        itemBuilder: (context, index) {
                          var ord = CakeDatabase.localOrdersCache[index];
                          String status = ord['status'] ?? ord['orderStatus'] ?? 'Pending';
                          var orderTotal = ord['grandTotal'] ?? ord['totalAmount'] ?? 0;
                          var itemsList = ord['items'] as List<dynamic>? ?? [];

                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('आर्डर #${ord['orderId'] ?? ''}', 
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('₹${orderTotal.toString()}', 
                                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('दुकान: ${ord['shopName'] ?? 'Viziag Mart'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  Text('दुकान का पता: ${ord['shopAddress'] ?? 'Faridabad'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('डिलीवरी पता: ${ord['customerAddress'] ?? ord['deliveryAddress'] ?? 'पता उपलब्ध नहीं'}', 
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const Divider(color: Colors.white24, height: 16),
                                  ...itemsList.map((it) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('• ${it['name']} (x${it['qty']})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                        Text('₹${(double.tryParse(it['price'].toString()) ?? 0) * (double.tryParse(it['qty'].toString()) ?? 1)}', 
                                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status.toLowerCase() == 'delivered' ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('स्टेटस: $status', style: TextStyle(color: status.toLowerCase() == 'delivered' ? Colors.greenAccent : Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      Text(ord['orderTime'] != null ? ord['orderTime'].toString().substring(0, 16).replaceAll('T', ' ') : '', 
                                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
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
