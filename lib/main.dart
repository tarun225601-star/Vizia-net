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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E293B),
        ),
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
          backgroundColor: const Color(0xFF0B0F19),
          elevation: 4,
          title: Row(
            children: [
              const Text(
                'VIZIAG MART',
                style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.store, size: 14),
                label: const Text('Shop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.lock_outline, size: 14),
                label: const Text('Vendor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(32),
            child: Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_circle, color: Color(0xFFF59E0B), size: 15),
                        const SizedBox(width: 6),
                        Text(CakeDatabase.currentCustomerName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: const Text('(Edit Profile & Address)', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)]),
        ),
        child: IndexedStack(index: _selectedTabIndex > 2 ? 2 : _selectedTabIndex, children: _tabScreens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 2 ? 2 : _selectedTabIndex,
        selectedItemColor: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFF0B0F19),
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
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
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
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Edit Profile & Address', style: TextStyle(fontSize: 15, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
              onPressed: () {
                setState(() {
                  CakeDatabase.currentCustomerName = nameCtrl.text.trim();
                  CakeDatabase.currentUserPhone = phoneCtrl.text.trim();
                  CakeDatabase.currentDeliveryAddress = addressCtrl.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Text('🔒 वेंडर लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
            const SizedBox(height: 20),
            TextField(controller: pinCtrl, obscureText: true, decoration: const InputDecoration(labelText: '4-Digit PIN (9971)')),
            const SizedBox(height: 10),
            TextField(controller: approvalCtrl, decoration: const InputDecoration(labelText: 'Approval Code (tarun#1)')),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
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
        children: const [
          TabBar(
            isScrollable: true,
            labelColor: Color(0xFFF59E0B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFF59E0B),
            tabs: [
              Tab(text: '📦 प्रोडक्ट्स जोड़ें'),
              Tab(text: '📋 कस्टमर आर्डर्स'),
              Tab(text: '⚙️ दुकान सेटिंग्स'),
            ],
          ),
          Expanded(
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
  String category = 'Fresh Fruits';
  String unit = 'Kg';
  String? itemImageBase64;

  Future<void> _addProduct() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
    var newProd = {
      'name': nameCtrl.text.trim(),
      'price': double.tryParse(priceCtrl.text) ?? 0.0,
      'category': category,
      'unit': unit,
      'image': itemImageBase64 ?? '',
      'inStock': true,
    };
    await http.post(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'), body: json.encode(newProd));
    nameCtrl.clear();
    priceCtrl.clear();
    setState(() => itemImageBase64 = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ प्रोडक्ट जुड़ गया!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GestureDetector(
          onTap: () async {
            String? img = await pickAndConvertToBase64();
            if (img != null) setState(() => itemImageBase64 = img);
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B))),
            child: itemImageBase64 == null
                ? const Center(child: Text('📷 आइटम फोटो अपलोड करें', style: TextStyle(color: Color(0xFFF59E0B))))
                : ClipRRect(borderRadius: BorderRadius.circular(10), child: buildShopOrProdImage(itemImageBase64, 100, double.infinity, Icons.image)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'प्रोडक्ट का नाम')),
        TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'कीमत (₹)')),
        DropdownButtonFormField<String>(
          value: category,
          dropdownColor: const Color(0xFF1E293B),
          items: ['Fresh Fruits', 'Vegetables', 'Organic Items', 'Daily Essentials'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => category = val!),
          decoration: const InputDecoration(labelText: 'कैटेगरी'),
        ),
        DropdownButtonFormField<String>(
          value: unit,
          dropdownColor: const Color(0xFF1E293B),
          items: ['Kg', 'Gram', 'Piece', 'Packet', 'Dozen'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (val) => setState(() => unit = val!),
          decoration: const InputDecoration(labelText: 'यूनिट (मात्रा इकाई)'),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
          onPressed: _addProduct,
          child: const Text('नया आइटम जोड़ें', style: TextStyle(fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
            onPressed: _fetchOrders,
            icon: const Icon(Icons.sync),
            label: const Text('आर्डर्स रिफ्रेश करें', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        if (isLoading) const LinearProgressIndicator(color: Color(0xFFF59E0B)),
        Expanded(
          child: allOrders.isEmpty
              ? const Center(child: Text('कोई आर्डर नहीं आया है', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: allOrders.length,
                  itemBuilder: (context, index) {
                    var ord = allOrders[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('ग्राहक: ${ord['customerName']} (${ord['customerPhone']})', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                        subtitle: Text('पता: ${ord['customerAddress']}\nकुल राशि: ₹${ord['grandTotal']?.toInt()}\nस्टेटस: ${ord['status']}'),
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

  Future<void> _saveSettings() async {
    CakeDatabase.bakeryShop['shopName'] = shopNameCtrl.text;
    CakeDatabase.bakeryShop['address'] = addressCtrl.text;
    await http.put(Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'), body: json.encode(CakeDatabase.bakeryShop));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ सेटिंग्स सेव हो गई!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
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
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
          onPressed: _saveSettings,
          child: const Text('सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
