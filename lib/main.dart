import 'package:flutter/material.dart';
import 'database_models.dart';
import 'marketplace_buyer_view.dart';
import 'cart_and_orders_view.dart';
import 'image_picker_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const CakeAppEnterpriseApp());

class CakeAppEnterpriseApp extends StatelessWidget {
  const CakeAppEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CakeMainHubScreen(),
    );
  }
}

class CakeMainHubScreen extends StatefulWidget {
  const CakeMainHubScreen({super.key});

  @override
  State<CakeMainHubScreen> createState() => _CakeMainHubScreenState();
}

class _CakeMainHubScreenState extends State<CakeMainHubScreen> {
  int _selectedTabIndex = 0;

  final List<Widget> _tabScreens = [
    const MarketplaceBuyerView(),
    const VendorAuthAndPortalView(),
    const CartAndOrdersView(),
  ];

  @override
  Widget build(BuildContext context) {
    int totalCartCount = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['qty'] as num?)?.toInt() ?? 1));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              const Text(
                'VIZIAG MART',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.store, size: 14),
                label: const Text('Shop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.lock_outline, size: 14),
                label: const Text('Vendor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: Row(
                      children: [
                        Icon(Icons.person_pin_circle, color: Colors.green.shade700, size: 15),
                        const SizedBox(width: 6),
                        Text(CakeDatabase.currentCustomerName, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: Text('(Edit Profile & Address)', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedTabIndex > 2 ? 2 : _selectedTabIndex, children: _tabScreens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 2 ? 2 : _selectedTabIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedTabIndex = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Vendor'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (totalCartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$totalCartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            label: 'Cart & Orders',
          ),
        ],
      ),
    );
  }

  void _showProfileEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController(text: CakeDatabase.currentCustomerName);
        final phoneCtrl = TextEditingController(text: CakeDatabase.currentUserPhone);
        final addressCtrl = TextEditingController(text: CakeDatabase.currentDeliveryAddress);
        return AlertDialog(
          title: const Text('Edit Profile & Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Location Note', isDense: true)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  CakeDatabase.currentCustomerName = nameCtrl.text.trim();
                  CakeDatabase.currentUserPhone = phoneCtrl.text.trim();
                  CakeDatabase.currentDeliveryAddress = addressCtrl.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  bool _isLoggedIn = false;
  final pinCtrl = TextEditingController();
  final approvalCtrl = TextEditingController();

  void _login() {
    if (pinCtrl.text == '9971' && approvalCtrl.text == 'tarun#1') {
      setState(() => _isLoggedIn = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ गलत पिन या अप्रूवल कोड!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒 वेंडर लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: pinCtrl, obscureText: true, decoration: const InputDecoration(labelText: '4-Digit PIN (9971)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: approvalCtrl, decoration: const InputDecoration(labelText: 'Approval Code (tarun#1)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              onPressed: _login,
              child: const Text('लॉग इन करें', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.green.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green.shade700,
              tabs: const [
                Tab(text: '📦 प्रोडक्ट्स जोड़ें & मैनेज करें'),
                Tab(text: '📋 कस्टमर आर्डर्स'),
                Tab(text: '⚙️ दुकान सेटिंग्स'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                VendorInventoryTab(),
                VendorOrdersTab(),
                VendorSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VendorInventoryTab extends StatefulWidget {
  const VendorInventoryTab({super.key});

  @override
  State<VendorInventoryTab> createState() => _VendorInventoryTabState();
}

class _VendorInventoryTabState extends State<VendorInventoryTab> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final unitCtrl = TextEditingController(text: 'Kg'); // फ्री-टेक्स्ट यूनिट बॉक्स
  String category = 'Fresh Fruits';
  String? itemImageBase64;
  bool _isLoading = false;

  Future<void> _addProduct() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    var newProd = {
      'name': nameCtrl.text.trim(),
      'price': double.tryParse(priceCtrl.text) ?? 0.0,
      'category': category,
      'unit': unitCtrl.text.trim().isEmpty ? 'Kg' : unitCtrl.text.trim(),
      'image': itemImageBase64 ?? '',
      'inStock': true,
    };
    await http.post(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'), body: json.encode(newProd));
    nameCtrl.clear();
    priceCtrl.clear();
    unitCtrl.text = 'Kg';
    setState(() {
      itemImageBase64 = null;
      _isLoading = false;
    });
    // रिफ्रेश के लिए पैरेंट को बताएं या लोकल लिस्ट अपडेट करें
    (contextzenState?.call() );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ प्रोडक्ट सफलतापूर्वक जुड़ गया!'), backgroundColor: Colors.green));
    }
  }

  Future<void> _deleteProduct(String firebaseKey) async {
    await http.delete(Uri.parse('${CakeDatabase.firebaseRestUrl}/products/$firebaseKey.json'));
    setState(() {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ प्रोडक्ट डिलीट हो गया!')));
  }

  Future<void> _toggleStock(String firebaseKey, bool currentStatus) async {
    await http.patch(
      Uri.parse('${CakeDatabase.firebaseRestUrl}/products/$firebaseKey.json'),
      body: json.encode({'inStock': !currentStatus}),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // नया प्रोडक्ट फॉर्म कार्ड
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✨ नया आइटम जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    String? img = await pickAndConvertToBase64();
                    if (img != null) setState(() => itemImageBase64 = img);
                  },
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: itemImageBase64 == null
                        ? const Center(child: Text('📷 आइटम फोटो अपलोड करें', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                        : ClipRRect(borderRadius: BorderRadius.circular(8), child: buildShopOrProdImage(itemImageBase64, 90, double.infinity, Icons.image)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'प्रोडक्ट का नाम', isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'कीमत (₹)', isDense: true)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['Fresh Fruits', 'Vegetables', 'Organic Items', 'Daily Essentials'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => category = val!),
                  decoration: const InputDecoration(labelText: 'कैटेगरी', isDense: true),
                ),
                const SizedBox(height: 10),
                // फ्री-टेक्स्ट यूनिट बॉक्स (अब इसमें Kg, Box, Piece कुछ भी लिख सकते हैं)
                TextField(
                  controller: unitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'यूनिट (मात्रा इकाई - जैसे Kg, Box, Piece, Packet)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : _addProduct,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('नया आइटम जोड़ें', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('📋 आपके मौजूदा प्रोडक्ट्स (मैनेज करें)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        const SizedBox(height: 10),
        // लाइव प्रोडक्ट्स लिस्ट फेच करके मैनेज करने के लिए
        FutureBuilder<http.Response>(
          future: http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.body == 'null' || snapshot.data!.body.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('कोई प्रोडक्ट उपलब्ध नहीं है', style: TextStyle(color: Colors.grey))),
              );
            }
            try {
              Map<String, dynamic> data = json.decode(snapshot.data!.body);
              List<Map<String, dynamic>> items = [];
              data.forEach((key, val) {
                var item = Map<String, dynamic>.from(val);
                item['firebaseKey'] = key;
                items.add(item);
              });
              items = items.reversed.toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var p = items[index];
                  bool inStock = p['inStock'] ?? true;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: buildShopOrProdImage(p['image'], 45, 45, Icons.eco),
                      ),
                      title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('₹${p['price']} / ${p['unit'] ?? 'Kg'}\nस्टेटस: ${inStock ? '🟢 In Stock' : '🔴 Out of Stock'}', style: const TextStyle(fontSize: 11)),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stock Toggle Button
                          Switch(
                            value: inStock,
                            activeColor: Colors.green,
                            onChanged: (val) async {
                              await _toggleStock(p['firebaseKey'], inStock);
                              setState(() {});
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(p['firebaseKey']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } catch (_) {
              return const Text('डेटा लोड करने में त्रुटि');
            }
          },
        ),
      ],
    );
  }
}

class VendorOrdersTab extends StatefulWidget {
  const VendorOrdersTab({super.key});

  @override
  State<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends State<VendorOrdersTab> {
  List<Map<String, dynamic>> allOrders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          list.add(item);
        });
        setState(() => allOrders = list.reversed.toList());
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String firebaseKey, String newStatus) async {
    await http.patch(
      Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$firebaseKey.json'),
      body: json.encode({'status': newStatus}),
    );
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: _fetchOrders,
            icon: const Icon(Icons.sync),
            label: const Text('आर्डर्स रिफ्रेश करें', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        if (isLoading) const LinearProgressIndicator(color: Colors.green),
        Expanded(
          child: allOrders.isEmpty
              ? const Center(child: Text('कोई आर्डर नहीं आया है', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: allOrders.length,
                  itemBuilder: (context, index) {
                    var ord = allOrders[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('ग्राहक: ${ord['customerName']} (${ord['customerPhone']})', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        subtitle: Text('पता: ${ord['customerAddress']}\nकुल राशि: ₹${ord['grandTotal']?.toInt()}\nस्टेटस: ${ord['status']}', style: const TextStyle(color: Colors.black87)),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) => _updateStatus(ord['firebaseKey'], val),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Accepted ✅', child: Text('Accept')),
                            const PopupMenuItem(value: 'Dispatched 🚚', child: Text('Dispatch')),
                            const PopupMenuItem(value: 'Delivered 🎉', child: Text('Deliver')),
                            const PopupMenuItem(value: 'Cancelled ❌', child: Text('Cancel')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class VendorSettingsTab extends StatefulWidget {
  const VendorSettingsTab({super.key});

  @override
  State<VendorSettingsTab> createState() => _VendorSettingsTabState();
}

class _VendorSettingsTabState extends State<VendorSettingsTab> {
  final shopNameCtrl = TextEditingController(text: CakeDatabase.bakeryShop['shopName']);
  final addressCtrl = TextEditingController(text: CakeDatabase.bakeryShop['address']);
  bool isOpen = CakeDatabase.bakeryShop['isOpen'] ?? true;

  Future<void> _saveSettings() async {
    CakeDatabase.bakeryShop['shopName'] = shopNameCtrl.text;
    CakeDatabase.bakeryShop['address'] = addressCtrl.text;
    CakeDatabase.bakeryShop['isOpen'] = isOpen;
    await http.put(Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'), body: json.encode(CakeDatabase.bakeryShop));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ दुकान सेटिंग्स सेव हो गई!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // दुकान चालू / बंद करने का मुख्य स्विच बटन
        Card(
          color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
          child: SwitchListTile(
            title: Text(isOpen ? '🟢 दुकान खुली (Open) है' : '🔴 दुकान बंद (Closed) है', style: TextStyle(fontWeight: FontWeight.bold, color: isOpen ? Colors.green.shade800 : Colors.red.shade800)),
            subtitle: const Text('कस्टमर को आर्डर करने से रोकने या अनुमति देने के लिए टॉगल करें'),
            value: isOpen,
            activeColor: Colors.green,
            onChanged: (val) => setState(() => isOpen = val),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('दुकान की फोटो', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () async {
                    String? img = await pickAndConvertToBase64();
                    if (img != null) setState(() => CakeDatabase.bakeryShop['shopPhotoPath'] = img);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: buildShopOrProdImage(CakeDatabase.bakeryShop['shopPhotoPath'], 70, 70, Icons.store),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Text('बैनर फोटो', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () async {
                    String? img = await pickAndConvertToBase64();
                    if (img != null) setState(() => CakeDatabase.bakeryShop['bannerPhotoPath'] = img);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: buildShopOrProdImage(CakeDatabase.bakeryShop['bannerPhotoPath'], 70, 120, Icons.image),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextField(controller: shopNameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम')),
        TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'दुकान का पता')),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          onPressed: _saveSettings,
          child: const Text('सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
