import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========================================================================
// 1. DATA MODELS & FIREBASE REST CONFIGURATION
// =========================================================================
class ViziagDatabase {
  static const String firebaseUrl = 'https://viziagmart-default-rtdb.firebaseio.com';

  static String currentCustomerName = 'Tarun Kumar';
  static String currentUserPhone = '9971968060';
  static String currentDeliveryAddress = 'Faridabad Hub, Haryana';

  static List<Map<String, dynamic>> cartItems = [];
  static List<Map<String, dynamic>> vendorRequests = [];

  // Sabzi, Fruits & Grocery Catalog (No food license items)
  static List<Map<String, dynamic>> localProductsCache = [
    {
      'id': 'g1',
      'name': 'Fresh Potato (Aloo) - 1kg',
      'price': 30,
      'shop': 'Faridabad Fresh Mandi',
      'category': 'Vegetables',
      'image': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500',
    },
    {
      'id': 'g2',
      'name': 'Fresh Onion (Pyaz) - 1kg',
      'price': 40,
      'shop': 'Faridabad Fresh Mandi',
      'category': 'Vegetables',
      'image': 'https://images.unsplash.com/photo-1508747703725-719777637510?w=500',
    },
    {
      'id': 'g3',
      'name': 'Fresh Tomato (Tamatar) - 1kg',
      'price': 35,
      'shop': 'Green Sabzi Hub',
      'category': 'Vegetables',
      'image': 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=500',
    },
    {
      'id': 'g4',
      'name': 'Banana (Kela) - 1 Dozen',
      'price': 60,
      'shop': 'Daily Fruits Stalls',
      'category': 'Fruits',
      'image': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500',
    },
    {
      'id': 'g5',
      'name': 'Aashirvaad Atta - 5kg',
      'price': 240,
      'shop': 'Viziag Grocery Store',
      'category': 'Grocery',
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
    },
    {
      'id': 'g6',
      'name': 'Fortune Basmati Rice - 1kg',
      'price': 110,
      'shop': 'Viziag Grocery Store',
      'category': 'Grocery',
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
    }
  ];

