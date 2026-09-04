import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CakeAppEnterpriseApp());
}

class CakeAppEnterpriseApp extends StatelessWidget {
  const CakeAppEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CakeApp - Ultra Premium Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFF59E0B), // Rich Neon Gold / Amber
          secondary: const Color(0xFFEC4899), // Vibrant Pink Accent
          surface: const Color(0xFF1E293B), // Dark Slate Card BG
          background: const Color(0xFF0F172A), // Deep Rich Dark Background
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const CakeMainHubScreen(),
    );
  }
}

// ==========================================
// CENTRAL DATABASE & CLOUD SYNC MODEL
// ==========================================
class CakeDatabase {
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/"; 

  static String currentUserPhone = "9971968060";
  static String currentCustomerName = "Tarun Kumar";
  static String currentDeliveryAddress = "Sector 15A Faridabad";

  // Active Delivery Partner Info
  static String currentDeliveryPartnerPhone = "9971968070";
  static String currentDeliveryPartnerName = "Ravi Kumar (Delivery)";

  static Map<String, dynamic> bakeryShop = {
    'shopId': 'shop_cake_01',
    'shopName': 'Tarun Fruit & Vegetable Shop',
    'ownerName': 'Tarun Kumar',
    'ownerPhone': '9971968060',
    'ownerPhotoPath': '', 
    'bannerPhotoPath': '',
    'shopPhotoPath': '',
    'phone': '9971968060',
    'whatsappNumber': '919971968060',
    'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
    'bio': 'ताज़ा फल, सब्जियां और बेकरी उत्पाद उपलब्ध।',
    'isOpen': true,
  };

  static List<Map<String, dynamic>> productInventory = [];
  static List<Map<String, dynamic>> cartItems = [];
}

// ==========================================
// MAIN HUB SCREEN WITH INDEXED STACK
// ==========================================
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
    const DeliveryPartnerPortalView(),
    const CartAndWhatsAppCheckoutView(),
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
          shadowColor: const Color(0xFFF59E0B).withOpacity(0.3),
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899)],
                ).createShader(bounds),
                child: const Text(
                  'CAKEAPP',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
                ),
              ),
              const Spacer(),
              _buildNavBtn('Shop', Icons.cake, 0),
              const SizedBox(width: 4),
              _buildNavBtn('Vendor', Icons.lock_outline, 1),
              const SizedBox(width: 4),
              _buildNavBtn('Delivery', Icons.delivery_dining, 2),
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
                        Text(
                          CakeDatabase.currentCustomerName,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: IndexedStack(
          index: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
          children: _tabScreens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: const Color(0xFF0B0F19),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_outlined), label: 'Delivery'),
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

  Widget _buildNavBtn(String label, IconData icon, int index) {
    bool isSelected = _selectedTabIndex == index;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF334155),
        foregroundColor: isSelected ? Colors.black87 : Colors.white,
        elevation: isSelected ? 6 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => setState(() => _selectedTabIndex = index),
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Location Note', isDense: true)),
              ],
            ),
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

// ==========================================
// IMAGE HELPER
// ==========================================
Widget buildShopOrProdImage(String? path, double height, double width, IconData fallbackIcon) {
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http')) {
      return Image.network(path, height: height, width: width, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: const Color(0xFF334155), child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B))));
    } else if (path.startsWith('data:image')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return Image.memory(bytes, height: height, width: width, fit: BoxFit.cover);
      } catch (_) {}
    } else if (File(path).existsSync()) {
      return Image.file(File(path), height: height, width: width, fit: BoxFit.cover);
    }
  }
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B)),
  );
}

