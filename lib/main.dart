import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase init error: $e");
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
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B), 
          secondary: Color(0xFFEC4899), 
          surface: Color(0xFF1E293B), 
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const CakeMainHubScreen(),
    );
  }
}

class CakeDatabase {
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/"; 

  static String currentUserPhone = "9971968060";
  static String currentCustomerName = "Tarun Kumar";
  static String currentDeliveryAddress = "Sector 15A Faridabad";

  static Map<String, dynamic> bakeryShop = {
    'shopId': 'shop_cake_01',
    'shopName': 'Tarun Fruit & Vegetable Shop',
    'ownerName': 'Tarun Kumar',
    'ownerPhone': '9971968060',
    'ownerPhotoPath': '', 
    'bannerPhotoPath': '',
    'shopPhotoPath': '',
    'phone': '9971968060',
    'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
    'bio': 'ताज़ा फल, सब्जियां और उत्पाद उपलब्ध।',
    'isOpen': true,
  };

  static List<Map<String, dynamic>> productInventory = [
    {
      'id': 'p1',
      'name': 'Fresh Kashmiri Apples',
      'price': 120,
      'unit': 'Kg',
      'category': 'Fresh Fruits',
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500',
      'description': 'Crisp, sweet and juicy premium Kashmiri apples.',
      'inStock': true,
    },
    {
      'id': 'p2',
      'name': 'Organic Bananas',
      'price': 60,
      'unit': 'Dozen',
      'category': 'Fresh Fruits',
      'image': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500',
      'description': 'Farm fresh energy-rich yellow bananas.',
      'inStock': true,
    },
    {
      'id': 'p3',
      'name': 'Fresh Tomatoes',
      'price': 40,
      'unit': 'Kg',
      'category': 'Vegetables',
      'image': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500',
      'description': 'Juicy farm-picked red tomatoes.',
      'inStock': true,
    },
    {
      'id': 'p4',
      'name': 'Green Potatoes',
      'price': 30,
      'unit': 'Kg',
      'category': 'Vegetables',
      'image': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500',
      'description': 'Freshly harvested everyday staple potatoes.',
      'inStock': true,
    }
  ];

