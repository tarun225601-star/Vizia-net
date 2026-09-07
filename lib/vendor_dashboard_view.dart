// ================= FILE: vendor_dashboard_view.dart =================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'vendor_auth_view.dart';

class VendorDashboardView extends StatefulWidget {
  const VendorDashboardView({Key? key}) : super(key: key);

  @override
  _VendorDashboardViewState createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView> {
  bool isLoading = false;
  List<Map<String, dynamic>> liveOrders = [];
  int previousOrderCount = 0;

  @override
  void initState() {
    super.initState();
    fetchLiveOrders();
  }

  Future<void> fetchLiveOrders() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/orders.json');
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != 'null') {
        final Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> loadedOrders = [];

        data.forEach((key, value) {
          if (value is Map) {
            // केवल उसी वेंडर के ऑर्डर्स दिखाएँ जो लॉगइन है (डेटा आइसोलेशन)
            if (value['vendorId'] == EnterpriseDatabase.currentVendorId) {
              loadedOrders.add({
                'orderId': key,
                'customerName': value['customerName'] ?? 'ग्राहक',
                'customerPhone': value['customerPhone'] ?? '',
                'deliveryAddress': value['deliveryAddress'] ?? '',
                'items': value['items'] ?? [],
                'totalAmount': value['totalAmount'] ?? calculateTotal(value['items']),
                'status': value['status'] ?? 'Pending',
              });
            }
          }
        });

        // नया आर्डर आने पर फोन में बिल्ट-इन वाइब्रेशन ट्रिगर होगा
        if (loadedOrders.length > previousOrderCount && previousOrderCount != 0) {
          HapticFeedback.heavyImpact();
        }

        setState(() {
          liveOrders = loadedOrders;
          previousOrderCount = loadedOrders.length;
        });
      }
    } catch (e) {
      print("Error fetching orders: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  double calculateTotal(dynamic items) {
    double total = 0.0;
    if (items is List) {
      for (var item in items) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final qty = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
        total += price * qty;
      }
    }
    return total;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final url = Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/orders/$orderId/status.json');
      await http.put(url, body: json.encode(newStatus));
      fetchLiveOrders();
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  void logout() {
    EnterpriseDatabase.currentVendorId = null;
    EnterpriseDatabase.currentShopName = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VendorAuthView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222B),
        title: Text('${EnterpriseDatabase.currentShopName ?? "वेंडर"} - डैशबोर्ड', style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: fetchLiveOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : liveOrders.isEmpty
              ? const Center(
                  child: Text('आपकी दुकान के लिए कोई नया ऑर्डर नहीं है', style: TextStyle(color: Colors.white54, fontSize: 16)),
                )
              : ListView.builder(
                  itemCount: liveOrders.length,
                  itemBuilder: (context, index) {
                    final order = liveOrders[index];
                    return Card(
                      color: const Color(0xFF1E222B),
                      margin: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("ऑर्डर आईडी: ${order['orderId']}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text(order['status'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  backgroundColor: order['status'] == 'Accepted' ? Colors.green : Colors.orange,
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            Text("ग्राहक: ${order['customerName']} (${order['customerPhone']})", style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text("पता: ${order['deliveryAddress']}", style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            const Text("आइटम्स और तस्वीरें:", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                            
                            // आइटम्स की लिस्ट और उनकी तस्वीरें दिखाने का सुरक्षित तरीका
                            ...((order['items'] as List?)?.map((item) {
                                  final String? imgBase64 = item['image'] ?? item['itemPhoto'];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: imgBase64 != null && imgBase64.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.memory(
                                                    base64Decode(imgBase64),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                                  ),
                                                )
                                              : const Icon(Icons.image, color: Colors.grey, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "${item['name']} (${item['quantity']}x) - ₹${item['price']}",
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList() ?? []),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("कुल राशि: ₹${order['totalAmount']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                const Row(
                                  children: [
                                    Icon(Icons.timer, color: Colors.orange, size: 16),
                                    SizedBox(width: 4),
                                    Text("10:00 min", style: TextStyle(color: Colors.orange, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => updateOrderStatus(order['orderId'], 'Accepted'),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text("Accept", style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => updateOrderStatus(order['orderId'], 'Rejected'),
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  label: const Text("Reject", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
