import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ViziagMartEnterpriseApp());
}

class ViziagMartEnterpriseApp extends StatelessWidget {
  const ViziagMartEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart - HyperLocal Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFF1A1A1A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const ViziagMainHubScreen(),
    );
  }
}

// ==========================================
// CENTRAL DATABASE & CLOUD SYNC MODEL
// ==========================================
class ViziagDatabase {
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/"; 

  static String currentUserPhone = "9971968060";
  static String currentCustomerName = "Tarun Kumar";
  static String currentDeliveryAddress = "Sector 15A Ajronda Sabji Mandi, Faridabad";
  
  static List<Map<String, dynamic>> registeredShops = [
    {
      'shopId': 'shop_01',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'ownerName': 'Tarun Kumar',
      'ownerPhotoPath': '', 
      'phone': '9971968060',
      'whatsappNumber': '919971968060',
      'category': 'Sabji & Fruits',
      'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
      'shopBannerPath': '', 
      'bio': 'अजोंदा की सबसे विश्वसनीय दुकान। ताज़ा फल और सब्जियां उचित दामों पर उपलब्ध।',
      'isOpen': true,
    }
  ];

  static List<Map<String, dynamic>> productInventory = [];
  static List<Map<String, dynamic>> cartItems = [];
}

// ==========================================
// MAIN HUB SCREEN
// ==========================================
class ViziagMainHubScreen extends StatefulWidget {
  const ViziagMainHubScreen({super.key});

  @override
  State<ViziagMainHubScreen> createState() => _ViziagMainHubScreenState();
}

class _ViziagMainHubScreenState extends State<ViziagMainHubScreen> {
  int _selectedTabIndex = 0;

  final List<Widget> _tabScreens = [
    const MarketplaceBuyerView(),
    const VendorAuthAndPortalView(), // 🔐 यहाँ डबल-पिन लॉगिन और वेंडर पोर्टल जोड़ दिया गया है
    const UserLoginAndAddressView(),
    const CartAndWhatsAppCheckoutView(), 
    const SettingsConfigView(),
  ];

  @override
  Widget build(BuildContext context) {
    int totalCartCount = ViziagDatabase.cartItems.fold(0, (sum, item) => sum + ((item['qty'] as num?)?.toInt() ?? 1));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Text(
                'Viziag\nMart',
                style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900, fontSize: 13, height: 1.1),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.storefront, size: 12),
                label: const Text('Marketplace', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.lock_outline, size: 12),
                label: const Text('Vendor Login', style: TextStyle(fontSize: 10)),
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
                    onTap: () => setState(() => _selectedTabIndex = 2),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blueAccent, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          ViziagDatabase.currentCustomerName,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 2),
                    child: const Text('(Edit Profile & Address)', style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _tabScreens[_selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 3) {
            setState(() => _selectedTabIndex = 3);
          } else {
            setState(() => _selectedTabIndex = index);
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Market'),
          const BottomNavigationBarItem(icon: Icon(Icons.lock_person_outlined), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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
            label: 'Cart',
          ),
        ],
      ),
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
    color: Colors.grey.shade300,
    child: Icon(fallbackIcon, size: height * 0.4, color: Colors.grey.shade600),
  );
}

