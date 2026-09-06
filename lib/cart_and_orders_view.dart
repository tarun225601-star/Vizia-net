// ================= FILE 5 OF 10: cart_and_orders_view.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';

class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  void _updateQuantity(int index, double delta) {
    setState(() {
      double currentQty = (EnterpriseDatabase.activeCart[index]['qty'] as num).toDouble();
      double newQty = currentQty + delta;
      if (newQty > 0) {
        EnterpriseDatabase.activeCart[index]['qty'] = newQty;
      } else {
        EnterpriseDatabase.activeCart.removeAt(index);
      }
    });
  }

  void _checkoutOrder() {
    if (EnterpriseDatabase.activeCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ आपका कार्ट खाली है!'), backgroundColor: Colors.red),
      );
      return;
    }

    double totalAmount = EnterpriseDatabase.activeCart.fold(
      0.0,
      (sum, item) => sum + ((item['price'] as num) * (item['qty'] as num)),
    );

    var orderRecord = {
      'orderId': 'VIZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      'customerName': EnterpriseDatabase.currentCustomerName,
      'customerPhone': EnterpriseDatabase.currentUserPhone,
      'deliveryAddress': EnterpriseDatabase.currentDeliveryAddress,
      'items': List<Map<String, dynamic>>.from(EnterpriseDatabase.activeCart),
      'totalAmount': totalAmount,
      'timestamp': DateTime.now().toString(),
      'status': 'Placed',
    };

    setState(() {
      EnterpriseDatabase.orderLedger.insert(0, orderRecord);
      EnterpriseDatabase.activeCart.clear();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('ऑर्डर सफल रहा!', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16)),
          ],
        ),
        content: Text(
          'आपका ऑर्डर सफलतापूर्वक रजिस्टर हो गया है!\nकुल राशि: ₹${totalAmount.toStringAsFixed(2)}\nडिलिवरी पता: ${EnterpriseDatabase.currentDeliveryAddress}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context),
            child: const Text('ठीक है', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = EnterpriseDatabase.activeCart.fold(
      0.0,
      (sum, item) => sum + ((item['price'] as num) * (item['qty'] as num)),
    );

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFFF59E0B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFF59E0B),
            tabs: [
              Tab(text: 'शॉपिंग कार्ट (Cart)'),
              Tab(text: 'ऑर्डर हिस्ट्री (Orders)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Cart View
                EnterpriseDatabase.activeCart.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: EnterpriseDatabase.activeCart.length,
                            itemBuilder: (context, index) {
                              var item = EnterpriseDatabase.activeCart[index];
                              double itemTotal = (item['price'] as num) * (item['qty'] as num);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('₹${item['price']} / ${item['unit']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFF59E0B), size: 18),
                                          onPressed: () => _updateQuantity(index, -1),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text('${item['qty']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF59E0B), size: 18),
                                          onPressed: () => _updateQuantity(index, 1),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Text('₹${itemTotal.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text('कुल राशि (Grand Total):', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 42),
                            ),
                            onPressed: _checkoutOrder,
                            child: const Text('ऑर्डर प्लेस करें (Checkout Now)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),

                // Tab 2: Orders Ledger View
                EnterpriseDatabase.orderLedger.isEmpty
                    ? const Center(
                        child: Text('कोई पिछला ऑर्डर उपलब्ध नहीं है।', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: EnterpriseDatabase.orderLedger.length,
                        itemBuilder: (context, index) {
                          var order = EnterpriseDatabase.orderLedger[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(order['orderId'], style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                                    const Spacer(),
                                    Text('₹${(order['totalAmount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('समय: ${order['timestamp']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
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
