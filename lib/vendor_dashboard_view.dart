// ============================================================================
// FILE: vendor_dashboard_view.dart (Multi-Vendor Marketplace - Base64 Storage Final)
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'database_models.dart';

class VendorDashboardView extends StatefulWidget {
  const VendorDashboardView({super.key});

  @override
  State<VendorDashboardView> createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView> {
  int _currentIndex = 0;
  bool _isShopOpen = true;

  // Helper method to convert File to Base64 String
  Future<String?> _convertFileToBase64(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Base64 Encoding Error: $e');
    }
    return null;
  }

  // Helper method to display Image from Base64 or File path
  Widget _buildImageWidget(String? imageSource, {BoxFit fit = BoxFit.cover}) {
    if (imageSource == null || imageSource.isEmpty) {
      return const Icon(Icons.image, color: Colors.amber, size: 30);
    }
    try {
      // Check if it's already a base64 string or a local file path
      if (!imageSource.startsWith('/')) {
        final bytes = base64Decode(imageSource);
        return Image.memory(bytes, fit: fit);
      } else {
        return Image.file(File(imageSource), fit: fit);
      }
    } catch (e) {
      // Fallback if decode fails
      if (File(imageSource).existsSync()) {
        return Image.file(File(imageSource), fit: fit);
      }
      return const Icon(Icons.broken_image, color: Colors.red, size: 30);
    }
  }

