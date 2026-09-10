import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. डेटाबेस मॉडल और ग्लोबल स्टेट (Database & State)
// ==========================================
class CakeDatabase {
  static String firebaseRestUrl = 'https://viziag-mart-default-rtdb.firebaseio.com';
  static String currentCustomerName = 'Tarun Customer';
  static String currentUserPhone = '9876543210';
  static String currentDeliveryAddress = 'Faridabad, Haryana';

  static List<Map<String, dynamic>> dummyProducts = [
    {'id': '1', 'name': 'Fresh Kashmiri Apple', 'price': 120, 'unit': 'kg', 'category': 'Fresh Fruits', 'stock': 50},
    {'id': '2', 'name': 'Nagpur Organic Orange', 'price': 80, 'unit': 'kg', 'category': 'Fresh Fruits', 'stock': 40},
    {'id': '3', 'name': 'Fresh Bananas (Robusta)', 'price': 50, 'unit': 'dozen', 'category': 'Fresh Fruits', 'stock': 60},
    {'id': '4', 'name': 'Fresh Green Spinach', 'price': 30, 'unit': 'bunch', 'category': 'Vegetables', 'stock': 30},
    {'id': '5', 'name': 'Desi Fresh Tomatoes', 'price': 40, 'unit': 'kg', 'category': 'Vegetables', 'stock': 45},
    {'id': '6', 'name': 'Premium California Almonds', 'price': 800, 'unit': 'kg', 'category': 'Dry Fruits', 'stock': 20},
    {'id': '7', 'name': 'Fresh Farm Milk', 'price': 65, 'unit': 'litre', 'category': 'Dairy', 'stock': 100},
    {'id': '8', 'name': 'Coconut Water Fresh', 'price': 50, 'unit': 'piece', 'category': 'Beverages', 'stock': 80},
    {'id': '9', 'name': 'Organic Honey Pure', 'price': 350, 'unit': 'bottle', 'category': 'Groceries', 'stock': 25},
    {'id': '10', 'name': 'Fresh Paneer Farm', 'price': 140, 'unit': 'packet', 'category': 'Dairy', 'stock': 35},
  ];

  static List<Map<String, dynamic>> cartItems = [];
  static List<Map<String, dynamic>> localOrdersCache = [];

  static void addToCart(Map<String, dynamic> product) {
    var existing = cartItems.indexWhere((item) => item['id'] == product['id']);
    if (existing >= 0) {
      cartItems[existing]['qty'] = (cartItems[existing]['qty'] ?? 1) + 1;
    } else {
      var newItem = Map<String, dynamic>.from(product);
      newItem['qty'] = 1;
      cartItems.add(newItem);
    }
  }

  static void removeFromCart(String id) {
    cartItems.removeWhere((item) => item['id'] == id);
  }

  static double getCartTotal() {
    double total = 0;
    for (var item in cartItems) {
      total += (item['price'] * (item['qty'] ?? 1));
    }
    return total;
  }
}

// ==========================================
// 2. मेन एप एंट्री पॉइंट (Main App Entry)
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init warning: $e");
  }
  runApp(const CakeAppEnterpriseApp());
}

