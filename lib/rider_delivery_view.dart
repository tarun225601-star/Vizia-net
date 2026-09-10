import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key});

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignedOrders();
  }

  // लाइव ऑर्डर्स को फायरबेस से फेच करने का मेथड
  Future<void> _fetchAssignedOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/customer_orders.json'),
      );

      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> loadedOrders = [];

        data.forEach((key, value) {
          if (value is Map) {
            var order = Map<String, dynamic>.from(value);
            order['orderId'] = key;
            loadedOrders.add(order);
          }
        });

        if (mounted) {
          setState(() {
            _activeOrders = loadedOrders.reversed.toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Rider fetch orders error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // आर्डर स्टेटस अपडेट करने के लिए
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/customer_orders/$orderId.json'),
        body: json.encode({
          'orderStatus': newStatus,
          'status': newStatus, // दोनों की अपडेट कर देंगे ताकि कहीं मिस न हो
        }),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ आर्डर स्टेटस बदलकर "$newStatus" कर दिया गया है!'), backgroundColor: Colors.green),
        );
      }
      _fetchAssignedOrders();
    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '🚴‍♂️ राइडर डिलीवरी डैशबोर्ड',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.green.shade700),
            onPressed: _fetchAssignedOrders,
            tooltip: 'ऑर्डर रिफ्रेश करें',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _activeOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'कोई नया डिलीवरी ऑर्डर उपलब्ध नहीं है!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAssignedOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _activeOrders.length,
                    itemBuilder: (context, index) {
                      var order = _activeOrders[index];
                      String orderId = order['orderId'] ?? '';
                      
                      // 🔍 सभी संभावित कीज़ (Keys) को चेक करने का फॉलबैक लॉजिक ताकि null न आए
                      String customerName = order['customerName'] ?? order['name'] ?? CakeDatabase.currentCustomerName;
                      String phone = order['customerPhone'] ?? order['phone'] ?? CakeDatabase.currentUserPhone;
                      String address = order['deliveryAddress'] ?? order['customerAddress'] ?? order['address'] ?? CakeDatabase.currentDeliveryAddress;
                      String status = order['orderStatus'] ?? order['status'] ?? 'Pending ⏳';
                      
                      var items = order['items'] as List<dynamic>? ?? [];
                      double totalAmount = (order['totalAmount'] ?? order['grandTotal'] ?? 0.0).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '📦 Order ID: ${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status.contains('Delivered') ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: status.contains('Delivered') ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 15, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  const Icon(Icons.phone, size: 15, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 15, color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              // 🛒 आर्डर किए गए आइटम्स की लिस्ट और उनकी कीमत दिखाने के लिए
                              const Text('खरीदे गए आइटम्स:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              ...items.map((item) {
                                var mapItem = item is Map ? item : {};
                                String itemName = mapItem['name'] ?? 'Item';
                                double itemPrice = (mapItem['price'] ?? 0.0).toDouble();
                                double itemQty = (mapItem['qty'] ?? 1.0).toDouble();
                                String itemUnit = mapItem['unit'] ?? 'Kg';
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text('• $itemName ($itemQty $itemUnit)', style: const TextStyle(fontSize: 12, color: Colors.black87))),
                                      Text('₹${(itemPrice * itemQty).toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('कुल राशि: ₹${totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                  Text('कुल आइटम्स: ${items.length}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                    onPressed: () => _updateOrderStatus(orderId, 'Out for Delivery 🚴‍♂️'),
                                    icon: const Icon(Icons.directions_bike, size: 14),
                                    label: const Text('Out for Delivery', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _updateOrderStatus(orderId, 'Delivered 🎉'),
                                    icon: const Icon(Icons.check_circle, size: 14),
                                    label: const Text('Delivered', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
