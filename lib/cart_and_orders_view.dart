import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'image_picker_helper.dart';
import 'rider_delivery_view.dart'; // RiderDispatchManager के लिए

class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  bool _isCheckingOut = false;
  List<Map<String, dynamic>> _customerOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomerOrders();
  }

  Future<void> _fetchCustomerOrders() async {
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          if (item['customerPhone'] == CakeDatabase.currentUserPhone) {
            item['firebaseKey'] = key;
            list.add(item);
          }
        });
        if (mounted) setState(() => _customerOrders = list.reversed.toList());
      }
    } catch (_) {}
  }

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
      final res = await http.post(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'), body: json.encode(newOrder));
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => CakeDatabase.cartItems.clear());
        _fetchCustomerOrders();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 आर्डर सफलतापूर्वक प्लेस हो गया!'), backgroundColor: Colors.green));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  // 🚀 वेंडर द्वारा राइडर असाइन और डिस्पैच करने का फंक्शन
  Future<void> _assignRiderToOrder(String orderKey, Map<String, dynamic> orderData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    String response = await DeliveryDispatcherManager.dispatchOrderToAvailableRider(orderKey, orderData);

    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (response.startsWith("SUCCESS")) {
        String riderPhone = response.split(":")[1];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 राइडर बुक हो गया! (फोन: $riderPhone)"), backgroundColor: Colors.green),
        );
        _fetchCustomerOrders();
      } else if (response == "NO_RIDER_AVAILABLE") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ कोई राइडर फ्री नहीं है! पहले 'राइडर रजिस्ट्रेशन' से राइडर जोड़ें।"), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ एरर: $response"), backgroundColor: Colors.red),
        );
      }
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
                  onPressed: _fetchCustomerOrders,
                  tooltip: 'आर्डर रिफ्रेश करें',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
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
                _customerOrders.isEmpty
                    ? const Center(child: Text('कोई पिछला आर्डर नहीं है', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _customerOrders.length,
                        itemBuilder: (context, index) {
                          var ord = _customerOrders[index];
                          String firebaseKey = ord['firebaseKey'] ?? '';
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
                                  const SizedBox(height: 10),
                                  
                                  // 🚀 यहाँ हर आर्डर के नीचे 'राइडर बुक करें' का बटन जोड़ दिया गया है
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.delivery_dining, size: 18),
                                      label: const Text('राइडर बुक करें & डिस्पैच करें'),
                                      onPressed: () {
                                        _assignRiderToOrder(firebaseKey, ord);
                                      },
                                    ),
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