class CakeAppEnterpriseApp extends StatelessWidget {
  const CakeAppEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart Enterprise',
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

// ==========================================
// 3. मेन हब स्क्रीन (Main Hub Screen)
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
    const RiderDeliveryScreen(),
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
      body: IndexedStack(index: _selectedTabIndex > 3 ? 3 : _selectedTabIndex, children: _tabScreens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedTabIndex = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Delivery'),
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

// ==========================================
// 4. बायर मार्केटप्लेस व्यू (Buyer Marketplace View)
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String _selectedFilterCat = 'All';
  final List<String> _categories = ['All', 'Fresh Fruits', 'Vegetables', 'Dry Fruits', 'Dairy', 'Beverages', 'Groceries'];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedProducts = CakeDatabase.dummyProducts;
    if (_selectedFilterCat != 'All') {
      displayedProducts = CakeDatabase.dummyProducts.where((p) => p['category'] == _selectedFilterCat).toList();
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                String cat = _categories[index];
                bool isSelected = _selectedFilterCat == cat;
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 12 : 6, right: index == _categories.length - 1 ? 12 : 0),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: Colors.green.shade100,
                    labelStyle: TextStyle(color: isSelected ? Colors.green.shade900 : Colors.black87),
                    onSelected: (bool selected) {
                      setState(() => _selectedFilterCat = cat);
                    },
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: displayedProducts.length,
            itemBuilder: (context, index) {
              var product = displayedProducts[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                        width: double.infinity,
                        child: const Icon(Icons.shopping_basket, size: 45, color: Colors.green),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('₹${product['price']} / ${product['unit']}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 30,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: EdgeInsets.zero),
                              onPressed: () {
                                CakeDatabase.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🛒 ${product['name']} कार्ट में जोड़ दिया गया!'), duration: const Duration(milliseconds: 800)));
                                setState(() {});
                              },
                              child: const Text('कार्ट में डालें', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 5. कार्ट और ऑर्डर्स व्यू (Cart & Orders View)
// ==========================================
class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  bool _isCheckingOut = false;

  Future<void> _placeOrderToFirebase() async {
    if (CakeDatabase.cartItems.isEmpty) return;

    setState(() => _isCheckingOut = true);
    try {
      final orderData = {
        'customerName': CakeDatabase.currentCustomerName,
        'phone': CakeDatabase.currentUserPhone,
        'address': CakeDatabase.currentDeliveryAddress,
        'items': CakeDatabase.cartItems,
        'total': CakeDatabase.getCartTotal(),
        'status': 'Pending',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/customer_orders.json'),
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        CakeDatabase.localOrdersCache.insert(0, orderData);
        CakeDatabase.cartItems.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 आर्डर सफलतापूर्वक प्लेस हो गया और वेंडर को भेज दिया गया!'), backgroundColor: Colors.green));
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Order place error: $e");
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: '🛍️ मेरी कार्ट (Cart)'),
                Tab(text: '📋 मेरे ऑर्डर्स (Orders)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                CakeDatabase.cartItems.isEmpty
                    ? const Center(child: Text('आपकी कार्ट खाली है!', style: TextStyle(color: Colors.grey)))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: CakeDatabase.cartItems.length,
                              itemBuilder: (context, index) {
                                var item = CakeDatabase.cartItems[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('₹${item['price']} x ${item['qty']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          CakeDatabase.removeFromCart(item['id']);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('कुल योग: ₹${CakeDatabase.getCartTotal()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                                  onPressed: _isCheckingOut ? null : _placeOrderToFirebase,
                                  child: _isCheckingOut ? const CircularProgressIndicator(color: Colors.white) : const Text('ऑर्डर प्लेस करें'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                CakeDatabase.localOrdersCache.isEmpty
                    ? const Center(child: Text('कोई आर्डर नहीं मिला।', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: CakeDatabase.localOrdersCache.length,
                        itemBuilder: (context, index) {
                          var ord = CakeDatabase.localOrdersCache[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text('ग्राहक: ${ord['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('रकम: ₹${ord['total']} | पता: ${ord['address']}'),
                              trailing: const Chip(label: Text('Pending', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green),
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

// ==========================================
// 6. वेंडर ऑथेंटिकेशन और ऑटो-पोलिंग डैशबोर्ड
// ==========================================
class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  int _viewMode = 0;

  final regShopNameCtrl = TextEditingController();
  final regPhoneCtrl = TextEditingController();
  final regAddressCtrl = TextEditingController();
  final regPass1Ctrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();

  final loginPhoneCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();

  final adminCodeCtrl = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> _vendorLiveOrders = [];
  bool _isFetchingOrders = false;
  Timer? _autoPollTimer;

  @override
  void dispose() {
    _autoPollTimer?.cancel();
    regShopNameCtrl.dispose();
    regPhoneCtrl.dispose();
    regAddressCtrl.dispose();
    regPass1Ctrl.dispose();
    regPass2Ctrl.dispose();
    loginPhoneCtrl.dispose();
    loginPassCtrl.dispose();
    adminCodeCtrl.dispose();
    super.dispose();
  }

  void _startAutoPolling() {
    _autoPollTimer?.cancel();
    // हर 10 सेकंड में ऑटोमैटिक नया आर्डर फेच करेगा
    _autoPollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchSingleLatestOrderAutomatic();
    });
  }

  Future<void> _fetchSingleLatestOrderManual() async {
    setState(() => _isFetchingOrders = true);
    await _fetchLatestOrderInternal(showNotification: true);
    if (mounted) setState(() => _isFetchingOrders = false);
  }

  Future<void> _fetchSingleLatestOrderAutomatic() async {
    await _fetchLatestOrderInternal(showNotification: false);
  }

  Future<void> _fetchLatestOrderInternal({required bool showNotification}) async {
    try {
      final response = await http.get(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/customer_orders.json?orderBy="\$key"&limitToLast=1'),
      );

      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        data.forEach((key, value) {
          var order = Map<String, dynamic>.from(value);
          order['orderId'] = key;
          
          bool exists = _vendorLiveOrders.any((el) => el['orderId'] == key);
          if (!exists) {
            if (mounted) {
              setState(() {
                _vendorLiveOrders.insert(0, order);
              });
            }
            if (showNotification && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔔 1 नया ऑर्डर सफलतापूर्वक फेच और सेव कर लिया गया!'), backgroundColor: Colors.green));
            } else if (!showNotification && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔔 नया ऑर्डर आ गया है!'), duration: Duration(seconds: 2), backgroundColor: Colors.green),
              );
            }
          } else {
            if (showNotification && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ℹ️ कोई नया आर्डर उपलब्ध नहीं है (कैचे अप-टू-डेट है)।')));
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Smart fetch error: $e");
    }
  }

  Future<void> _submitRegistration() async {
    if (regPhoneCtrl.text.trim().length < 10 || regShopNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया दुकान का नाम और सही मोबाइल नंबर भरें!'), backgroundColor: Colors.red));
      return;
    }
    if (regPass1Ctrl.text.isEmpty || regPass1Ctrl.text != regPass2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ पासवर्ड मेल नहीं खा रहे हैं!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var shopData = {
        'name': regShopNameCtrl.text.trim(),
        'phone': regPhoneCtrl.text.trim(),
        'address': regAddressCtrl.text.trim().isEmpty ? 'Faridabad' : regAddressCtrl.text.trim(),
        'pass': regPass1Ctrl.text.trim(),
        'status': 'pending',
      };

      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'),
        body: json.encode(shopData),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⏳ रिक्वेस्ट सबमिट हो गई'),
            content: const Text('आपकी दुकान का रजिस्ट्रेशन हो गया है। मास्टर एडमिन (तरुण) द्वारा अप्रूव होने के बाद ही आप लॉगिन कर पाएंगे।'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _viewMode = 0);
                },
                child: const Text('ठीक है'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginVendor() async {
    String phone = loginPhoneCtrl.text.trim();
    String pass = loginPassCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया मोबाइल नंबर और पासवर्ड दर्ज करें!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'));
      bool isApproved = false;

      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        data.forEach((key, val) {
          if (val['phone'] == phone && val['pass'] == pass && val['status'] == 'approved') {
            isApproved = true;
          }
        });
      }

      if (isApproved) {
        setState(() => _viewMode = 3);
        _startAutoPolling(); // लॉगिन होते ही 10 सेकंड की ऑटो-पोलिंग शुरू
        _fetchSingleLatestOrderManual(); // तुरंत पहला फेच करें
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ लॉगिन असफल'),
              content: const Text('दुकान अभी तक मास्टर एडमिन द्वारा अप्रूव नहीं की गई है!'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है'))],
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyAdminCode() {
    if (adminCodeCtrl.text.trim() == 'tarun#1') {
      setState(() => _viewMode = 5);
      adminCodeCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ गलत गुप्त कोड!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode == 0) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 75, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🛍️ वेंडर पोर्टल', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: () => setState(() => _viewMode = 1),
                icon: const Icon(Icons.person_add),
                label: const Text('नई दुकान रजिस्टर करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green, width: 2), foregroundColor: Colors.green.shade800),
                onPressed: () => setState(() => _viewMode = 2),
                icon: const Icon(Icons.login),
                label: const Text('वेंडर लॉगिन', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const Spacer(),
            const Divider(),
            TextButton.icon(
              onPressed: () => setState(() => _viewMode = 4),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.green),
              label: const Text('मास्टर शॉप अप्रूवल डैशबोर्ड (Admin)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 1) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            const Center(child: Text('📝 नया वेंडर रजिस्ट्रेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            TextField(controller: regShopNameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 15),
            TextField(controller: regPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: regAddressCtrl, decoration: const InputDecoration(labelText: 'दुकान का पता', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 15),
            TextField(controller: regPass1Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 15),
            TextField(controller: regPass2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड दोबारा दर्ज करें', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _submitRegistration,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('सबमिट करें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    if (_viewMode == 2) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 65, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🔐 वेंडर लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            TextField(controller: loginPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: loginPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _loginVendor,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('लॉगिन करें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    // वेंडर डैशबोर्ड (Auto-Polling Every 10 Seconds & Local Save)
    if (_viewMode == 3) {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Text('🟢 वेंडर डैशबोर्ड (Auto-Polling Active)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _autoPollTimer?.cancel();
                      setState(() => _viewMode = 0);
                    },
                    child: const Text('लॉग आउट', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
              ),
            ),
            const Material(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
                tabs: [
                  Tab(text: '📥 लाइव ऑर्डर्स (Auto 10s)'),
                  Tab(text: '📦 प्रोडक्ट्स'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            onPressed: _isFetchingOrders ? null : _fetchSingleLatestOrderManual,
                            icon: const Icon(Icons.download, size: 18),
                            label: _isFetchingOrders ? const CircularProgressIndicator(color: Colors.white) : const Text('मैनुअल रिफ्रेश / 1 आर्डर फेच करें'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _vendorLiveOrders.isEmpty
                              ? const Center(child: Text('नए आर्डर्स का इंतज़ार है... (हर 10 सेकंड में ऑटो-चेक हो रहा है)', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center))
                              : ListView.builder(
                                  itemCount: _vendorLiveOrders.length,
                                  itemBuilder: (context, index) {
                                    var order = _vendorLiveOrders[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text('ग्राहक: ${order['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('रकम: ₹${order['total']} | पता: ${order['address']}'),
                                        trailing: const Chip(label: Text('Saved Locally', style: TextStyle(fontSize: 9, color: Colors.white)), backgroundColor: Colors.green),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const Center(child: Text('📦 वेंडर प्रोडक्ट स्टॉक मैनेज करें', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 4) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 65, color: Colors.green),
            const SizedBox(height: 16),
            const Text('मास्टर एडमिन वेरिफिकेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: adminCodeCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'गुप्त कोड (tarun#1)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.key))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _verifyAdminCode,
                child: const Text('वेरिफ़ाई करें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← रद्द करें', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    if (_viewMode == 5) {
      return FutureBuilder<http.Response>(
        future: http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          Map<String, dynamic> requests = {};
          if (snapshot.data!.body != 'null' && snapshot.data!.body.isNotEmpty) {
            requests = json.decode(snapshot.data!.body);
          }

          List<MapEntry<String, dynamic>> pendingList = requests.entries.where((e) => e.value['status'] == 'pending').toList();

          return Column(
            children: [
              Container(
                color: Colors.green.shade100,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Text('👑 मास्टर एडमिन अप्रूवल हब', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('बंद करें')),
                  ],
                ),
              ),
              Expanded(
                child: pendingList.isEmpty
                    ? const Center(child: Text('कोई पेंडिंग रिक्वेस्ट नहीं है।'))
                    : ListView.builder(
                        itemCount: pendingList.length,
                        itemBuilder: (context, index) {
                          var entry = pendingList[index];
                          var data = entry.value;
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('फोन: ${data['phone']}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () async {
                                  await http.patch(
                                    Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests/${entry.key}.json'),
                                    body: json.encode({'status': 'approved'}),
                                  );
                                  setState(() {});
                                },
                                child: const Text('अप्रूव करें'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ==========================================
// 7. राइडर डिलीवरी व्यू डमी (Rider Delivery Screen)
// ==========================================
class RiderDeliveryScreen extends StatelessWidget {
  const RiderDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('🛵 राइडर डिलीवरी ट्रैकिंग पोर्टल', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