  void _showProfessionalProductDialog({Map<String, dynamic>? existingProduct, int? editIndex}) {
    final nameController = TextEditingController(text: existingProduct?['name'] ?? '');
    final priceController = TextEditingController(text: existingProduct?['price']?.toString() ?? '');
    final stockController = TextEditingController(text: existingProduct?['stock']?.toString() ?? '');
    final descController = TextEditingController(text: existingProduct?['description'] ?? '');
    
    String category = existingProduct?['category'] ?? 'Automotive Care';
    String? localImageBase64 = existingProduct?['image'];
    bool isInStock = existingProduct?['isInStock'] ?? true;

    final List<String> categories = [
      'Automotive Care',
      'Dash & Polish',
      'Shampoos & Waxes',
      'Microfiber & Tools',
      'General Accessories'
    ];

    Future<void> pickAndConvertImage(StateSetter setDialogState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (pickedFile != null) {
        final base64String = await _convertFileToBase64(pickedFile.path);
        if (base64String != null) {
          setDialogState(() {
            localImageBase64 = base64String;
          });
        }
      }
    }

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

                  Center(
                    child: GestureDetector(
                      onTap: () => pickAndConvertImage(setDialogState),
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: localImageBase64 != null && localImageBase64!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImageWidget(localImageBase64),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.amber, size: 28),
                                  SizedBox(height: 4),
                                  Text('फोटो जोड़ें', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

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
                        'image': localImageBase64 ?? '', // Base64 Saved
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
                        const SnackBar(content: Text('उत्पाद Base64 डेटाबेस में सुरक्षित कर दिया गया!'), backgroundColor: Colors.green),
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
            CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 16,
              child: EnterpriseDatabase.activeShopProfile['shopImage'] != null &&
                     EnterpriseDatabase.activeShopProfile['shopImage'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: _buildImageWidget(EnterpriseDatabase.activeShopProfile['shopImage']),
                      ),
                    )
                  : const Icon(Icons.store, color: Colors.black, size: 18),
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
        final imgSource = item['image']?.toString() ?? '';
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
                    child: _buildImageWidget(imgSource),
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
              final String status = order['status'] ?? 'Pending';

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
                          Text('ऑर्डर #${order['orderId'] ?? '1001'}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Accepted' ? Colors.green.withOpacity(0.2) : status == 'Rejected' ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status == 'Accepted' ? 'स्वीकृत (Accepted)' : status == 'Rejected' ? 'अस्वीकृत (Rejected)' : 'लंबित (Pending)',
                              style: TextStyle(
                                color: status == 'Accepted' ? Colors.green : status == 'Rejected' ? Colors.red : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey, height: 16),
                      Text('ग्राहक: ${order['customerName'] ?? 'ग्राहक'} (${order['phone'] ?? 'नंबर नहीं'})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('डिलिवरी पता: ${order['address'] ?? 'Faridabad (लोकल एड्रेस)'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('आइटम: ${order['items'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('कुल राशि: ₹${order['totalAmount'] ?? '0'}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                HapticFeedback.vibrate();
                                setState(() {
                                  order['status'] = 'Accepted';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ऑर्डर स्वीकार कर लिया गया! ग्राहक खुद पिकअप करने आ रहा है या आप डिलीवर करेंगे।'), backgroundColor: Colors.green),
                                );
                              },
                              child: const Text('Accept (स्वीकार करें)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                HapticFeedback.vibrate();
                                setState(() {
                                  order['status'] = 'Rejected';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ऑर्डर रद्द कर दिया गया।'), backgroundColor: Colors.red),
                                );
                              },
                              child: const Text('Reject (रद्द करें)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.iconStyleFrom(
                            side: const BorderSide(color: Colors.amber),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.storefront, color: Colors.amber, size: 18),
                          label: const Text('Self Delivery / दुकान से पिकअप', style: TextStyle(color: Colors.amber, fontSize: 12)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('सेल्फ डिलीवरी / पिकअप के लिए आर्डर तैयार है (${order['customerName'] ?? 'ग्राहक'} के लिए)।')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildStoreSettingsTab() {
    final shopNameController = TextEditingController(text: EnterpriseDatabase.activeShopProfile['shopName'] ?? '');
    final ownerNameController = TextEditingController(text: EnterpriseDatabase.activeShopProfile['ownerName'] ?? '');
    final phoneController = TextEditingController(text: EnterpriseDatabase.activeShopProfile['phone'] ?? '');
    final shopNumberController = TextEditingController(text: EnterpriseDatabase.activeShopProfile['shopNumber'] ?? '');
    final addressController = TextEditingController(text: EnterpriseDatabase.activeShopProfile['address'] ?? '');

    Future<void> pickAndConvertStoreImage(bool isShop, StateSetter setSettingsState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (pickedFile != null) {
        final base64String = await _convertFileToBase64(pickedFile.path);
        if (base64String != null) {
          setSettingsState(() {
            if (isShop) {
              EnterpriseDatabase.activeShopProfile['shopImage'] = base64String;
            } else {
              EnterpriseDatabase.activeShopProfile['ownerImage'] = base64String;
            }
          });
          setState(() {}); // Refresh appbar if shop image changes
        }
      }
    }

    return StatefulBuilder(
      builder: (context, setSettingsState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('मेरी दुकान और ओनर प्रोफाइल सेटिंग्स', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('यहाँ अपनी दुकान और अपनी सही जानकारी भरें। सभी फोटो Base64 फॉर्मेट में सेव होंगी।', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () => pickAndConvertStoreImage(true, setSettingsState),
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: EnterpriseDatabase.activeShopProfile['shopImage'] != null && 
                             EnterpriseDatabase.activeShopProfile['shopImage'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageWidget(EnterpriseDatabase.activeShopProfile['shopImage']),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store, color: Colors.amber, size: 28),
                                SizedBox(height: 4),
                                Text('शॉप फोटो', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('दुकान का फोटो', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => pickAndConvertStoreImage(false, setSettingsState),
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: EnterpriseDatabase.activeShopProfile['ownerImage'] != null && 
                             EnterpriseDatabase.activeShopProfile['ownerImage'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageWidget(EnterpriseDatabase.activeShopProfile['ownerImage']),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, color: Colors.amber, size: 28),
                                SizedBox(height: 4),
                                Text('ओनर फोटो', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('मालिक का फोटो', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: shopNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _getInputDecoration('दुकान का नाम (Shop Name)', Icons.store),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: ownerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _getInputDecoration('मालिक का नाम (Owner Name)', Icons.person),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _getInputDecoration('मोबाइल नंबर', Icons.phone),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: shopNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _getInputDecoration('शॉप नंबर / बूथ नं', Icons.confirmation_number),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: addressController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: _getInputDecoration('पूरा एड्रेस (Full Address & Landmark)', Icons.location_on),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (shopNameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('कृपया दुकान का नाम और मोबाइल नंबर भरें!'), backgroundColor: Colors.red),
                );
                return;
              }

              setState(() {
                EnterpriseDatabase.activeShopProfile['shopName'] = shopNameController.text.trim();
                EnterpriseDatabase.activeShopProfile['ownerName'] = ownerNameController.text.trim();
                EnterpriseDatabase.activeShopProfile['phone'] = phoneController.text.trim();
                EnterpriseDatabase.activeShopProfile['shopNumber'] = shopNumberController.text.trim();
                EnterpriseDatabase.activeShopProfile['address'] = addressController.text.trim();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('दुकान और ओनर की प्रोफाइल Base64 के साथ सेव हो गई!'), backgroundColor: Colors.green),
              );
            },
            child: const Text(
              'दुकान की जानकारी सेव करें',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
