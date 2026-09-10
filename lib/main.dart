import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ==========================================
// 🗄️ CAKE DATABASE & GLOBAL STATE
// ==========================================
class CakeDatabase {
  static String firebaseRestUrl = "https://viziag-mart-default-rtdb.firebaseio.com";
  static String currentCustomerName = "Tarun Kumar";
  static String currentUserPhone = "9971968060";
  static String currentDeliveryAddress = "Faridabad, Haryana";
  
  static List<Map<String, dynamic>> cartItems = [];
  
  static final List<Map<String, dynamic>> initialProducts = [
    {
      'id': 'p1',
      'name': 'Chocolate Truffle Cake',
      'price': 650,
      'category': 'Cakes',
      'image': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500',
      'description': 'Rich dark chocolate truffle layered with soft sponge.'
    },
    {
      'id': 'p2',
      'name': 'Red Velvet Cake',
      'price': 750,
      'category': 'Cakes',
      'image': 'https://images.unsplash.com/photo-1586788680434-30d324b2d46f?w=500',
      'description': 'Classic red velvet with cream cheese frosting.'
    },
    {
      'id': 'p3',
      'name': 'Fresh Fruit Gateaux',
      'price': 800,
      'category': 'Cakes',
      'image': 'https://images.unsplash.com/photo-1535141192574-5d4897c13136?w=500',
      'description': 'Loaded with fresh seasonal exotic fruits.'
    },
    {
      'id': 'p4',
      'name': 'Black Forest Delight',
      'price': 600,
      'category': 'Cakes',
      'image': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500',
      'description': 'Traditional German chocolate sponge with cherries.'
    }
  ];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
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

// ==========================================
// 📱 MAIN HUB SCREEN
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
// 🛍️ MARKETPLACE BUYER VIEW
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    var filtered = CakeDatabase.initialProducts.where((p) {
      return p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search delicious cakes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade200,
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              var product = filtered[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(product['image'], width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.cake, color: Colors.grey))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                          const SizedBox(height: 2),
                          Text('₹${product['price']}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 30,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: EdgeInsets.zero),
                              onPressed: () {
                                setState(() {
                                  var existing = CakeDatabase.cartItems.firstWhere((item) => item['id'] == product['id'], orElse: () => {});
                                  if (existing.isNotEmpty) {
                                    existing['qty'] = (existing['qty'] ?? 1) + 1;
                                  } else {
                                    CakeDatabase.cartItems.add({...product, 'qty': 1});
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🛒 Added to Cart!'), duration: Duration(milliseconds: 800)));
                              },
                              child: const Text('Add to Cart', style: TextStyle(fontSize: 11)),
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
// 🛒 CART & ORDERS VIEW
// ==========================================
class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  bool _isCheckingOut = false;

  double get _cartTotal {
    return CakeDatabase.cartItems.fold(0.0, (sum, item) => sum + ((item['price'] as num).toDouble() * ((item['qty'] as num?)?.toDouble() ?? 1.0)));
  }

  Future<void> _placeOrder() async {
    setState(() => _isCheckingOut = true);
    try {
      String orderId = "ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      var orderData = {
        'orderId': orderId,
        'customerName': CakeDatabase.currentCustomerName,
        'customerPhone': CakeDatabase.currentUserPhone,
        'deliveryAddress': CakeDatabase.currentDeliveryAddress,
        'items': CakeDatabase.cartItems,
        'grandTotal': _cartTotal,
        'orderStatus': 'Out for Delivery', // ताकि तुरंत राइडर को दिखे
        'status': 'Out for Delivery',
        'timestamp': ServerValue.timestamp,
      };

      await FirebaseDatabase.instance.ref('orders').push().set(orderData);
      
      setState(() {
        CakeDatabase.cartItems.clear();
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Order Placed Successfully!'),
            content: Text('Your Order ID is #$orderId. Assigned to delivery rider instantly.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (CakeDatabase.cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text('Your cart is empty!', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: CakeDatabase.cartItems.length,
            itemBuilder: (context, index) {
              var item = CakeDatabase.cartItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${item['price']} x ${item['qty']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            if ((item['qty'] ?? 1) > 1) {
                              item['qty'] -= 1;
                            } else {
                              CakeDatabase.cartItems.removeAt(index);
                            }
                          });
                        },
                      ),
                      Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            item['qty'] = (item['qty'] ?? 1) + 1;
                          });
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
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹$_cartTotal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: _isCheckingOut ? null : _placeOrder,
                  child: _isCheckingOut ? const CircularProgressIndicator(color: Colors.white) : const Text('Place Order Now ➔', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🔐 VENDOR PORTAL & ADMIN DASHBOARD VIEW
// ==========================================
class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  int _viewMode = 0; // 0: Hub, 1: Register, 2: Login, 3: Dashboard, 4: Admin Code, 5: Admin Panel

  final regShopNameCtrl = TextEditingController();
  final regPhoneCtrl = TextEditingController();
  final regAddressCtrl = TextEditingController();
  final regPass1Ctrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();

  final loginPhoneCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();
  final adminCodeCtrl = TextEditingController();

  bool _isLoading = false;

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
            content: const Text('आपकी दुकान का रजिस्ट्रेशन हो गया है। मास्टर एडमिन द्वारा अप्रूव होने के बाद ही आप लॉगिन कर पाएंगे।'),
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
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ लॉगिन असफल (Not Approved)'),
              content: const Text('आपकी दुकान अभी तक मास्टर एडमिन द्वारा अप्रूव नहीं की गई है!'),
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
                label: const Text('नई दुकान रजिस्टर करें (New Registration)'),
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
                label: const Text('वेंडर लॉगिन (Existing Vendor Login)'),
              ),
            ),
            const Spacer(),
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
            const Center(child: Text('📝 नया वेंडर रजिस्ट्रेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            TextField(controller: regShopNameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: regPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '')),
            const SizedBox(height: 15),
            TextField(controller: regAddressCtrl, decoration: const InputDecoration(labelText: 'दुकान का पता', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: regPass1Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड बनाएं', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: regPass2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड दोबारा दर्ज करें', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
              onPressed: _isLoading ? null : _submitRegistration,
              child: const Text('अप्रूवल के लिए सबमिट करें'),
            ),
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
            const Text('🔐 वेंडर लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: loginPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '')),
            const SizedBox(height: 15),
            TextField(controller: loginPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
              onPressed: _isLoading ? null : _loginVendor,
              child: const Text('लॉगिन करें'),
            ),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    if (_viewMode == 3) {
      return Column(
        children: [
          AppBar(
            title: const Text('वेंडर डैशबोर्ड (Live Orders)'),
            backgroundColor: Colors.green.shade700,
            automaticallyImplyLeading: false,
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => setState(() => _viewMode = 0))],
          ),
          const Expanded(child: VendorLiveOrdersTab()),
        ],
      );
    }

    if (_viewMode == 4) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 70, color: Colors.green),
            const SizedBox(height: 15),
            const Text('मास्टर एडमिन वेरिफिकेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: adminCodeCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'गुप्त एडमिन कोड दर्ज करें', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
              onPressed: _verifyAdminCode,
              child: const Text('वेरिफाई करें'),
            ),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    return Column(
      children: [
        AppBar(
          title: const Text('मास्टर अप्रूवल पैनल'),
          backgroundColor: Colors.green.shade700,
          automaticallyImplyLeading: false,
          actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => setState(() => _viewMode = 0))],
        ),
        const Expanded(child: AdminApprovalListTab()),
      ],
    );
  }
}

class VendorLiveOrdersTab extends StatefulWidget {
  const VendorLiveOrdersTab({super.key});
  @override
  State<VendorLiveOrdersTab> createState() => _VendorLiveOrdersTabState();
}

class _VendorLiveOrdersTabState extends State<VendorLiveOrdersTab> {
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
          if (val is Map) {
            var item = Map<String, dynamic>.from(val);
            item['firebaseKey'] = key;
            list.add(item);
          }
        });
        setState(() => allOrders = list.reversed.toList());
      } else {
        setState(() => allOrders = []);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String firebaseKey, String newStatus) async {
    await http.patch(
      Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$firebaseKey.json'),
      body: json.encode({'status': newStatus, 'orderStatus': newStatus}),
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
            label: const Text('आर्डर्स रिफ्रेश करें'),
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
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text('ग्राहक: ${ord['customerName'] ?? 'कस्टमर'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        subtitle: Text('मोबाइल: ${ord['customerPhone'] ?? ''}\nपता: ${ord['deliveryAddress'] ?? ''}\nराशि: ₹${ord['grandTotal'] ?? 0}\nस्टेटस: ${ord['status'] ?? 'Pending'}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) => _updateStatus(ord['firebaseKey'], val),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Accepted ✅', child: Text('Accept')),
                            const PopupMenuItem(value: 'Out for Delivery 🛵', child: Text('Out for Delivery')),
                            const PopupMenuItem(value: 'Delivered 🎉', child: Text('Deliver')),
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

class AdminApprovalListTab extends StatefulWidget {
  const AdminApprovalListTab({super.key});
  @override
  State<AdminApprovalListTab> createState() => _AdminApprovalListTabState();
}

class _AdminApprovalListTabState extends State<AdminApprovalListTab> {
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'));
    if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
      Map<String, dynamic> data = json.decode(res.body);
      List<Map<String, dynamic>> list = [];
      data.forEach((key, val) {
        if (val is Map) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          list.add(item);
        }
      });
      setState(() => requests = list);
    }
  }

