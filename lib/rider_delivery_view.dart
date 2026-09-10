import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart'; // सुनिश्चित करें कि आपकी डेटाबेस फाइल का नाम यही हो

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
          var order = Map<String, dynamic>.from(value);
          order['orderId'] = key;
          // यहाँ राइडर अपने लिए पेंडिंग या डिलेवरी वाले ऑर्डर्स देख सकता है
          loadedOrders.add(order);
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
        body: json.encode({'status': newStatus}),
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
                      String customerName = order['customerName'] ?? CakeDatabase.currentCustomerName;
                      String phone = order['phone'] ?? CakeDatabase.currentUserPhone;
                      String address = order['address'] ?? CakeDatabase.currentDeliveryAddress;
                      String status = order['status'] ?? 'Pending';
                      var items = order['items'] as List<dynamic>? ?? [];

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
                                    '📦 Order ID: ${orderId.substring(0, orderId.length > 6 ? 6 : orderId.length)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status == 'Delivered' ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'Delivered' ? Colors.green.shade800 : Colors.orange.shade800,
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
                                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 15),
                                  const Icon(Icons.phone, size: 15, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(phone, style: const TextStyle(fontSize: 13)),
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
                              const SizedBox(height: 10),
                              Text(
                                'कुल आइटम्स: ${items.length}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                    onPressed: () => _updateOrderStatus(orderId, 'Out for Delivery'),
                                    icon: const Icon(Icons.directions_bike, size: 14),
                                    label: const Text('Out for Delivery', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _updateOrderStatus(orderId, 'Delivered'),
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