// ==========================================
// MARKETPLACE BUYER VIEW
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String selectedCategory = 'All';
  bool _isLoadingCloud = false;
  
  final Map<String, double> _itemQuantities = {};
  final Map<String, TextEditingController> _cakeMessageControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  final List<String> cakeCategories = [
    'All', 'Birthday Cake', 'Anniversary Cake', 'Chocolate Cake', 'Kids / Cartoon Cake',
    'Fruit Cake', 'Red Velvet', 'Heart Shaped Cake', 'Tier / Wedding Cake', 'Cupcakes & Pastries',
    'Designer / Custom Cake', 'Truffle Cake', 'Butterscotch', 'Black Forest', 'Pineapple Cake',
    'Strawberry Cake', 'Coffee / Mocha Cake', 'Photo Cake', 'Combos (Cake + Flowers)',
    'Midnight Special Cake', 'Fasting / Eggless Special'
  ];

  @override
  void initState() {
    super.initState();
    _fetchShopProfileAndProducts();
  }

  @override
  void dispose() {
    for (var ctrl in _cakeMessageControllers.values) ctrl.dispose();
    for (var ctrl in _qtyControllers.values) ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchShopProfileAndProducts() async {
    setState(() => _isLoadingCloud = true);
    try {
      final shopRes = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'));
      if (shopRes.statusCode == 200 && shopRes.body != 'null' && shopRes.body.isNotEmpty) {
        var data = json.decode(shopRes.body);
        if (data is Map) {
          setState(() {
            CakeDatabase.bakeryShop = Map<String, dynamic>.from(data);
          });
        }
      }

      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedList = [];
        data.forEach((key, value) {
          var item = Map<String, dynamic>.from(value);
          item['firebaseKey'] = key;
          fetchedList.add(item);
        });
        setState(() {
          CakeDatabase.productInventory = fetchedList.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint("Cloud sync error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCloud = false);
    }
  }

  void _addToCart(Map<String, dynamic> prod, double qty, String cakeMsg) {
    if (CakeDatabase.bakeryShop['isOpen'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Sorry! Shop is currently CLOSED.'), backgroundColor: Colors.red));
      return;
    }
    if (prod['inStock'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ This item is currently OUT OF STOCK!')));
      return;
    }

    String prodName = prod['name'];
    var existingIndex = CakeDatabase.cartItems.indexWhere((item) => item['name'] == prodName);

    setState(() {
      if (existingIndex >= 0) {
        CakeDatabase.cartItems[existingIndex]['qty'] = qty;
        CakeDatabase.cartItems[existingIndex]['cakeMessage'] = cakeMsg;
      } else {
        CakeDatabase.cartItems.add({
          'name': prodName,
          'price': prod['price'],
          'unit': prod['unit'] ?? 'Piece',
          'qty': qty,
          'cakeMessage': cakeMsg,
          'shopName': CakeDatabase.bakeryShop['shopName'],
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛒 Added $qty ${prod['unit'] ?? 'Piece'} $prodName to Cart!'), backgroundColor: const Color(0xFFF59E0B), duration: const Duration(milliseconds: 900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredProducts = CakeDatabase.productInventory.where((p) {
      if (selectedCategory == 'All') return true;
      return p['category'] == selectedCategory;
    }).toList();

    var shop = CakeDatabase.bakeryShop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ((shop['bannerPhotoPath'] ?? '').toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: buildShopOrProdImage(shop['bannerPhotoPath'], 140, double.infinity, Icons.store),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: buildShopOrProdImage(shop['shopPhotoPath'] ?? shop['ownerPhotoPath'], 65, 65, Icons.store),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop['shopName'] ?? 'Tarun Shop', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFF59E0B))),
                            const SizedBox(height: 3),
                            Text('👤 Owner: ${shop['ownerName'] ?? 'Tarun Kumar'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 2),
                            Text('📍 ${shop['address'] ?? 'Faridabad'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: _fetchShopProfileAndProducts, icon: const Icon(Icons.sync, color: Color(0xFFF59E0B)), tooltip: 'Sync'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cakeCategories.map((category) {
                bool isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.black87 : Colors.white70)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF59E0B),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (bool selected) => setState(() => selectedCategory = category),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_isLoadingCloud) ...[const SizedBox(height: 10), const LinearProgressIndicator(color: Color(0xFFF59E0B))],
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              var prod = filteredProducts[index];
              String prodKey = prod['firebaseKey'] ?? prod['id'] ?? index.toString();
              double unitPrice = (prod['price'] ?? 499.0).toDouble();
              double selectedQty = _itemQuantities[prodKey] ?? 1.0;
              double totalPrice = unitPrice * selectedQty;
              bool inStock = prod['inStock'] ?? true;

              if (!_cakeMessageControllers.containsKey(prodKey)) _cakeMessageControllers[prodKey] = TextEditingController();
              var msgController = _cakeMessageControllers[prodKey]!;

              if (!_qtyControllers.containsKey(prodKey)) _qtyControllers[prodKey] = TextEditingController(text: selectedQty.toInt().toString());
              var qtyController = _qtyControllers[prodKey]!;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: buildShopOrProdImage(prod['imagePath'], 95, 95, Icons.cake)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('₹${unitPrice.toInt()} / ${prod['unit'] ?? 'Piece'}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: msgController,
                              style: const TextStyle(fontSize: 11, color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'विशेष निर्देश / नोट',
                                labelStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Qty:', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 35, height: 24,
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)), contentPadding: EdgeInsets.zero),
                                    onChanged: (val) {
                                      double? q = double.tryParse(val);
                                      if (q != null && q > 0) setState(() => _itemQuantities[prodKey] = q);
                                    },
                                  ),
                                ),
                                const Spacer(),
                                Text('₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFEC4899))),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: inStock ? const Color(0xFFF59E0B) : Colors.grey, foregroundColor: Colors.black87),
                                    onPressed: inStock ? () => _addToCart(prod, selectedQty, msgController.text.trim()) : null,
                                    child: Text(inStock ? 'Add' : 'Out', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

// ==========================================
// VENDOR AUTH & DASHBOARD PORTAL
// ==========================================
class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  bool _isLoggedIn = false;
  final TextEditingController _loginPhoneCtrl = TextEditingController();
  final TextEditingController _loginPinCtrl = TextEditingController();
  final TextEditingController _regPhoneCtrl = TextEditingController();
  final TextEditingController _createPinCtrl = TextEditingController();
  bool _isRegisteringNew = false;
  bool _isLoadingAuth = false;

  Future<void> _verifyOrLoginVendor() async {
    String phone = _loginPhoneCtrl.text.trim();
    String pin = _loginPinCtrl.text.trim();
    if (phone.isEmpty || pin.isEmpty) return;

    setState(() => _isLoadingAuth = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendors/$phone.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        var data = json.decode(response.body);
        if (data['pin'] == pin) {
          setState(() { _isLoggedIn = true; CakeDatabase.currentUserPhone = phone; });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ गलत पिन!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ नंबर रजिस्टर्ड नहीं है।')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingAuth = false);
    }
  }

  Future<void> _saveNewVendorPin() async {
    String phone = _regPhoneCtrl.text.trim();
    String pin = _createPinCtrl.text.trim();
    if (phone.isEmpty || pin.length != 4) return;

    setState(() => _isLoadingAuth = true);
    try {
      await http.put(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendors/$phone.json'), body: json.encode({'phone': phone, 'pin': pin}));
      if (mounted) setState(() { _isLoggedIn = true; _isRegisteringNew = false; CakeDatabase.currentUserPhone = phone; });
    } finally {
      if (mounted) setState(() => _isLoadingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 55, color: Color(0xFFF59E0B)),
                  const SizedBox(height: 10),
                  Text(_isRegisteringNew ? '🛠️ नया पिन बनाएं' : '🔐 ओनर लॉगिन', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 15),
                  if (!_isRegisteringNew) ...[
                    TextField(controller: _loginPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _loginPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-अंक पिन', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87), onPressed: _verifyOrLoginVendor, child: const Text('लॉगिन करें')),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = true), child: const Text('नया अकाउंट? पिन सेट करें', style: TextStyle(color: Color(0xFFEC4899)))),
                  ] else ...[
                    TextField(controller: _regPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _createPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'नया पिन', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _saveNewVendorPin, child: const Text('पिन सेव करें')),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = false), child: const Text('लॉगिन पर वापस')),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const VendorPortalDashboardView();
  }
}

class VendorPortalDashboardView extends StatefulWidget {
  const VendorPortalDashboardView({super.key});

  @override
  State<VendorPortalDashboardView> createState() => _VendorPortalDashboardViewState();
}

class _VendorPortalDashboardViewState extends State<VendorPortalDashboardView> {
  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _vendorOrders = [];
  List<Map<String, dynamic>> _vendorProducts = [];
  bool _isLoadingOrders = false;
  bool _isLoadingProducts = false;
  String _selectedCategory = 'Birthday Cake';
  String? _pickedProdImagePath;

  @override
  void initState() {
    super.initState();
    _fetchVendorOrders();
    _fetchVendorProducts();
  }

  Future<void> _fetchVendorOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          list.add(item);
        });
        if (mounted) setState(() => _vendorOrders = list.reversed.toList());
      }
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _fetchVendorProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          list.add(item);
        });
        if (mounted) setState(() => _vendorProducts = list.reversed.toList());
      }
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _acceptAndForwardToDelivery(String orderKey) async {
    try {
      // Mark as accepted and trigger sequential delivery dispatch
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderKey.json'),
        body: json.encode({
          'status': 'Assigned to Delivery (Pending Pickup) 🛵',
          'deliveryStatus': 'pending_agent_1',
          'assignedAgentPhone': '',
        }),
      );
      _fetchVendorOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Order Accepted & Forwarded to Delivery Network!'), backgroundColor: Colors.green));
      }
    } catch (_) {}
  }

  Future<void> _rejectOrder(String orderKey) async {
    await http.patch(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderKey.json'), body: json.encode({'status': 'Rejected ❌'}));
    _fetchVendorOrders();
  }

  Future<void> _publishProduct() async {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    var newProduct = {
      'name': _prodNameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 499.0,
      'category': _selectedCategory,
      'imagePath': _pickedProdImagePath ?? '',
      'inStock': true,
    };
    await http.post(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'), body: json.encode(newProduct));
    _prodNameCtrl.clear();
    _priceCtrl.clear();
    setState(() => _pickedProdImagePath = null);
    _fetchVendorProducts();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Add Product Quick Widget
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('📦 Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
              const SizedBox(height: 8),
              TextField(controller: _prodNameCtrl, decoration: const InputDecoration(labelText: 'Item Name', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', isDense: true)),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white),
                onPressed: _publishProduct,
                child: const Text('Publish Item'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('📋 Permanent Vendor Orders', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
            const Spacer(),
            IconButton(onPressed: _fetchVendorOrders, icon: const Icon(Icons.sync, color: Color(0xFFF59E0B))),
          ],
        ),
        _isLoadingOrders 
            ? const Center(child: CircularProgressIndicator())
            : _vendorOrders.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(12), child: Center(child: Text('कोई आर्डर नहीं मिला'))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vendorOrders.length,
                    itemBuilder: (context, index) {
                      var ord = _vendorOrders[index];
                      String status = ord['status'] ?? 'Pending ⏳';
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${ord['customerName']} - ₹${ord['grandTotal']?.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  const Spacer(),
                                  Chip(label: Text(status, style: const TextStyle(fontSize: 9)), backgroundColor: Colors.orange),
                                ],
                              ),
                              Text('📞 ${ord['customerPhone']} | 📍 ${ord['customerAddress']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 8),
                              if (status.contains('Pending'))
                                Row(
                                  children: [
                                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _acceptAndForwardToDelivery(ord['firebaseKey']), child: const Text('Accept & Forward'))),
                                    const SizedBox(width: 8),
                                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _rejectOrder(ord['firebaseKey']), child: const Text('Reject'))),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}

// ==========================================
// DELIVERY PARTNER PORTAL & SEQUENTIAL DISPATCH
// ==========================================
class DeliveryPartnerPortalView extends StatefulWidget {
  const DeliveryPartnerPortalView({super.key});

  @override
  State<DeliveryPartnerPortalView> createState() => _DeliveryPartnerPortalViewState();
}

class _DeliveryPartnerPortalViewState extends State<DeliveryPartnerPortalView> {
  bool _isDeliveryLoggedIn = false;
  final TextEditingController _phoneCtrl = TextEditingController(text: CakeDatabase.currentDeliveryPartnerPhone);
  final TextEditingController _nameCtrl = TextEditingController(text: CakeDatabase.currentDeliveryPartnerName);
  List<Map<String, dynamic>> _availableOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDispatchQueue();
  }

  Future<void> _fetchDispatchQueue() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          // Filter orders forwarded to delivery network
          if ((item['status'] ?? '').toString().contains('Delivery')) {
            list.add(item);
          }
        });
        if (mounted) setState(() => _availableOrders = list.reversed.toList());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrderAsDelivery(String orderKey) async {
    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderKey.json'),
        body: json.encode({
          'status': 'Out for Delivery 🛵 by ${_nameCtrl.text}',
          'assignedAgentPhone': _phoneCtrl.text,
        }),
      );
      _fetchDispatchQueue();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 You accepted the delivery assignment!'), backgroundColor: Colors.green));
    } catch (_) {}
  }

  Future<void> _passToNextAgent(String orderKey) async {
    // Passes dispatch to next agent in queue
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏭️ Order passed to next delivery partner in queue.')));
    _fetchDispatchQueue();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeliveryLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.delivery_dining, size: 50, color: Color(0xFFF59E0B)),
                const SizedBox(height: 10),
                const Text('🛵 डिलीवरी पार्टनर लॉगिन / प्रोफाइल', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'आपका नाम', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
                  onPressed: () => setState(() => _isDeliveryLoggedIn = true),
                  child: const Text('डैशबोर्ड खोलें', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Text('🛵 Delivery Dashboard: ${_nameCtrl.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF59E0B))),
            const Spacer(),
            IconButton(onPressed: _fetchDispatchQueue, icon: const Icon(Icons.sync, color: Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _availableOrders.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text('कोई आर्डर डिलीवरी के लिए उपलब्ध नहीं है'))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableOrders.length,
                    itemBuilder: (context, index) {
                      var ord = _availableOrders[index];
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${ord['customerName']} - ₹${ord['grandTotal']?.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('📍 Address: ${ord['customerAddress']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () => _acceptOrderAsDelivery(ord['firebaseKey']),
                                      child: const Text('Accept Order', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                      onPressed: () => _passToNextAgent(ord['firebaseKey']),
                                      child: const Text('Pass (Next)', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}

// ==========================================
// CART & WHATSAPP CHECKOUT VIEW
// ==========================================
class CartAndWhatsAppCheckoutView extends StatefulWidget {
  const CartAndWhatsAppCheckoutView({super.key});

  @override
  State<CartAndWhatsAppCheckoutView> createState() => _CartAndWhatsAppCheckoutViewState();
}

class _CartAndWhatsAppCheckoutViewState extends State<CartAndWhatsAppCheckoutView> {
  bool _isPlacingOrder = false;

  void _showCheckoutConfirmationPopup(double grandTotal) {
    final nameCtrl = TextEditingController(text: CakeDatabase.currentCustomerName);
    final phoneCtrl = TextEditingController(text: CakeDatabase.currentUserPhone);
    final addressCtrl = TextEditingController(text: CakeDatabase.currentDeliveryAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('🛒 Confirm Delivery Order', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name', isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Delivery Address', isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  CakeDatabase.currentCustomerName = nameCtrl.text.trim();
                  CakeDatabase.currentUserPhone = phoneCtrl.text.trim();
                  CakeDatabase.currentDeliveryAddress = addressCtrl.text.trim();
                });
                Navigator.pop(context);
                _sendOrderToWhatsApp(grandTotal);
              },
              child: const Text('Confirm & Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendOrderToWhatsApp(double grandTotal) async {
    if (CakeDatabase.cartItems.isEmpty) return;
    setState(() => _isPlacingOrder = true);

    String formattedTime = "${DateTime.now().hour}:${DateTime.now().minute} (${DateTime.now().day}/${DateTime.now().month})";
    var orderData = {
      'orderId': 'ord_${DateTime.now().millisecondsSinceEpoch}',
      'customerName': CakeDatabase.currentCustomerName,
      'customerPhone': CakeDatabase.currentUserPhone,
      'customerAddress': CakeDatabase.currentDeliveryAddress,
      'items': List.from(CakeDatabase.cartItems),
      'grandTotal': grandTotal,
      'orderTime': formattedTime,
      'status': 'Pending ⏳',
    };

    try {
      await http.post(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'), body: json.encode(orderData));
    } catch (_) {}

    setState(() {
      CakeDatabase.cartItems.clear();
      _isPlacingOrder = false;
    });

    String vendorPhone = CakeDatabase.bakeryShop['whatsappNumber'] ?? '919971968060';
    String message = "🛒 *New Order*\n👤 *Customer:* ${CakeDatabase.currentCustomerName}\n📍 *Address:* ${CakeDatabase.currentDeliveryAddress}\n💰 *Total:* ₹${grandTotal.toInt()}";
    
    String whatsappUrl = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    var cart = CakeDatabase.cartItems;
    double grandTotal = cart.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['qty'] as double)));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          const Text('🛒 Cart & Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 6),
          cart.isEmpty
              ? const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Cart is empty'))))
              : Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        var item = cart[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          child: ListTile(
                            title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Qty: ${item['qty']} • ₹${item['price']}'),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => CakeDatabase.cartItems.removeAt(index))),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      onPressed: _isPlacingOrder ? null : () => _showCheckoutConfirmationPopup(grandTotal),
                      icon: const Icon(Icons.chat),
                      label: Text('Checkout (₹${grandTotal.toInt()}) via WhatsApp 🚀', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
