import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
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
  StreamSubscription<DatabaseEvent>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    CakeDatabase.loadOrdersLocally().then((_) {
      if (mounted) setState(() {});
    });
    _startCustomerOrdersListener();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _startCustomerOrdersListener() {
    DatabaseReference ordersRef = FirebaseDatabase.instance.ref('orders');

    _ordersSubscription = ordersRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.value == null) return;

      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> loadedOrders = [];

      data.forEach((key, val) {
        if (val is Map) {
          var ord = Map<String, dynamic>.from(val);
          ord['orderId'] = key;

          String custPhone = ord['customerPhone'] ?? '';
          if (custPhone == CakeDatabase.currentUserPhone && CakeDatabase.currentUserPhone.isNotEmpty) {
            loadedOrders.add(ord);
          }
        }
      });

      loadedOrders = loadedOrders.reversed.toList();

      if (mounted) {
        setState(() {
          CakeDatabase.localOrdersCache = loadedOrders;
        });
        CakeDatabase.saveOrdersLocally();
      }
    }, onError: (error) {
      debugPrint("Customer Realtime database error: $error");
    });
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
      'customerName': CakeDatabase.currentCustomerName,
      'customerPhone': CakeDatabase.currentUserPhone,
      'customerAddress': CakeDatabase.currentDeliveryAddress.isEmpty ? 'पता उपलब्ध नहीं' : CakeDatabase.currentDeliveryAddress,
      'shopName': CakeDatabase.bakeryShop['shopName'] ?? 'Viziag Mart',
      'shopAddress': CakeDatabase.bakeryShop['shopAddress'] ?? CakeDatabase.bakeryShop['address'] ?? 'Faridabad',
      'items': CakeDatabase.cartItems,
      'grandTotal': grandTotal,
      'totalAmount': grandTotal,
      'status': 'Pending',
      'orderStatus': 'Pending ⏳',
      'orderTime': DateTime.now().toIso8601String(),
    };

    try {
      DatabaseReference newOrderRef = FirebaseDatabase.instance.ref('orders').push();
      await newOrderRef.set(newOrder);

      if (mounted) {
        setState(() {
          CakeDatabase.cartItems.clear();
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 आर्डर सफलतापूर्वक प्लेस हो गया!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Place order error: $e");
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
                    tabs: [Tab(text: '🛒 मेरा कार्ट'), Tab(text: '📦 आर्डर इतिहास (Live)')],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Color(0xFFF59E0B)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚡ आर्डर आटोमेटिक लाइव सिंक हो रहे हैं!'), duration: Duration(seconds: 2)),
                    );
                  },
                  tooltip: 'Live Synced',
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
                
                // 2nd Tab: Order History View (Real-time Live)
                CakeDatabase.localOrdersCache.isEmpty
                    ? const Center(child: Text('कोई पिछला आर्डर नहीं है', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: CakeDatabase.localOrdersCache.length,
                        itemBuilder: (context, index) {
                          var ord = CakeDatabase.localOrdersCache[index];
                          String status = ord['orderStatus'] ?? ord['status'] ?? 'Pending';
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
                                      Text('आर्डर #${ord['orderId'] != null && ord['orderId'].toString().length > 8 ? ord['orderId'].toString().substring(0, 8) : ord['orderId'] ?? ''}', 
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
                                  ...itemsList.map((it) {
                                    var m = it is Map ? it : {};
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('• ${m['name'] ?? 'Item'} (x${m['qty'] ?? 1})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                          Text('₹${(double.tryParse(m['price'].toString()) ?? 0) * (double.tryParse(m['qty'].toString()) ?? 1)}', 
                                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status.toLowerCase().contains('delivered') ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('स्टेटस: $status', style: TextStyle(color: status.toLowerCase().contains('delivered') ? Colors.greenAccent : Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      Text(ord['orderTime'] != null && ord['orderTime'].toString().length >= 16 ? ord['orderTime'].toString().substring(0, 16).replaceAll('T', ' ') : '', 
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