  // Fetch Vendors from Firebase Realtime Database
  static Future<void> fetchVendorsFromFirebase() async {
    try {
      final response = await http.get(Uri.parse('$firebaseUrl/vendor_requests.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> loadedList = [];
        data.forEach((key, value) {
          var mapVal = Map<String, dynamic>.from(value);
          mapVal['firebaseKey'] = key; // Save push key for updating status
          loadedList.add(mapVal);
        });
        vendorRequests = loadedList;
      } else {
        vendorRequests = [];
      }
    } catch (e) {
      debugPrint('Error fetching vendors: $e');
    }
  }

  // Register New Vendor to Firebase
  static Future<bool> registerVendorToFirebase(Map<String, dynamic> vendorData) async {
    try {
      final response = await http.post(
        Uri.parse('$firebaseUrl/vendor_requests.json'),
        body: json.encode(vendorData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error registering vendor: $e');
      return false;
    }
  }

  // Update Vendor Status to Approved in Firebase
  static Future<bool> updateVendorStatusInFirebase(String firebaseKey, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$firebaseUrl/vendor_requests/$firebaseKey.json'),
        body: json.encode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating vendor status: $e');
      return false;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ViziagDatabase.fetchVendorsFromFirebase();
  runApp(const ViziagMartApp());
}

class ViziagMartApp extends StatelessWidget {
  const ViziagMartApp({super.key});

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
      home: const ViziagMainHubScreen(),
    );
  }
}

// =========================================================================
// 2. MAIN HUB SCREEN (Tabs Controller)
// =========================================================================
class ViziagMainHubScreen extends StatefulWidget {
  const ViziagMainHubScreen({super.key});

  @override
  State<ViziagMainHubScreen> createState() => _ViziagMainHubScreenState();
}

class _ViziagMainHubScreenState extends State<ViziagMainHubScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    int totalCartCount = ViziagDatabase.cartItems.fold(0, (sum, item) => sum + ((item['qty'] as num?)?.toInt() ?? 1));

    final List<Widget> tabScreens = [
      MarketplaceBuyerView(onCartChanged: () => setState(() {})),
      const VendorAuthAndPortalView(),
      CartAndOrdersView(onCartChanged: () => setState(() {})),
    ];

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
                        Text(ViziagDatabase.currentCustomerName, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
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
      body: IndexedStack(index: _selectedTabIndex > 2 ? 2 : _selectedTabIndex, children: tabScreens),
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
        final nameCtrl = TextEditingController(text: ViziagDatabase.currentCustomerName);
        final phoneCtrl = TextEditingController(text: ViziagDatabase.currentUserPhone);
        final addressCtrl = TextEditingController(text: ViziagDatabase.currentDeliveryAddress);
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
                  ViziagDatabase.currentCustomerName = nameCtrl.text.trim();
                  ViziagDatabase.currentUserPhone = phoneCtrl.text.trim();
                  ViziagDatabase.currentDeliveryAddress = addressCtrl.text.trim();
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

// =========================================================================
// 3. MARKETPLACE BUYER VIEW (Shop & Products Catalog)
// =========================================================================
class MarketplaceBuyerView extends StatefulWidget {
  final VoidCallback onCartChanged;
  const MarketplaceBuyerView({super.key, required this.onCartChanged});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    var filteredList = ViziagDatabase.localProductsCache.where((item) {
      final name = item['name'].toString().toLowerCase();
      final shop = item['shop'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || shop.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search vegetables, fruits or grocery...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: filteredList.isEmpty
              ? const Center(child: Text('No products found matching your search.', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    var product = filteredList[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: Image.network(
                                product['image'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.shopping_basket, color: Colors.grey)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(product['shop'], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${product['price']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13)),
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                        onPressed: () {
                                          setState(() {
                                            bool found = false;
                                            for (var cartItem in ViziagDatabase.cartItems) {
                                              if (cartItem['id'] == product['id']) {
                                                cartItem['qty'] = (cartItem['qty'] ?? 1) + 1;
                                                found = true;
                                                break;
                                              }
                                            }
                                            if (!found) {
                                              ViziagDatabase.cartItems.add({...product, 'qty': 1});
                                            }
                                          });
                                          widget.onCartChanged();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${product['name']} added to cart!'), duration: const Duration(milliseconds: 600)),
                                          );
                                        },
                                        child: const Text('Add', style: TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                  ],
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

// =========================================================================
// 4. CART & ORDERS VIEW
// =========================================================================
class CartAndOrdersView extends StatefulWidget {
  final VoidCallback onCartChanged;
  const CartAndOrdersView({super.key, required this.onCartChanged});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  int get _cartTotal {
    return ViziagDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1) as int));
  }

  void _placeOrder() {
    if (ViziagDatabase.cartItems.isEmpty) return;

    setState(() {
      ViziagDatabase.cartItems.clear();
    });
    widget.onCartChanged();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Order Placed Successfully!'),
        content: const Text('Your grocery/vegetable order has been confirmed and sent to the hub.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ViziagDatabase.cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text('Your cart is empty!', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: ViziagDatabase.cartItems.length,
            itemBuilder: (context, index) {
              var item = ViziagDatabase.cartItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Image.network(item['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.shopping_basket)),
                  title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${item['price']} x ${item['qty']} = ₹${(item['price'] * item['qty'])}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            if (item['qty'] > 1) {
                              item['qty']--;
                            } else {
                              ViziagDatabase.cartItems.removeAt(index);
                            }
                          });
                          widget.onCartChanged();
                        },
                      ),
                      Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            item['qty']++;
                          });
                          widget.onCartChanged();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹$_cartTotal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: _placeOrder,
                  child: const Text('Place Order Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// 5. VENDOR AUTH, PORTAL & ADMIN APPROVAL VIEW (FIREBASE SYNCED)
// =========================================================================
class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  int _viewMode = 0; // 0: Home, 1: Register, 2: Login, 3: Vendor Dash, 4: Admin Code, 5: Admin Panel
  bool _isLoading = false;

  final regShopNameCtrl = TextEditingController();
  final regPhoneCtrl = TextEditingController();
  final regAddressCtrl = TextEditingController();
  final regPass1Ctrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();

  final loginPhoneCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();
  final adminCodeCtrl = TextEditingController();

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

    var newShop = {
      'name': regShopNameCtrl.text.trim(),
      'phone': regPhoneCtrl.text.trim(),
      'address': regAddressCtrl.text.trim().isEmpty ? 'Faridabad' : regAddressCtrl.text.trim(),
      'pass': regPass1Ctrl.text.trim(),
      'status': 'pending',
    };

    bool success = await ViziagDatabase.registerVendorToFirebase(newShop);
    await ViziagDatabase.fetchVendorsFromFirebase();

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⏳ रिक्वेस्ट सबमिट हो गई'),
            content: const Text('आपकी दुकान Firebase पर रजिस्टर हो गई है। अब एडमिन पैनल (tarun#1) में जाकर इसे अप्रूव करें।'),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ इंटरनेट या Firebase कनेक्शन एरर!'), backgroundColor: Colors.red));
      }
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
    await ViziagDatabase.fetchVendorsFromFirebase();
    setState(() => _isLoading = false);

    bool isApproved = false;
    for (var shop in ViziagDatabase.vendorRequests) {
      if (shop['phone'] == phone && shop['pass'] == pass && shop['status'] == 'approved') {
        isApproved = true;
        break;
      }
    }

    if (isApproved) {
      setState(() => _viewMode = 3);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ स्वागत है! वेंडर डैशबोर्ड लाइव है।'), backgroundColor: Colors.green));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ लॉगिन असफल (Not Approved)'),
          content: const Text('आपकी दुकान अभी तक एडमिन द्वारा अप्रूव नहीं की गई है या पासवर्ड गलत है!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है')),
          ],
        ),
      );
    }
  }