  static List<Map<String, dynamic>> cartItems = [];
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
                  'VIZIAG MART',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black87,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.store, size: 13),
                label: const Text('Shop', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.lock_outline, size: 13),
                label: const Text('Vendor', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 2),
                icon: const Icon(Icons.delivery_dining, size: 13),
                label: const Text('Rider', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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

  final List<String> categories = [
    'All',
    'Fresh Fruits',
    'Vegetables',
    'Organic Items',
    'Daily Essentials',
  ];

  @override
  void initState() {
    super.initState();
    _fetchShopProfileAndProducts();
  }

  @override
  void dispose() {
    for (var ctrl in _cakeMessageControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _qtyControllers.values) {
      ctrl.dispose();
    }
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
          'unit': prod['unit'] ?? 'Kg',
          'qty': qty,
          'cakeMessage': cakeMsg,
          'shopName': CakeDatabase.bakeryShop['shopName'],
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛒 Added $qty ${prod['unit'] ?? 'Kg'} $prodName to Cart!'), backgroundColor: const Color(0xFFF59E0B), duration: const Duration(milliseconds: 900)),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
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
                            Text(
                              shop['shopName'] ?? 'Tarun Fruit & Vegetable Shop',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFF59E0B)),
                            ),
                            const SizedBox(height: 3),
                            Text('👤 Owner: ${shop['ownerName'] ?? 'Tarun Kumar'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 2),
                            Text('📍 ${shop['address'] ?? 'Faridabad'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _fetchShopProfileAndProducts,
                        icon: const Icon(Icons.sync, color: Color(0xFFF59E0B)),
                        tooltip: 'Sync Shop & Products',
                      ),
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
              children: categories.map((category) {
                bool isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.black87 : Colors.white70)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF59E0B),
                    backgroundColor: const Color(0xFF1E293B),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: const Color(0xFFF59E0B),
                    side: BorderSide(color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade700),
                    onSelected: (bool selected) {
                      setState(() => selectedCategory = category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          if (_isLoadingCloud) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(color: Color(0xFFF59E0B)),
          ],
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              var prod = filteredProducts[index];
              String prodKey = prod['firebaseKey'] ?? prod['id'] ?? prod['name'] ?? index.toString();
              double unitPrice = (prod['price'] ?? 49.0).toDouble();
              String unitLabel = prod['unit'] ?? 'Kg';
              double currentQty = _itemQuantities[prodKey] ?? 1.0;

              _cakeMessageControllers.putIfAbsent(prodKey, () => TextEditingController());
              _qtyControllers.putIfAbsent(prodKey, () => TextEditingController(text: currentQty.toString()));

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: buildShopOrProdImage(prod['image'], 90, 90, Icons.fastfood),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('₹$unitPrice / $unitLabel', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(prod['description'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade400), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Qty ($unitLabel):', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 60,
                                  height: 30,
                                  child: TextField(
                                    controller: _qtyControllers[prodKey],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(6)),
                                    onChanged: (val) {
                                      double? parsed = double.tryParse(val);
                                      if (parsed != null && parsed > 0) {
                                        setState(() => _itemQuantities[prodKey] = parsed);
                                      }
                                    },
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    double finalQty = _itemQuantities[prodKey] ?? 1.0;
                                    String note = _cakeMessageControllers[prodKey]?.text ?? '';
                                    _addToCart(prod, finalQty, note);
                                  },
                                  child: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
// CART & ORDERS VIEW
// ==========================================
class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  bool _isCheckingOut = false;

  Future<void> _placeOrder() async {
    if (CakeDatabase.cartItems.isEmpty) return;
    setState(() => _isCheckingOut = true);
    try {
      String orderId = "ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      double total = CakeDatabase.cartItems.fold(0.0, (sum, item) => sum + ((item['price'] as num).toDouble() * ((item['qty'] as num?)?.toDouble() ?? 1.0)));

      var orderData = {
        'orderId': orderId,
        'customerName': CakeDatabase.currentCustomerName,
        'customerPhone': CakeDatabase.currentUserPhone,
        'deliveryAddress': CakeDatabase.currentDeliveryAddress,
        'items': CakeDatabase.cartItems,
        'grandTotal': total,
        'orderStatus': 'Out for Delivery',
        'status': 'Out for Delivery',
        'timestamp': ServerValue.timestamp,
      };

      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'),
        body: json.encode(orderData),
      );

      setState(() {
        CakeDatabase.cartItems.clear();
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('🎉 Order Placed Successfully!', style: TextStyle(color: Color(0xFFF59E0B))),
            content: Text('Your Order ID is #$orderId. Assigned to delivery rider instantly.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Color(0xFFF59E0B)))),
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

    double cartTotal = CakeDatabase.cartItems.fold(0.0, (sum, item) => sum + ((item['price'] as num).toDouble() * ((item['qty'] as num?)?.toDouble() ?? 1.0)));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: CakeDatabase.cartItems.length,
            itemBuilder: (context, index) {
              var item = CakeDatabase.cartItems[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('₹${item['price']} x ${item['qty']} ${item['unit'] ?? 'Kg'}', style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        CakeDatabase.cartItems.removeAt(index);
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
          color: const Color(0xFF0B0F19),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹$cartTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87),
                  onPressed: _isCheckingOut ? null : _placeOrder,
                  child: _isCheckingOut ? const CircularProgressIndicator(color: Colors.black87) : const Text('Place Order Now ➔', style: TextStyle(fontWeight: FontWeight.bold)),
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
// VENDOR PORTAL VIEW
// ==========================================
class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  final nameCtrl = TextEditingController(text: CakeDatabase.bakeryShop['shopName']);
  final phoneCtrl = TextEditingController(text: CakeDatabase.bakeryShop['phone']);
  final addressCtrl = TextEditingController(text: CakeDatabase.bakeryShop['address']);
  bool _isSaving = false;

  Future<void> _saveShopProfile() async {
    setState(() => _isSaving = true);
    try {
      CakeDatabase.bakeryShop['shopName'] = nameCtrl.text.trim();
      CakeDatabase.bakeryShop['phone'] = phoneCtrl.text.trim();
      CakeDatabase.bakeryShop['address'] = addressCtrl.text.trim();

      await http.put(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'),
        body: json.encode(CakeDatabase.bakeryShop),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shop Profile Updated Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('🏪 Vendor & Shop Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 15),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black87, minimumSize: const Size(double.infinity, 48)),
            onPressed: _isSaving ? null : _saveShopProfile,
            child: _isSaving ? const CircularProgressIndicator(color: Colors.black87) : const Text('Save Shop Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// RIDER DELIVERY SCREEN
// ==========================================
class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key});

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final _phoneController = TextEditingController(text: CakeDatabase.currentUserPhone);
  List<Map<String, dynamic>> _liveOrders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
  }

  Future<void> _fetchLiveOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        List<Map<String, dynamic>> orders = [];
        data.forEach((key, val) {
          if (val is Map) {
            var item = Map<String, dynamic>.from(val);
            item['firebaseKey'] = key;
            orders.add(item);
          }
        });
        setState(() => _liveOrders = orders.reversed.toList());
      } else {
        setState(() => _liveOrders = []);
      }
    } catch (_) {
      setState(() => _liveOrders = []);
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _updateOrderStatus(String firebaseKey, String newStatus) async {
    await http.patch(
      Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$firebaseKey.json'),
      body: json.encode({'status': newStatus, 'orderStatus': newStatus}),
    );
    _fetchLiveOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Text('🛵 Rider Delivery Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
              const Spacer(),
              IconButton(onPressed: _fetchLiveOrders, icon: const Icon(Icons.sync, color: Color(0xFFF59E0B))),
            ],
          ),
        ),
        if (_isLoadingOrders) const LinearProgressIndicator(color: Color(0xFFF59E0B)),
        Expanded(
          child: _liveOrders.isEmpty
              ? const Center(child: Text('No delivery orders found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _liveOrders.length,
                  itemBuilder: (context, index) {
                    var ord = _liveOrders[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('Customer: ${ord['customerName'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                        subtitle: Text('Address: ${ord['deliveryAddress'] ?? 'N/A'}\nTotal: ₹${ord['grandTotal'] ?? 0}\nStatus: ${ord['status'] ?? 'Pending'}', style: const TextStyle(color: Colors.white70)),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) => _updateOrderStatus(ord['firebaseKey'], val),
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
