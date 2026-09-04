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
      title: 'CakeApp - Online Bakery & Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4081),
          primary: const Color(0xFFFF4081),
          secondary: const Color(0xFF1A1A1A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
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

  static Map<String, dynamic> bakeryShop = {
    'shopId': 'shop_cake_01',
    'shopName': 'Tarun Premium Bakery',
    'ownerName': 'Tarun Kumar',
    'ownerPhotoPath': '', 
    'phone': '9971968060',
    'whatsappNumber': '919971968060',
    'address': 'Sector 15A Faridabad',
    'bio': 'अहर्निश ताज़ा और स्वादिष्ट केक और बेकरी उत्पाद उपलब्ध।',
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
    const CartAndWhatsAppCheckoutView(),
  ];

  @override
  Widget build(BuildContext context) {
    int totalCartCount = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['qty'] as num?)?.toInt() ?? 1));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Text(
                'CAKEAPP',
                style: TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4081),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.cake, size: 12),
                label: const Text('Shop', style: TextStyle(fontSize: 9)),
              ),
              const SizedBox(width: 3),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.lock_outline, size: 12),
                label: const Text('Vendor', style: TextStyle(fontSize: 9)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
              color: const Color(0xFF2C2C2C),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFFFF4081), size: 13),
                        const SizedBox(width: 4),
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
                    child: const Text('(Edit Profile & Address)', style: TextStyle(color: Color(0xFFFF4081), fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedTabIndex > 2 ? 2 : _selectedTabIndex,
        children: _tabScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 2 ? 2 : _selectedTabIndex,
        selectedItemColor: const Color(0xFFFF4081),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.cake_outlined), label: 'Cakes'),
          const BottomNavigationBarItem(icon: Icon(Icons.lock_person_outlined), label: 'Vendor'),
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
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text('$totalCartCount', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
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
          title: const Text('Edit Profile & Address', style: TextStyle(fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Location Note', isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4081), foregroundColor: Colors.white),
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
// IMAGE HELPER
// ==========================================
Widget buildShopOrProdImage(String? path, double height, double width, IconData fallbackIcon) {
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http')) {
      return Image.network(path, height: height, width: width, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey.shade300, child: Icon(fallbackIcon, size: height * 0.4)));
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
    color: Colors.grey.shade200,
    child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFFF4081)),
  );
}