  Future<void> _approveVendor(String key) async {
    await http.patch(
      Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests/$key.json'),
      body: json.encode({'status': 'approved'}),
    );
    _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var req = requests[index];
        bool isApproved = req['status'] == 'approved';
        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            title: Text(req['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Phone: ${req['phone']}\nStatus: ${req['status']}'),
            trailing: isApproved
                ? const Text('Approved ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                    onPressed: () => _approveVendor(req['firebaseKey']),
                    child: const Text('Approve'),
                  ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 🛵 RIDER DELIVERY SCREEN (FULLY DETAILED)
// ==========================================
class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({Key? key}) : super(key: key);

  @override
  _RiderDeliveryScreenState createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  
  bool _isCheckingSession = true;
  bool _isRegistered = false;
  bool _isLoading = false;

  Map<String, dynamic> _currentOrder = {};
  bool _isLoadingOrder = true;
  String _activeRiderPhone = '';
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _vibrationTimer;
  StreamSubscription<DatabaseEvent>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _checkSavedRider();
  }

  Future<void> _checkSavedRider() async {
    final prefs = await SharedPreferences.getInstance();
    String savedPhone = prefs.getString('saved_rider_phone') ?? '';

    if (savedPhone.isNotEmpty) {
      setState(() {
        _activeRiderPhone = savedPhone;
        _isRegistered = true;
        _isCheckingSession = false;
      });
      _loadCachedOrderAndListen();
    } else {
      setState(() {
        _isRegistered = false;
        _isCheckingSession = false;
      });
    }
  }

  Future<void> _loadCachedOrderAndListen() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedOrderJson = prefs.getString('cached_active_order_$_activeRiderPhone');
    if (cachedOrderJson != null) {
      try {
        Map<String, dynamic> cachedMap = json.decode(cachedOrderJson);
        if (mounted) {
          setState(() {
            _currentOrder = cachedMap;
            _isLoadingOrder = false;
          });
        }
      } catch (_) {}
    }
    
    _startRealtimeOrderListener();
  }

  Future<void> _registerRider() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String phone = _phoneController.text.trim();
        String name = _nameController.text.trim();
        String vehicleNumber = _vehicleController.text.trim().toUpperCase();
        
        var riderData = {
          'name': name,
          'phone': phone,
          'vehicleNumber': vehicleNumber,
          'isReady': true,
        };

        await FirebaseDatabase.instance.ref('riders').push().set(riderData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_rider_phone', phone);

        if (mounted) {
          setState(() {
            _activeRiderPhone = phone;
            _isRegistered = true;
            _isLoading = false;
          });
          _loadCachedOrderAndListen();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 राइडर सफलतापूर्वक रजिस्टर हो गया!")),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ एरर: $e")),
          );
        }
      }
    }
  }

  void _startRealtimeOrderListener() {
    _orderSubscription?.cancel();
    DatabaseReference ordersRef = FirebaseDatabase.instance.ref('orders');

    _orderSubscription = ordersRef.onValue.listen((event) {
      final data = event.snapshot.value;
      Map<String, dynamic>? activeOrder;

      if (data != null && data is Map) {
        data.forEach((key, val) {
          if (val != null && val is Map) {
            String status = val['orderStatus']?.toString() ?? val['status']?.toString() ?? '';
            String rPhone = val['riderPhone']?.toString() ?? val['phone']?.toString() ?? '';
            
            // यदि आर्डर 'Out for Delivery' है (या इस राइडर को असाइंड है)
            if (status.contains('Out for Delivery')) {
              activeOrder = Map<String, dynamic>.from(val);
              activeOrder!['orderKey'] = key;
            }
          }
        });
      }

      if (mounted) {
        setState(() {
          bool wasEmpty = _currentOrder.isEmpty;
          _currentOrder = activeOrder ?? {};
          _isLoadingOrder = false;

          if (wasEmpty && _currentOrder.isNotEmpty) {
            _startAlertAndTimer();
          } else if (_currentOrder.isEmpty) {
            _stopAlertAndTimer();
          }
        });

        _saveOrderToCache();
      }
    });
  }

  Future<void> _saveOrderToCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentOrder.isNotEmpty) {
      prefs.setString('cached_active_order_$_activeRiderPhone', json.encode(_currentOrder));
    } else {
      prefs.remove('cached_active_order_$_activeRiderPhone');
    }
  }

  void _startAlertAndTimer() {
    _timer?.cancel();
    _vibrationTimer?.cancel();

    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopAlertAndTimer() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
  }

  @override
  void dispose() {
    _stopAlertAndTimer();
    _orderSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remSec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remSec.toString().padLeft(2, '0')}';
  }

  Future<void> _sendDetailsToWhatsApp() async {
    String customerName = _currentOrder['customerName'] ?? 'कस्टमर';
    String customerPhone = _currentOrder['customerPhone'] ?? '';
    String deliveryAddr = _currentOrder['deliveryAddress'] ?? _currentOrder['address'] ?? 'Faridabad';
    String orderId = _currentOrder['orderId'] ?? _currentOrder['orderKey']?.toString().substring(1) ?? '101';

    String message = '''
🛵 *डिफ़ॉल्ट डिलीवरी आर्डर* 🛵

📦 *ऑर्डर आईडी:* #$orderId
🔴 *डिलीवरी पता:* $deliveryAddr
👤 *ग्राहक:* $customerName
📞 *फोन:* $customerPhone

समय पर सुरक्षित डिलीवरी करें! 🚀
''';

    String targetPhone = _activeRiderPhone.isEmpty ? '9971968060' : _activeRiderPhone;
    String url = "https://wa.me/+91$targetPhone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (!_isRegistered) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("राइडर रजिस्ट्रेशन (Viziag Mart)", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green[700],
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "अपने डिलीवरी पार्टनर को यहाँ जोड़ें:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "राइडर का पूरा नाम", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    validator: (value) => value!.isEmpty ? 'कृपया नाम दर्ज करें' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(labelText: "मोबाइल नंबर", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone), counterText: ''),
                    validator: (value) => value!.length < 10 ? 'सही मोबाइल नंबर दर्ज करें' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(labelText: "गाड़ी/बाइक नंबर", border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_bike)),
                    validator: (value) => value!.isEmpty ? 'गाड़ी का नंबर दर्ज करें' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      onPressed: _isLoading ? null : _registerRider,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("राइडर रजिस्टर करें", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    bool hasOrder = _currentOrder.isNotEmpty;

    return Scaffold(
      backgroundColor: hasOrder ? Colors.red[900] : Colors.white,
      appBar: AppBar(
        title: Text("राइडर डैशबोर्ड ($_activeRiderPhone)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_rider_phone');
              setState(() => _isRegistered = false);
            },
          )
        ],
      ),
      body: _isLoadingOrder
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: hasOrder
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "🚨 नया डिलीवरी आर्डर आया है!",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatTime(_secondsElapsed),
                            style: const TextStyle(color: Colors.yellowAccent, fontSize: 45, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📦 आर्डर ID: #${_currentOrder['orderId'] ?? _currentOrder['orderKey'] ?? 'N/A'}",
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const Divider(thickness: 2),
                                    const SizedBox(height: 10),
                                    const Text("🔴 डिलीवरी पता:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                    Text(_currentOrder['deliveryAddress'] ?? _currentOrder['address'] ?? 'Faridabad',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 10),
                                    Text("👤 ग्राहक नाम: ${_currentOrder['customerName'] ?? 'कस्टमर'}", style: const TextStyle(color: Colors.black87)),
                                    Text("📞 फोन: ${_currentOrder['customerPhone'] ?? ''}", style: const TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _stopAlertAndTimer();
                              _sendDetailsToWhatsApp();
                            },
                            child: const Text(
                              "आर्डर स्वीकार करें & WhatsApp पर भेजें",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delivery_dining, size: 80, color: Colors.green[700]),
                            const SizedBox(height: 20),
                            const Text("स्वागत है, राइडर पार्टनर!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            const Text(
                              "रियलटाइम मोड एक्टिव है। नया आर्डर आते ही अपने आप स्क्रीन पर प्रकट हो जाएगा!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }
}
