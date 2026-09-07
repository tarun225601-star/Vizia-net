// ============================================================================
// FILE: vendor_dashboard_view.dart (Multi-Vendor Marketplace - Bulletproof)
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_models.dart';

class VendorDashboardView extends StatefulWidget {
  const VendorDashboardView({super.key});

  @override
  State<VendorDashboardView> createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView> {
  int _currentIndex = 0;
  bool _isShopOpen = true;

  void _showProfessionalProductDialog({Map<String, dynamic>? existingProduct, int? editIndex}) {
    final nameController = TextEditingController(text: existingProduct?['name'] ?? '');
    final priceController = TextEditingController(text: existingProduct?['price']?.toString() ?? '');
    final stockController = TextEditingController(text: existingProduct?['stock']?.toString() ?? '');
    final descController = TextEditingController(text: existingProduct?['description'] ?? '');
    
    String category = existingProduct?['category'] ?? 'Automotive Care';
    String? localImagePath = existingProduct?['image'];
    bool isInStock = existingProduct?['isInStock'] ?? true;

    final List<String> categories = [
      'Automotive Care',
      'Dash & Polish',
      'Shampoos & Waxes',
      'Microfiber & Tools',
      'General Accessories'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editIndex == null ? 'नया उत्पाद जोड़ें' : 'उत्पाद अपडेट करें',
                        style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 10),

                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _getInputDecoration('उत्पाद का नाम', Icons.shopping_bag),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _getInputDecoration('कीमत (₹)', Icons.currency_rupee),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _getInputDecoration('स्टॉक मात्रा', Icons.inventory),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: categories.contains(category) ? category : categories.first,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: _getInputDecoration('उत्पाद श्रेणी', Icons.category),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text('उपलब्ध है (In-Stock)', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(isInStock ? 'ग्राहक इसे खरीद सकते हैं' : 'यह आउट ऑफ स्टॉक है', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    value: isInStock,
                    activeColor: Colors.green,
                    onChanged: (val) => setDialogState(() => isInStock = val),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('कृपया नाम और कीमत भरें!')),
                        );
                        return;
                      }

                      final productData = {
                        'id': existingProduct?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text.trim(),
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'stock': int.tryParse(stockController.text) ?? 10,
                        'category': category,
                        'description': descController.text.trim(),
                        'image': localImagePath ?? '',
                        'isInStock': isInStock,
                      };

                      setState(() {
                        if (editIndex != null) {
                          EnterpriseDatabase.globalInventory[editIndex] = productData;
                        } else {
                          EnterpriseDatabase.globalInventory.add(productData);
                        }
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('उत्पाद सुरक्षित कर दिया गया है!'), backgroundColor: Colors.green),
                      );
                    },
                    child: Text(
                      editIndex == null ? 'डेटाबेस में जोड़ें' : 'अपडेट करें',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.amber, size: 20),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: const Color(0xFF252525),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildAnalyticsDashboardTab(),
      _buildInventoryCatalogTab(),
      _buildOrderLedgerTab(),
      _buildStoreSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 16,
              child: Icon(Icons.store, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EnterpriseDatabase.activeShopProfile['shopName'] ?? 'मेरी दुकान',
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _isShopOpen ? '● दुकान खुली है (Live)' : '● दुकान बंद है (Closed)',
                    style: TextStyle(color: _isShopOpen ? Colors.green : Colors.red, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Switch(
            value: _isShopOpen,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            onChanged: (val) {
              setState(() {
                _isShopOpen = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isShopOpen ? 'दुकान लाइव हो गई है।' : 'दुकान बंद कर दी गई है।')),
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'डैशबोर्ड'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'कैटलॉग'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'ऑर्डर्स'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'सेटिंग्स'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              backgroundColor: Colors.amber,
              onPressed: () => _showProfessionalProductDialog(),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('नया उत्पाद', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildAnalyticsDashboardTab() {
    int totalOrders = EnterpriseDatabase.orderLedger.length;
    double totalRevenue = 0;
    
    // सुरक्षित पार्सिंग ताकि स्ट्रिंग या डबल दोनों में क्रैश न हो
    for (var order in EnterpriseDatabase.orderLedger) {
      var rawAmount = order['totalAmount'];
      if (rawAmount != null) {
        totalRevenue += double.tryParse(rawAmount.toString()) ?? 0.0;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isShopOpen ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isShopOpen ? 'आपकी दुकान लाइव है' : 'दुकान बंद है', style: TextStyle(color: _isShopOpen ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('ग्राहक अभी ऑर्डर दे सकते हैं', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: _isShopOpen,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _isShopOpen = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('कारोबार सारांश', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildMetricCard('कुल बिक्री', '₹${totalRevenue.toStringAsFixed(1)}', Icons.currency_rupee, Colors.greenAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('कुल ऑर्डर्स', '$totalOrders', Icons.shopping_cart, Colors.amber)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInventoryCatalogTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: EnterpriseDatabase.globalInventory.length,
      itemBuilder: (context, index) {
        final item = EnterpriseDatabase.globalInventory[index];
        final imgPath = item['image']?.toString() ?? '';
        final bool isInStock = item['isInStock'] ?? true;

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[850],
                    child: imgPath.isNotEmpty && File(imgPath).existsSync()
                        ? Image.file(File(imgPath), fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.amber, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('₹${item['price']} | स्टॉक: ${item['stock']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(isInStock ? '● In-Stock' : '● Out of Stock', style: TextStyle(color: isInStock ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                      onPressed: () => _showProfessionalProductDialog(existingProduct: item, editIndex: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() {
                          EnterpriseDatabase.globalInventory.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderLedgerTab() {
    return EnterpriseDatabase.orderLedger.isEmpty
        ? const Center(child: Text('कोई नया ऑर्डर नहीं है।', style: TextStyle(color: Colors.grey, fontSize: 16)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: EnterpriseDatabase.orderLedger.length,
            itemBuilder: (context, index) {
              final order = EnterpriseDatabase.orderLedger[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ऑर्डर #${order['orderId']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(order['date'] ?? 'आज', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Divider(color: Colors.grey, height: 16),
                      Text('ग्राहक: ${order['customerName']} (${order['phone']})', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      Text('आइटम: ${order['items']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('कुल राशि: ₹${order['totalAmount']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () {
                                HapticFeedback.vibrate();
                                setState(() {
                                  order['status'] = 'Accepted';
                                });
                              },
                              child: const Text('Accept (स्वीकार करें)', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                              onPressed: () {
                                setState(() {
                                  order['status'] = 'Rejected';
                                });
                              },
                              child: const Text('Reject (रद्द करें)', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildStoreSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('दुकान सेटिंग्स', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.store, color: Colors.amber),
                    title: const Text('दुकान का नाम', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(EnterpriseDatabase.activeShopProfile['shopName'] ?? 'मेरी दुकान', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.amber),
                    title: const Text('मोबाइल नंबर', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(EnterpriseDatabase.activeShopProfile['phone'] ?? '9999999999', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.amber),
                    title: const Text('पता', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(EnterpriseDatabase.activeShopProfile['address'] ?? 'Faridabad', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