// ==========================================
// MARKETPLACE BUYER VIEW (DIRECT CAKES)
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

  @override
  void initState() {
    super.initState();
    _fetchProductsFromCloud();
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

  Future<void> _fetchProductsFromCloud() async {
    setState(() => _isLoadingCloud = true);
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Sorry! Bakery is currently CLOSED.'), backgroundColor: Colors.red));
      return;
    }
    if (prod['inStock'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ This cake is currently OUT OF STOCK!')));
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
      SnackBar(content: Text('🎂 Added $qty ${prod['unit'] ?? 'Piece'} $prodName to Cart!'), duration: const Duration(milliseconds: 800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredProducts = CakeDatabase.productInventory.where((p) {
      if (selectedCategory == 'All') return true;
      return p['category'] == selectedCategory;
    }).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFFFF80AB)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake, color: Colors.white, size: 36),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎂 Fresh Cakes & Pastries', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Order delicious custom & fresh cakes instantly!', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _fetchProductsFromCloud,
                  icon: const Icon(Icons.sync, color: Colors.white),
                  tooltip: 'Sync Cakes',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Birthday Cake', 'Chocolate Cake', 'Pastry', 'Customized'].map((category) {
                bool isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF4081),
                    backgroundColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() => selectedCategory = category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          if (_isLoadingCloud) const LinearProgressIndicator(color: Color(0xFFFF4081)),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              var prod = filteredProducts[index];
              String prodKey = prod['firebaseKey'] ?? prod['id'] ?? prod['name'] ?? index.toString();
              double unitPrice = (prod['price'] ?? 499.0).toDouble();
              double selectedQty = _itemQuantities[prodKey] ?? 1.0;
              double totalPrice = unitPrice * selectedQty;
              bool inStock = prod['inStock'] ?? true;

              if (!_cakeMessageControllers.containsKey(prodKey)) {
                _cakeMessageControllers[prodKey] = TextEditingController();
              }
              var msgController = _cakeMessageControllers[prodKey]!;

              if (!_qtyControllers.containsKey(prodKey)) {
                _qtyControllers[prodKey] = TextEditingController(text: selectedQty.toInt().toString());
              }
              var qtyController = _qtyControllers[prodKey]!;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: buildShopOrProdImage(prod['imagePath'], 90, 90, Icons.cake),
                          ),
                          if (!inStock)
                            Container(
                              height: 90,
                              width: 90,
                              color: Colors.black.withOpacity(0.6),
                              child: const Center(
                                child: Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(prod['category'] ?? 'General', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text('₹${unitPrice.toInt()} / ${prod['unit'] ?? 'Piece'}', style: const TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(height: 6),

                            TextField(
                              controller: msgController,
                              style: const TextStyle(fontSize: 11),
                              decoration: const InputDecoration(
                                labelText: 'तुम क्या लिखवाना चाहते हो केक पर',
                                labelStyle: TextStyle(fontSize: 10),
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 6),

                            Row(
                              children: [
                                const Text('Qty:', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 32,
                                  height: 22,
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                                    onChanged: (val) {
                                      double? q = double.tryParse(val);
                                      if (q != null && q > 0) {
                                        setState(() => _itemQuantities[prodKey] = q);
                                      }
                                    },
                                  ),
                                ),
                                const Spacer(),
                                Text('₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 26,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: inStock ? const Color(0xFFFF4081) : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: inStock ? () => _addToCart(prod, selectedQty, msgController.text.trim()) : null,
                                    child: Text(inStock ? 'Add to Cart' : 'Out of Stock', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
// VENDOR LOGIN & PORTAL
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
  final TextEditingController _reEnterPinCtrl = TextEditingController();
  bool _isRegisteringNew = false;
  bool _isLoadingAuth = false;

  Future<void> _verifyOrLoginVendor() async {
    String phone = _loginPhoneCtrl.text.trim();
    String pin = _loginPinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया मोबाइल नंबर और पिन दर्ज करें!')));
      return;
    }

    setState(() => _isLoadingAuth = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendors/$phone.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        var data = json.decode(response.body);
        if (data['pin'] == pin) {
          setState(() {
            _isLoggedIn = true;
            CakeDatabase.currentUserPhone = phone;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ गलत पिन!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ नंबर रजिस्टर्ड नहीं है।')));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAuth = false);
    }
  }

  Future<void> _saveNewVendorPin() async {
    String phone = _regPhoneCtrl.text.trim();
    String pin1 = _createPinCtrl.text.trim();
    String pin2 = _reEnterPinCtrl.text.trim();

    if (phone.isEmpty || pin1.length != 4 || pin1 != pin2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया सही विवरण भरें!')));
      return;
    }

    setState(() => _isLoadingAuth = true);
    try {
      await http.put(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/vendors/$phone.json'),
        body: json.encode({'phone': phone, 'pin': pin1}),
      );
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isRegisteringNew = false;
          CakeDatabase.currentUserPhone = phone;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cake, size: 50, color: Color(0xFFFF4081)),
                  const SizedBox(height: 10),
                  Text(_isRegisteringNew ? '🛠️ नया पिन बनाएं' : '🔐 बेकर लॉगिन', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (!_isRegisteringNew) ...[
                    TextField(controller: _loginPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _loginPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-अंक का पिन', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4081), foregroundColor: Colors.white), onPressed: _verifyOrLoginVendor, child: const Text('लॉगिन करें')),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = true), child: const Text('नया अकाउंट है? पिन सेट करें')),
                  ] else ...[
                    TextField(controller: _regPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _createPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'पिन दर्ज करें', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 10),
                    TextField(controller: _reEnterPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'दोबारा पिन डालें', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _saveNewVendorPin, child: const Text('पिन सेव करें')),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = false), child: const Text('लॉगिन पर वापस जाएं')),
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
  Map<String, dynamic> get activeShop => CakeDatabase.bakeryShop;

  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  late final TextEditingController _shopNameCtrl = TextEditingController(text: activeShop['shopName']);

  final String _selectedUnit = 'Piece';
  String _selectedCategory = 'Birthday Cake';
  bool _isUploadingToCloud = false;
  bool _isSavingShop = false;
  String? _pickedProdImagePath;
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _vendorOrders = [];
  List<Map<String, dynamic>> _vendorProducts = [];
  bool _isLoadingOrders = false;
  bool _isLoadingProducts = false;

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
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          list.add(item);
        });
        if (mounted) setState(() => _vendorOrders = list.reversed.toList());
      } else {
        if (mounted) setState(() => _vendorOrders = []);
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _fetchVendorProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          list.add(item);
        });
        if (mounted) {
          setState(() {
            _vendorProducts = list.reversed.toList();
            CakeDatabase.productInventory = _vendorProducts;
          });
        }
      } else {
        if (mounted) setState(() => _vendorProducts = []);
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _acceptOrder(String orderKey) async {
    try {
      String timeNow = "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} (${DateTime.now().day}/${DateTime.now().month})";
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderKey.json'),
        body: json.encode({'status': 'Out for Delivery 🛵', 'vendorAcceptedTime': timeNow}),
      );
      _fetchVendorOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Order Accepted & Marked Out for Delivery!'), backgroundColor: Colors.green));
      }
    } catch (_) {}
  }

  // Location Share Function (Cleaned for Flutter mobile build compatibility)
  Future<void> _shareLocationToCustomer(String customerPhone, String customerAddress) async {
    try {
      if (customerPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Customer phone number not found!')));
        return;
      }

      String locationText = "📍 नमस्ते! यह रही डिलीवरी लोकेशन: $customerAddress. (कृपया व्हाट्सएप के अटैचमेंट आइकॉन से अपनी लाइव लोकेशन शेयर करें)";
      String whatsappUrl = "https://wa.me/$customerPhone?text=${Uri.encodeComponent(locationText)}";
      final Uri uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error sharing location: $e");
    }
  }

  Future<void> _deleteProduct(String firebaseKey) async {
    try {
      await http.delete(Uri.parse('${CakeDatabase.firebaseRestUrl}/products/$firebaseKey.json'));
      _fetchVendorProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Product Deleted Successfully!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint("Error deleting product: $e");
    }
  }

  Future<void> _toggleStockStatus(String firebaseKey, bool currentStatus) async {
    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/products/$firebaseKey.json'),
        body: json.encode({'inStock': !currentStatus}),
      );
      _fetchVendorProducts();
    } catch (e) {
      debugPrint("Error toggling stock: $e");
    }
  }

  Future<void> _saveShopDetailsToCloud() async {
    setState(() => _isSavingShop = true);
    try {
      CakeDatabase.bakeryShop['shopName'] = _shopNameCtrl.text.trim();

      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'),
        body: json.encode(CakeDatabase.bakeryShop),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shop Details Saved!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Error saving shop: $e");
    } finally {
      if (mounted) setState(() => _isSavingShop = false);
    }
  }

  Future<void> _pickProductImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => _pickedProdImagePath = "data:image/jpeg;base64,${base64Encode(bytes)}");
    }
  }

  Future<void> _publishProductToCloud() async {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please fill cake name and price!')));
      return;
    }
    setState(() => _isUploadingToCloud = true);

    var newProduct = {
      'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
      'shopName': activeShop['shopName'],
      'owner': activeShop['ownerName'],
      'name': _prodNameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 499.0,
      'unit': _selectedUnit,
      'stock': int.tryParse(_stockCtrl.text) ?? 20,
      'imagePath': _pickedProdImagePath ?? '',
      'category': _selectedCategory,
      'inStock': true,
    };

    try {
      final response = await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'),
        body: json.encode(newProduct),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        _prodNameCtrl.clear();
        _priceCtrl.clear();
        _stockCtrl.clear();
        setState(() => _pickedProdImagePath = null);
        _fetchVendorProducts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Cake Added Successfully!'), backgroundColor: Colors.green));
      }
    } finally {
      if (mounted) setState(() => _isUploadingToCloud = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🏪 Shop Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFF4081))),
              const SizedBox(height: 10),
              TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              _isSavingShop
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4081), foregroundColor: Colors.white),
                      onPressed: _saveShopDetailsToCloud,
                      child: const Text('Save Shop Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(thickness: 2),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('📦 Add New Cake / Item', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFF4081))),
              const SizedBox(height: 10),
              TextField(controller: _prodNameCtrl, decoration: const InputDecoration(labelText: 'Cake Name (e.g. Choco Truffle)', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Cake Directory / Category', border: OutlineInputBorder(), isDense: true),
                items: ['Birthday Cake', 'Chocolate Cake', 'Pastry', 'Customized'].map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickProductImage,
                      icon: const Icon(Icons.add_a_photo, size: 16),
                      label: Text(_pickedProdImagePath == null ? 'Select Image' : 'Image Selected ✓', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _isUploadingToCloud 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4081), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), 
                      onPressed: _publishProductToCloud, 
                      child: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(thickness: 2),

        Row(
          children: [
            const Text('📋 Your Cake Inventory & Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: _fetchVendorProducts, icon: const Icon(Icons.sync, size: 18), tooltip: 'Refresh Products'),
          ],
        ),
        const SizedBox(height: 6),
        _isLoadingProducts
            ? const Center(child: CircularProgressIndicator())
            : _vendorProducts.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(12), child: Center(child: Text('कोई केक उपलब्ध नहीं है'))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vendorProducts.length,
                    itemBuilder: (context, index) {
                      var prod = _vendorProducts[index];
                      bool inStock = prod['inStock'] ?? true;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: buildShopOrProdImage(prod['imagePath'], 45, 45, Icons.cake),
                          ),
                          title: Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${prod['category']} • ₹${prod['price']}\nStatus: ${inStock ? '🟢 In Stock' : '🔴 Out of Stock'}', style: const TextStyle(fontSize: 11)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: inStock,
                                activeColor: Colors.green,
                                onChanged: (val) => _toggleStockStatus(prod['firebaseKey'], inStock),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteProduct(prod['firebaseKey']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

        const SizedBox(height: 16),
        const Divider(thickness: 2),

        Row(
          children: [
            const Text('🛒 Customer Orders Received', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF4081))),
            const Spacer(),
            IconButton(onPressed: _fetchVendorOrders, icon: const Icon(Icons.sync, size: 18), tooltip: 'Refresh Orders'),
          ],
        ),
        const SizedBox(height: 6),
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
                      List itemsList = ord['items'] ?? [];
                      String custPhone = ord['customerPhone'] ?? '';
                      String custAddr = ord['customerAddress'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${ord['customerName']} - ₹${ord['grandTotal']?.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  Chip(
                                    label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 9)),
                                    backgroundColor: status.contains('Pending') ? Colors.orange : Colors.green,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('🕒 आर्डर समय: ${ord['orderTime'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('📞 WhatsApp: $custPhone', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                              Text('📍 पता / लोकेशन: $custAddr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 6),
                              const Text('🎂 आर्डर किए गए आइटम और मैसेज:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF4081))),
                              ...itemsList.map<Widget>((it) {
                                String cakeMsg = it['cakeMessage'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6, top: 2),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ${it['name']} (${it['qty']} ${it['unit']}) - ₹${(it['price'] * it['qty']).toInt()}', style: const TextStyle(fontSize: 11)),
                                      if (cakeMsg.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2, bottom: 4),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: Text('💬 केक पर लिखावट: "$cakeMsg"', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink)),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              
                              // Delivery/Vendor Action Buttons
                              Row(
                                children: [
                                  if (status.contains('Pending'))
                                    Expanded(
                                      child: SizedBox(
                                        height: 32,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                          onPressed: () => _acceptOrder(ord['firebaseKey']),
                                          child: const Text('Accept Order', style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    ),
                                  if (status.contains('Pending')) const SizedBox(width: 8),
                                  
                                  // 📍 Share Location Button for Delivery Boy/Vendor
                                  Expanded(
                                    child: SizedBox(
                                      height: 32,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                                        onPressed: () => _shareLocationToCustomer(custPhone, custAddr),
                                        icon: const Icon(Icons.share_location, size: 14),
                                        label: const Text('📍 Share Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
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
// WHATSAPP CHECKOUT CART & LOCATION SHARING
// ==========================================
class CartAndWhatsAppCheckoutView extends StatefulWidget {
  const CartAndWhatsAppCheckoutView({super.key});

  @override
  State<CartAndWhatsAppCheckoutView> createState() => _CartAndWhatsAppCheckoutViewState();
}

class _CartAndWhatsAppCheckoutViewState extends State<CartAndWhatsAppCheckoutView> {
  bool _isPlacingOrder = false;
  bool _isLoadingUserOrders = false;
  bool _isSharingLocation = false;
  List<Map<String, dynamic>> _userOrdersList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserOrders();
  }

  Future<void> _fetchUserOrders() async {
    setState(() => _isLoadingUserOrders = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['firebaseKey'] = key;
          if (item['customerPhone'] == CakeDatabase.currentUserPhone) {
            list.add(item);
          }
        });
        if (mounted) setState(() => _userOrdersList = list.reversed.toList());
      }
    } catch (e) {
      debugPrint("Error fetching user orders: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUserOrders = false);
    }
  }

  // WhatsApp Native Location Share Option
  Future<void> _sendLiveLocationOnWhatsApp() async {
    setState(() => _isSharingLocation = true);
    try {
      String vendorPhone = CakeDatabase.bakeryShop['whatsappNumber'] ?? '919971968060';
      String locationPrompt = "📍 नमस्ते भाई, मेरी डिलीवरी लोकेशन यह है: ${CakeDatabase.currentDeliveryAddress}. (कृपया व्हाट्सएप के लोकेशन आइकॉन से लाइव लोकेशन शेयर करें)";
      
      String whatsappUrl = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(locationPrompt)}";
      final Uri uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      if (mounted) setState(() => _isSharingLocation = false);
    }
  }

  Future<void> _sendOrderToWhatsApp() async {
    if (CakeDatabase.cartItems.isEmpty) return;
    setState(() => _isPlacingOrder = true);

    double grandTotal = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['qty'] as double)));
    
    String formattedTime = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} | ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    var orderData = {
      'orderId': 'ord_${DateTime.now().millisecondsSinceEpoch}',
      'customerName': CakeDatabase.currentCustomerName,
      'customerPhone': CakeDatabase.currentUserPhone,
      'customerAddress': CakeDatabase.currentDeliveryAddress,
      'items': List.from(CakeDatabase.cartItems),
      'grandTotal': grandTotal,
      'orderTime': formattedTime,
      'status': 'Out for Delivery 🛵',
    };

    try {
      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'),
        body: json.encode(orderData),
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        CakeDatabase.cartItems.clear();
        _isPlacingOrder = false;
      });
    }
    
    _fetchUserOrders();

    String vendorPhone = CakeDatabase.bakeryShop['whatsappNumber'] ?? '919971968060';
    String message = "🎂 *New Cake Order from CakeApp*\n⏱️ *Time:* $formattedTime\n\n👤 *Customer:* ${CakeDatabase.currentCustomerName}\n📱 *Phone:* ${CakeDatabase.currentUserPhone}\n📍 *Address:* ${CakeDatabase.currentDeliveryAddress}\n\n";

    for (var item in orderData['items'] as List) {
      message += "• ${item['name']} x ${item['qty']} ${item['unit']} = ₹${(item['price'] * item['qty']).toInt()}\n";
      if ((item['cakeMessage'] ?? '').toString().isNotEmpty) {
        message += "  💬 Cake Msg: ${item['cakeMessage']}\n";
      }
    }
    message += "\n💰 *Grand Total: ₹${grandTotal.toInt()}*";

    String whatsappUrl = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = CakeDatabase.cartItems;
    double grandTotal = cart.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['qty'] as double)));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          const Text('🛒 Your Cake Cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        String cakeMsg = item['cakeMessage'] ?? '';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => setState(() => CakeDatabase.cartItems.removeAt(index)),
                                    ),
                                  ],
                                ),
                                Text('Qty: ${item['qty']} ${item['unit']} • ₹${item['price']} each', style: const TextStyle(fontSize: 11)),
                                if (cakeMsg.isNotEmpty)
                                  Text('💬 केक पर लिखावट: $cakeMsg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: _isPlacingOrder
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                                    onPressed: _sendOrderToWhatsApp,
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('Send Order to WhatsApp 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

          const Divider(height: 30, thickness: 2),

          Row(
            children: [
              const Text('📦 Your Orders & Location Sharing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF4081))),
              const Spacer(),
              IconButton(
                onPressed: _fetchUserOrders,
                icon: const Icon(Icons.sync, size: 18),
                tooltip: 'Refresh Orders',
              ),
            ],
          ),
          const SizedBox(height: 6),

          _isLoadingUserOrders
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : _userOrdersList.isEmpty
                  ? const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('आपने अभी तक कोई आर्डर नहीं दिया है'))))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _userOrdersList.length,
                      itemBuilder: (context, index) {
                        var ord = _userOrdersList[index];
                        String status = ord['status'] ?? 'Pending ⏳';
                        String orderTime = ord['orderTime'] ?? 'N/A';
                        List itemsList = ord['items'] ?? [];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Order ID: ${ord['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    const Spacer(),
                                    Chip(
                                      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 9)),
                                      backgroundColor: status.contains('Pending') ? Colors.orange : Colors.green,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Total Amount: ₹${ord['grandTotal']?.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                const SizedBox(height: 2),
                                Text('🕒 आर्डर किया गया: $orderTime', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                                Text('📍 पता: ${ord['customerAddress']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 6),
                                ...itemsList.map<Widget>((it) {
                                  String cakeMsg = it['cakeMessage'] ?? '';
                                  return Text('• ${it['name']} (${it['qty']} ${it['unit']})${cakeMsg.isNotEmpty ? ' | 💬 $cakeMsg' : ''}', style: const TextStyle(fontSize: 11, color: Colors.pink));
                                }).toList(),
                                const SizedBox(height: 8),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: _isSharingLocation
                                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                      : ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: _sendLiveLocationOnWhatsApp,
                                          icon: const Icon(Icons.share_location, size: 14),
                                          label: const Text(
                                            '📍 Share WhatsApp Live Location',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
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