// ==========================================
// TAB 1: MARKETPLACE
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  bool isWholesaleMarket = false;
  bool _isLoadingCloud = false;
  final Map<String, double> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _fetchProductsFromCloud();
  }

  Future<void> _fetchProductsFromCloud() async {
    setState(() => _isLoadingCloud = true);
    try {
      final response = await http.get(Uri.parse('${ViziagDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedList = [];
        data.forEach((key, value) {
          var item = Map<String, dynamic>.from(value);
          item['firebaseKey'] = key;
          fetchedList.add(item);
        });
        setState(() {
          ViziagDatabase.productInventory = fetchedList.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint("Cloud sync error: $e");
    } finally {
      setState(() => _isLoadingCloud = false);
    }
  }

  void _addToCart(Map<String, dynamic> prod, double qty) {
    var shop = ViziagDatabase.registeredShops[0];
    if (shop['isOpen'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Sorry! Shop is currently CLOSED by Vendor.'), backgroundColor: Colors.red));
      return;
    }
    if (prod['inStock'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ This item is currently OUT OF STOCK!')));
      return;
    }

    String prodName = prod['name'];
    var existingIndex = ViziagDatabase.cartItems.indexWhere((item) => item['name'] == prodName);

    if (existingIndex >= 0) {
      setState(() {
        ViziagDatabase.cartItems[existingIndex]['qty'] = qty;
      });
    } else {
      setState(() {
        ViziagDatabase.cartItems.add({
          'name': prodName,
          'price': prod['price'],
          'unit': prod['unit'] ?? 'KG',
          'qty': qty,
          'shopName': prod['shopName'] ?? shop['shopName'],
        });
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛒 Added $qty ${prod['unit'] ?? 'KG'} $prodName to Cart!'), duration: const Duration(milliseconds: 800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var shop = ViziagDatabase.registeredShops[0];
    var filteredProducts = ViziagDatabase.productInventory.where((p) => p['isWholesale'] == isWholesaleMarket).toList();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              ToggleButtons(
                isSelected: [!isWholesaleMarket, isWholesaleMarket],
                onPressed: (index) => setState(() => isWholesaleMarket = index == 1),
                borderRadius: BorderRadius.circular(6),
                selectedColor: Colors.white,
                fillColor: const Color(0xFFFF5722),
                color: Colors.black,
                constraints: const BoxConstraints(minHeight: 28, minWidth: 70),
                children: const [
                  Text('Retail', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('Wholesale', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              if (shop['isOpen'] == false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                  child: const Text('SHOP CLOSED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _fetchProductsFromCloud,
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Sync', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        if (_isLoadingCloud) const LinearProgressIndicator(color: Color(0xFFFF5722)),
        const SizedBox(height: 8),

        // Shop Banner Profile
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, spreadRadius: 1)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                width: double.infinity,
                child: shop['shopBannerPath'] != null && shop['shopBannerPath'].isNotEmpty
                    ? buildShopOrProdImage(shop['shopBannerPath'], 110, double.infinity, Icons.store)
                    : Container(color: const Color(0xFF2C3E50), child: const Center(child: Text('🏪 Storefront Banner View', style: TextStyle(color: Colors.white70, fontSize: 11)))),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF5722), width: 2)),
                      child: ClipOval(
                        child: shop['ownerPhotoPath'] != null && shop['ownerPhotoPath'].isNotEmpty
                            ? buildShopOrProdImage(shop['ownerPhotoPath'], 55, 55, Icons.person)
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.person, size: 30, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['shopName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('📍 ${shop['address']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text('📞 WhatsApp: ${shop['whatsappNumber']}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(shop['bio'], style: const TextStyle(fontSize: 10, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text('✨ Shop Items & Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),

        // Grid View
        filteredProducts.isEmpty
            ? const Padding(padding: EdgeInsets.all(30.0), child: Center(child: Text('No products available right now!')))
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  childAspectRatio: 0.48,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  var prod = filteredProducts[index];
                  String prodKey = prod['id'] ?? prod['name'];
                  double unitPrice = (prod['price'] ?? 100.0).toDouble();
                  double selectedQty = _itemQuantities[prodKey] ?? 1.0;
                  double totalPrice = unitPrice * selectedQty;
                  bool inStock = prod['inStock'] ?? true;

                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              child: buildShopOrProdImage(prod['imagePath'], 70, double.infinity, Icons.fastfood),
                            ),
                            if (!inStock)
                              Container(
                                height: 70,
                                color: Colors.black.withOpacity(0.6),
                                child: const Center(
                                  child: Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('₹${unitPrice.toInt()}/${prod['unit'] ?? 'kg'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Qty:', style: TextStyle(fontSize: 7)),
                                        const SizedBox(width: 2),
                                        SizedBox(
                                          width: 26,
                                          height: 16,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 0)),
                                            controller: TextEditingController(text: selectedQty.toInt().toString())
                                              ..selection = TextSelection.fromPosition(TextPosition(offset: selectedQty.toInt().toString().length)),
                                            onChanged: (val) {
                                              double? q = double.tryParse(val);
                                              if (q != null && q > 0) setState(() => _itemQuantities[prodKey] = q);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Total: ₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 20,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: inStock ? const Color(0xFFE91E63) : Colors.grey,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: inStock ? () => _addToCart(prod, selectedQty) : null,
                                        child: Text(inStock ? 'Add to Cart' : 'Out of Stock', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}

// ==========================================
// 🔐 VENDOR LOGIN, DOUBLE PIN & PORTAL WRAPPER
// ==========================================
class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  bool _isLoggedIn = false; // चेक करेगा कि वेंडर ने पिन डालकर लॉगइन किया है या नहीं
  final TextEditingController _loginPhoneCtrl = TextEditingController();
  final TextEditingController _loginPinCtrl = TextEditingController();

  final TextEditingController _regPhoneCtrl = TextEditingController();
  final TextEditingController _createPinCtrl = TextEditingController();
  final TextEditingController _reEnterPinCtrl = TextEditingController();

  bool _isRegisteringNew = false;
  bool _isLoadingAuth = false;

  // फायरबेस से वेंडर का पिन चेक करना या नया पिन सेव करना
  Future<void> _verifyOrLoginVendor() async {
    String phone = _loginPhoneCtrl.text.trim();
    String pin = _loginPinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया मोबाइल नंबर और 4-अंक का पिन दर्ज करें!')));
      return;
    }

    setState(() => _isLoadingAuth = true);
    try {
      final response = await http.get(Uri.parse('${ViziagDatabase.firebaseRestUrl}/vendors/$phone.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        var data = json.decode(response.body);
        if (data['pin'] == pin) {
          setState(() {
            _isLoggedIn = true;
            ViziagDatabase.currentUserPhone = phone;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ सफलतापूर्वक लॉगिन हो गया!'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ गलत पिन (Incorrect PIN)!'), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ यह नंबर रजिस्टर्ड नहीं है। कृपया पहले पिन सेट करें।')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoadingAuth = false);
    }
  }

  Future<void> _saveNewVendorPin() async {
    String phone = _regPhoneCtrl.text.trim();
    String pin1 = _createPinCtrl.text.trim();
    String pin2 = _reEnterPinCtrl.text.trim();

    if (phone.isEmpty || pin1.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया सही मोबाइल नंबर और 4-अंकों का पिन दर्ज करें!')));
      return;
    }

    if (pin1 != pin2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ दोनों पिन मेल नहीं खा रहे हैं (Pins do not match)!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoadingAuth = true);
    try {
      var vendorData = {'phone': phone, 'pin': pin1};
      final response = await http.put(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/vendors/$phone.json'),
        body: json.encode(vendorData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLoggedIn = true;
          _isRegisteringNew = false;
          ViziagDatabase.currentUserPhone = phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 पिन सफलतापूर्व सेव हो गया! अब आप वेंडर पोर्टल में हैं।'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoadingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      // 🔐 Login / Register PIN Screen
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_person, size: 50, color: Color(0xFFFF5722)),
                  const SizedBox(height: 10),
                  Text(
                    _isRegisteringNew ? '🛠️नया पिन बनाएं (Create PIN)' : '🔐 दुकानदार लॉगिन (Vendor Login)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  if (!_isRegisteringNew) ...[
                    TextField(
                      controller: _loginPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'मोबाइल नंबर (Mobile Number)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _loginPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(labelText: '4-अंक का पिन (4-Digit PIN)', border: OutlineInputBorder(), isDense: true, counterText: ''),
                    ),
                    const SizedBox(height: 15),
                    _isLoadingAuth
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
                            onPressed: _verifyOrLoginVendor,
                            child: const Text('लॉगिन करें (Login)'),
                          ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _isRegisteringNew = true),
                      child: const Text('नया अकाउंट है? पिन सेट करें (Create PIN)'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _regPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'मोबाइल नंबर (Mobile Number)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _createPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(labelText: 'पिन दर्ज करें (Enter 4-Digit PIN)', border: OutlineInputBorder(), isDense: true, counterText: ''),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reEnterPinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(labelText: 'दोबारा पिन डालें (Re-enter PIN)', border: OutlineInputBorder(), isDense: true, counterText: ''),
                    ),
                    const SizedBox(height: 15),
                    _isLoadingAuth
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: _saveNewVendorPin,
                            child: const Text('पिन सेव करें और लॉगिन करें (Save & Login)'),
                          ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _isRegisteringNew = false),
                      child: const Text('पहले से पिन है? लॉगिन करें (Back to Login)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ✅ Once logged in via PIN, show the actual Shop Register & Product Update Portal
    return const ShopRegisterAndUpdateView();
  }
}

// ==========================================
// TAB 2: VENDOR PORTAL (SHOP DETAILS, WHATSAPP, ITEMS, STATUS & DELETE)
// ==========================================
class ShopRegisterAndUpdateView extends StatefulWidget {
  const ShopRegisterAndUpdateView({super.key});

  @override
  State<ShopRegisterAndUpdateView> createState() => _ShopRegisterAndUpdateViewState();
}

class _ShopRegisterAndUpdateViewState extends State<ShopRegisterAndUpdateView> {
  late final TextEditingController _shopNameCtrl = TextEditingController(text: ViziagDatabase.registeredShops[0]['shopName']);
  late final TextEditingController _ownerNameCtrl = TextEditingController(text: ViziagDatabase.registeredShops[0]['ownerName']);
  late final TextEditingController _shopWhatsappCtrl = TextEditingController(text: ViziagDatabase.registeredShops[0]['whatsappNumber']);
  late final TextEditingController _shopAddressCtrl = TextEditingController(text: ViziagDatabase.registeredShops[0]['address']);
  late final TextEditingController _shopBioCtrl = TextEditingController(text: ViziagDatabase.registeredShops[0]['bio']);

  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();

  String _selectedUnit = 'KG';
  bool _isWholesaleItem = false;
  bool _isUploadingToCloud = false;
  String? _pickedProdImagePath;
  final ImagePicker _picker = ImagePicker();

  void _saveShopDetails() {
    setState(() {
      ViziagDatabase.registeredShops[0]['shopName'] = _shopNameCtrl.text.trim();
      ViziagDatabase.registeredShops[0]['ownerName'] = _ownerNameCtrl.text.trim();
      ViziagDatabase.registeredShops[0]['whatsappNumber'] = _shopWhatsappCtrl.text.trim();
      ViziagDatabase.registeredShops[0]['address'] = _shopAddressCtrl.text.trim();
      ViziagDatabase.registeredShops[0]['bio'] = _shopBioCtrl.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shop Details & WhatsApp Number Saved!'), backgroundColor: Colors.green));
  }

  Future<void> _pickProductImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _pickedProdImagePath = "data:image/jpeg;base64,${base64Encode(bytes)}");
    }
  }

  Future<void> _pickOwnerPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        ViziagDatabase.registeredShops[0]['ownerPhotoPath'] = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Owner Photo Updated!')));
    }
  }

  Future<void> _pickShopBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        ViziagDatabase.registeredShops[0]['shopBannerPath'] = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Banner Photo Updated!')));
    }
  }

  Future<void> _publishProductToCloud() async {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item name and price!')));
      return;
    }

    setState(() => _isUploadingToCloud = true);
    var activeShop = ViziagDatabase.registeredShops[0];

    var newProduct = {
      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
      'shopName': activeShop['shopName'],
      'owner': activeShop['ownerName'],
      'name': _prodNameCtrl.text,
      'price': double.tryParse(_priceCtrl.text) ?? 100.0,
      'unit': _selectedUnit,
      'stock': int.tryParse(_stockCtrl.text) ?? 20,
      'imagePath': _pickedProdImagePath ?? '',
      'isWholesale': _isWholesaleItem,
      'inStock': true,
    };

    try {
      final response = await http.post(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/products.json'),
        body: json.encode(newProduct),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = json.decode(response.body);
        newProduct['firebaseKey'] = responseData['name'];

        setState(() {
          ViziagDatabase.productInventory.insert(0, newProduct);
        });

        _prodNameCtrl.clear();
        _priceCtrl.clear();
        _stockCtrl.clear();
        setState(() => _pickedProdImagePath = null);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Item Added Successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
    } finally {
      setState(() => _isUploadingToCloud = false);
    }
  }

  Future<void> _deleteProduct(int index, Map<String, dynamic> prod) async {
    String? firebaseKey = prod['firebaseKey'];
    try {
      if (firebaseKey != null) {
        await http.delete(Uri.parse('${ViziagDatabase.firebaseRestUrl}/products/$firebaseKey.json'));
      }
      setState(() {
        ViziagDatabase.productInventory.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Item Deleted Successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  void _toggleStockStatus(int index) {
    setState(() {
      bool currentStatus = ViziagDatabase.productInventory[index]['inStock'] ?? true;
      ViziagDatabase.productInventory[index]['inStock'] = !currentStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    var shop = ViziagDatabase.registeredShops[0];
    bool isShopOpen = shop['isOpen'] ?? true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🛠️ Vendor Control Panel & Shop Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // 🏪 Shop Open/Close Master Button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isShopOpen ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isShopOpen ? Colors.green : Colors.red),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isShopOpen ? '🟢 Shop is Open for Orders' : '🔴 Shop is Closed', style: TextStyle(fontWeight: FontWeight.bold, color: isShopOpen ? Colors.green.shade800 : Colors.red.shade800)),
                  const Text('Customers can place orders only when open.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Switch(
                value: isShopOpen,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() => shop['isOpen'] = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        const Text('📍 Shop & WhatsApp Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(
          controller: _shopWhatsappCtrl, 
          keyboardType: TextInputType.phone, 
          decoration: const InputDecoration(
            labelText: 'WhatsApp Number (e.g. 919971968060)', 
            helperText: 'ऑर्डर इसी नंबर पर WhatsApp पर जाएगा (देश का कोड 91 जरूर लगाएं)',
            helperStyle: TextStyle(fontSize: 9),
            border: OutlineInputBorder(), 
            isDense: true
          ),
        ),
        const SizedBox(height: 8),
        TextField(controller: _shopAddressCtrl, decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _shopBioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Shop Bio / Description', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: _saveShopDetails,
          child: const Text('Save Shop & WhatsApp Number'),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickOwnerPhoto,
                icon: const Icon(Icons.person, size: 14),
                label: const Text('Owner Photo', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickShopBanner,
                icon: const Icon(Icons.store, size: 14),
                label: const Text('Banner Photo', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
        const Divider(height: 25),

        const Text('📦 Add New Item', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _prodNameCtrl, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), isDense: true),
                items: ['KG', 'pc', '20 KG Box', 'Packet'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUnit = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Type: '),
            ChoiceChip(label: const Text('Retail'), selected: !_isWholesaleItem, onSelected: (val) => setState(() => _isWholesaleItem = false)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Wholesale'), selected: _isWholesaleItem, onSelected: (val) => setState(() => _isWholesaleItem = true)),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickProductImage,
          icon: const Icon(Icons.add_a_photo, size: 14),
          label: Text(_pickedProdImagePath == null ? 'Select Item Image' : 'Image Selected ✅'),
        ),
        const SizedBox(height: 12),
        _isUploadingToCloud
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
                onPressed: _publishProductToCloud,
                child: const Text('Add Item to Catalog 🚀'),
              ),
        
        const Divider(height: 35),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📋 Manage Added Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${ViziagDatabase.productInventory.length} Items', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),

        ViziagDatabase.productInventory.isEmpty
            ? const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text('No items added yet.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ViziagDatabase.productInventory.length,
                itemBuilder: (context, index) {
                  var prod = ViziagDatabase.productInventory[index];
                  bool inStock = prod['inStock'] ?? true;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: buildShopOrProdImage(prod['imagePath'], 50, 50, Icons.fastfood),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('₹${prod['price']} / ${prod['unit'] ?? 'KG'} • ${prod['isWholesale'] == true ? 'Wholesale' : 'Retail'}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: inStock ? Colors.blue.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(3)),
                                  child: Text(inStock ? 'In Stock' : 'Out of Stock', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: inStock ? Colors.blue : Colors.red)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(inStock ? Icons.toggle_on : Icons.toggle_off, color: inStock ? Colors.green : Colors.grey, size: 30),
                                onPressed: () => _toggleStockStatus(index),
                                tooltip: 'Toggle In/Out Stock',
                              ),
                              const Text('Stock', style: TextStyle(fontSize: 8, color: Colors.grey)),
                              const SizedBox(height: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteProduct(index, prod),
                                tooltip: 'Delete Item',
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
// TAB 3: CUSTOMER PROFILE
// ==========================================
class UserLoginAndAddressView extends StatefulWidget {
  const UserLoginAndAddressView({super.key});

  @override
  State<UserLoginAndAddressView> createState() => _UserLoginAndAddressViewState();
}

class _UserLoginAndAddressViewState extends State<UserLoginAndAddressView> {
  final TextEditingController _nameCtrl = TextEditingController(text: ViziagDatabase.currentCustomerName);
  final TextEditingController _userPhoneCtrl = TextEditingController(text: ViziagDatabase.currentUserPhone);
  final TextEditingController _addressCtrl = TextEditingController(text: ViziagDatabase.currentDeliveryAddress);

  void _saveCustomerProfile() {
    setState(() {
      ViziagDatabase.currentCustomerName = _nameCtrl.text.trim();
      ViziagDatabase.currentUserPhone = _userPhoneCtrl.text.trim();
      ViziagDatabase.currentDeliveryAddress = _addressCtrl.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Profile Saved Successfully!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('👤 Customer Profile & Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _userPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Full Delivery Address', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
            onPressed: _saveCustomerProfile,
            child: const Text('Save Profile & Address'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: WHATSAPP CHECKOUT CART
// ==========================================
class CartAndWhatsAppCheckoutView extends StatefulWidget {
  const CartAndWhatsAppCheckoutView({super.key});

  @override
  State<CartAndWhatsAppCheckoutView> createState() => _CartAndWhatsAppCheckoutViewState();
}

class _CartAndWhatsAppCheckoutViewState extends State<CartAndWhatsAppCheckoutView> {
  Future<void> _sendOrderToWhatsApp() async {
    if (ViziagDatabase.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }

    String vendorPhone = ViziagDatabase.registeredShops[0]['whatsappNumber'] ?? '919971968060';
    String message = "🛍️ *New Order from Viziag Mart*\n\n👤 *Customer:* ${ViziagDatabase.currentCustomerName}\n📞 *Phone:* ${ViziagDatabase.currentUserPhone}\n📍 *Address:* ${ViziagDatabase.currentDeliveryAddress}\n\n";

    double grandTotal = 0;
    for (int i = 0; i < ViziagDatabase.cartItems.length; i++) {
      var item = ViziagDatabase.cartItems[i];
      double itemTotal = (item['price'] as double) * (item['qty'] as double);
      grandTotal += itemTotal;
      message += "${i + 1}. ${item['name']} - ${item['qty']} ${item['unit']} = *₹${itemTotal.toStringAsFixed(0)}*\n";
    }
    message += "\n💰 *Grand Total: ₹${grandTotal.toStringAsFixed(0)}*";

    String whatsappUrl = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        String fallbackUrl = "whatsapp://send?phone=$vendorPhone&text=${Uri.encodeComponent(message)}";
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ WhatsApp is not installed on this device!')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Error opening WhatsApp: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = ViziagDatabase.cartItems;
    double grandTotal = cart.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['qty'] as double)));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Text('🛒 Your Shopping Cart & Total Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Cart is empty. Add items from Marketplace!'))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      var item = cart[index];
                      double itemTotal = (item['price'] as double) * (item['qty'] as double);
                      return Card(
                        child: ListTile(
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: ${item['qty']} ${item['unit']} • ₹${item['price']} each\nTotal: ₹${itemTotal.toStringAsFixed(0)}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => ViziagDatabase.cartItems.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      onPressed: _sendOrderToWhatsApp,
                      icon: const Icon(Icons.chat),
                      label: Text('Send Order to WhatsApp (₹${grandTotal.toStringAsFixed(0)}) 🚀', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
// TAB 5: SETTINGS
// ==========================================
class SettingsConfigView extends StatelessWidget {
  const SettingsConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('⚙️ Settings & Vendor Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Divider(),
        Text('All product images and details are safely synced with Firebase Cloud Realtime Database and remain persistent even after app reinstallation.'),
      ],
    );
  }
}