  void _verifyAdminCode() {
    if (adminCodeCtrl.text.trim() == 'tarun#1') {
      setState(() => _viewMode = 5);
      adminCodeCtrl.clear();
      // Load latest pending requests from Firebase
      _refreshAdminData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ गलत गुप्त कोड! (सही कोड: tarun#1)'), backgroundColor: Colors.red));
    }
  }

  Future<void> _refreshAdminData() async {
    setState(() => _isLoading = true);
    await ViziagDatabase.fetchVendorsFromFirebase();
    setState(() => _isLoading = false);
  }

  Future<void> _approveShop(String firebaseKey) async {
    setState(() => _isLoading = true);
    bool success = await ViziagDatabase.updateVendorStatusInFirebase(firebaseKey, 'approved');
    await ViziagDatabase.fetchVendorsFromFirebase();
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ दुकान Firebase पर सफलतापूर्वक अप्रूव हो गई!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ अप्रूवल अपडेट करने में दिक्कत आई।'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_viewMode == 0) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 75, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🛍️ वेंडर पोर्टल (Firebase Live)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('सब्जी, फल और ग्रोसरी विक्रेता पंजीकरण और लाइव एडमिन अप्रूवल', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: () => setState(() => _viewMode = 1),
                icon: const Icon(Icons.person_add),
                label: const Text('नई दुकान रजिस्टर करें (New Registration)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                label: const Text('वेंडर लॉगिन (Existing Vendor Login)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            TextField(controller: regShopNameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम (Shop Name)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 15),
            TextField(controller: regPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: regAddressCtrl, decoration: const InputDecoration(labelText: 'दुकान का पता / लोकेशन', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 15),
            TextField(controller: regPass1Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड बनाएं', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 15),
            TextField(controller: regPass2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड दोबारा दर्ज करें', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _submitRegistration,
                child: const Text('फायरबेस पर सबमिट करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            const SizedBox(height: 5),
            const Text('एडमिन से अप्रूव होना अनिवार्य है', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                onPressed: _loginVendor,
                child: const Text('लॉगिन करें ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    if (_viewMode == 3) {
      return Column(
        children: [
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('🟢 वेंडर डैशबोर्ड (Firebase Live)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _viewMode = 0),
                  child: const Text('लॉग आउट', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('यहाँ वेंडर अपनी सब्जी/ग्रोसरी के प्रोडक्ट्स और ऑर्डर्स मैनेज कर सकता है।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    if (_viewMode == 4) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 65, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🔐 मास्टर एडमिन वेरिफिकेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: adminCodeCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'गुप्त कोड दर्ज करें (Admin Code: tarun#1)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _verifyAdminCode,
                child: const Text('वेरीफाई करें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    // Admin Dashboard for Approving Shops from Firebase
    var pendingList = ViziagDatabase.vendorRequests.where((s) => s['status'] == 'pending').toList();

    return Column(
      children: [
        AppBar(
          title: const Text('Master Shop Approval (Live)'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _viewMode = 0),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshAdminData,
            ),
          ],
        ),
        Expanded(
          child: pendingList.isEmpty
              ? const Center(
                  child: Text(
                    'कोई नई दुकान अप्रूवल के लिए पेंडिंग नहीं है!',
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: pendingList.length,
                  itemBuilder: (context, index) {
                    var shop = pendingList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(shop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Phone: ${shop['phone']}\nAddress: ${shop['address']}'),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => _approveShop(shop['firebaseKey']),
                          child: const Text('Approve'),
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
