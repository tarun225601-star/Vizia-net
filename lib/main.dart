import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
// CENTRAL DATABASE & CONFIG MODEL
// ==========================================
class ViziagDatabase {
  static String firebaseRestUrl = ""; 
  static String activeCityZone = "Faridabad, Delhi & Gurgaon";
  static const String secretAdminCode = "202137"; // कंपनी का फिक्स सिक्रेट कोड

  // वर्तमान यूजर (कस्टमर) की जानकारी
  static String currentUserPhone = "";
  static String currentDeliveryAddress = "";
  static bool isUserLoggedIn = false;

  // रजिस्टर्ड दुकानें (WhatsApp नंबर के साथ)
  static List<Map<String, dynamic>> registeredShops = [
    {
      'shopId': 'shop_01',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'ownerName': 'Tarun Kumar',
      'ownerPhoto': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      'phone': '9971968060',
      'whatsappNumber': '919971968060', // आर्डर देखने के लिए WhatsApp नंबर
      'category': 'Sabji & Fruits',
      'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
      'shopBanner': 'https://images.unsplash.com/photo-1542838132-92c53300491e',
      'isOpen': true,
      'isApproved': true,
    }
  ];

  // प्रोडक्ट्स इन्वेंट्री
  static List<Map<String, dynamic>> productInventory = [
    {
      'id': 'p_101',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'owner': 'Tarun Kumar',
      'name': 'Fresh Kashmiri Apple',
      'category': 'Fruits & Vegetables',
      'price': 120.0,
      'unit': 'KG',
      'stock': 50,
      'location': 'Sector 15A, Faridabad',
      'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
      'isWholesale': false,
      'deliveryType': 'Express Delivery'
    },
  ];
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
    const ShopRegisterAndUpdateView(),
    const UserLoginAndAddressView(),
    const SettingsConfigView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Text(
                'Viziag Mart',
                style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const Spacer(),
              _buildNavBtn('Market', Icons.storefront, 0),
              _buildNavBtn('Vendor', Icons.store, 1),
              _buildNavBtn('User/OTP', Icons.person, 2),
              _buildNavBtn('Settings', Icons.settings, 3),
            ],
          ),
        ),
      ),
      body: _tabScreens[_selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Vendor'),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Profile/OTP'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavBtn(String title, IconData icon, int index) {
    bool isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: RETAIL & WHOLESALE MARKETPLACE
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  bool isWholesaleMarket = false;

  void _placeOrder(Map<String, dynamic> shop, Map<String, dynamic> prod) {
    if (!ViziagDatabase.isUserLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please login with your mobile number & set delivery address first!'), backgroundColor: Colors.red),
      );
      return;
    }

    // WhatsApp पर आर्डर भेजने की सुविधा
    String whatsappMsg = "Hello ${shop['shopName']}, I want to order:\n"
        "📦 Item: ${prod['name']}\n"
        "💰 Price: ₹${prod['price']} / ${prod['unit']}\n"
        "📍 Deliver To: ${ViziagDatabase.currentDeliveryAddress}\n"
        "📞 Customer Ph: ${ViziagDatabase.currentUserPhone}";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Order placed successfully! Sent to shop WhatsApp: ${shop['whatsappName'] ?? shop['shopName']}'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // यूजर डिलीवरी एड्रेस बार
        Container(
          color: Colors.amber.shade100,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.deepOrange, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  ViziagDatabase.isUserLoggedIn
                      ? 'Delivering to: ${ViziagDatabase.currentDeliveryAddress} (${ViziagDatabase.currentUserPhone})'
                      : '⚠️ User not logged in. Tap "User/OTP" tab to set address.',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isWholesaleMarket ? const Color(0xFFFF5722) : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => isWholesaleMarket = false),
                  icon: const Icon(Icons.shopping_bag, size: 14),
                  label: const Text('🛍️ Retail', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWholesaleMarket ? Colors.purple.shade700 : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => isWholesaleMarket = true),
                  icon: const Icon(Icons.inventory_2, size: 14),
                  label: const Text('📦 Wholesale', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: ViziagDatabase.registeredShops.map((shop) {
              bool shopOpen = shop['isOpen'] ?? true;
              bool isApproved = shop['isApproved'] ?? false;

              if (!isApproved) return const SizedBox.shrink();

              var shopProducts = ViziagDatabase.productInventory.where((p) =>
                p['shopName'] == shop['shopName'] && p['isWholesale'] == isWholesaleMarket
              ).toList();

              if (shopProducts.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: Image.network(
                            shop['shopBanner'],
                            height: 90,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(height: 90, color: Colors.grey),
                          ),
                        ),
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: shopOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shopOpen ? '🟢 OPEN' : '🔴 CLOSED',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 10,
                          right: 10,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(shop['ownerPhoto']),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop['shopName'],
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'WhatsApp Orders Enabled • ${shop['address']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: shopOpen ? shopProducts.map((prod) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(prod['imageUrl'], width: 45, height: 45, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('₹${prod['price']} / ${prod['unit']} • Stock: ${prod['stock']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green color for orders
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                                onPressed: () => _placeOrder(shop, prod),
                                child: const Text('Order WhatsApp', style: TextStyle(fontSize: 10)),
                              )
                            ],
                          ),
                        )).toList() : [
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('🔴 Shop is currently CLOSED.', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TAB 2: VENDOR REGISTRATION & WHATSAPP FORM
// ==========================================
class ShopRegisterAndUpdateView extends StatefulWidget {
  const ShopRegisterAndUpdateView({super.key});

  @override
  State<ShopRegisterAndUpdateView> createState() => _ShopRegisterAndUpdateViewState();
}

class _ShopRegisterAndUpdateViewState extends State<ShopRegisterAndUpdateView> {
  final TextEditingController _shopNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController(); // WhatsApp नंबर यहाँ डाला जाएगा
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _secretCodeCtrl = TextEditingController();

  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();

  String _selectedUnit = 'KG';
  bool _isWholesaleItem = false;

  void _registerNewShopWithSecretCode() {
    if (_shopNameCtrl.text.isEmpty || _whatsappCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill shop name and WhatsApp number!')));
      return;
    }

    if (_secretCodeCtrl.text.trim() != ViziagDatabase.secretAdminCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Invalid Secret Admin Code (202137 required)!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      ViziagDatabase.registeredShops.add({
        'shopId': 'shop_${DateTime.now().millisecondsSinceEpoch}',
        'shopName': _shopNameCtrl.text,
        'ownerName': _ownerNameCtrl.text,
        'ownerPhoto': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
        'phone': _phoneCtrl.text,
        'whatsappNumber': _whatsappCtrl.text, // व्हाट्सएप सेव किया गया
        'category': 'General Store',
        'address': _addressCtrl.text,
        'shopBanner': 'https://images.unsplash.com/photo-1542838132-92c53300491e',
        'isOpen': true,
        'isApproved': true,
      });
    });

    _shopNameCtrl.clear();
    _ownerNameCtrl.clear();
    _phoneCtrl.clear();
    _whatsappCtrl.clear();
    _addressCtrl.clear();
    _secretCodeCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Shop Registered Successfully with WhatsApp Order Integration!'), backgroundColor: Colors.green),
    );
  }

  void _publishProduct() {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item name and price!')));
      return;
    }

    setState(() {
      ViziagDatabase.productInventory.insert(0, {
        'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
        'shopName': ViziagDatabase.registeredShops[0]['shopName'],
        'owner': ViziagDatabase.registeredShops[0]['ownerName'],
        'name': _prodNameCtrl.text,
        'category': 'Fruits & Vegetables',
        'price': double.tryParse(_priceCtrl.text) ?? 100.0,
        'unit': _selectedUnit,
        'stock': int.tryParse(_stockCtrl.text) ?? 20,
        'location': 'Faridabad',
        'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        'isWholesale': _isWholesaleItem,
        'deliveryType': _isWholesaleItem ? 'Bulk Delivery' : 'Express Delivery'
      });
    });

    _prodNameCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Product Published Live Successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    var myShop = ViziagDatabase.registeredShops[0];
    bool isShopOpen = myShop['isOpen'] ?? true;
    var myProducts = ViziagDatabase.productInventory.where((p) => p['shopName'] == myShop['shopName']).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: isShopOpen ? Colors.green.shade50 : Colors.red.shade50,
          child: SwitchListTile(
            title: Text(
              isShopOpen ? '🟢 Shop Status: OPEN' : '🔴 Shop Status: CLOSED',
              style: TextStyle(fontWeight: FontWeight.bold, color: isShopOpen ? Colors.green.shade800 : Colors.red.shade800, fontSize: 13),
            ),
            subtitle: const Text('Toggle switch to open or close your shop instantly', style: TextStyle(fontSize: 10)),
            value: isShopOpen,
            activeColor: Colors.green,
            onChanged: (val) {
              setState(() {
                myShop['isOpen'] = val;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text('🏪 Register Shop & WhatsApp Orders Form', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name (Photo Included)', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Calling Mobile Number', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        // यहाँ शॉप वाला अपना WhatsApp नंबर डालेगा जिस पर आर्डर दिखेंगे
        TextField(
          controller: _whatsappCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'WhatsApp Number (To Receive Customer Orders)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_android, color: Colors.green),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Shop Address / Location', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(
          controller: _secretCodeCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Company Secret Code (202137)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock, color: Color(0xFFFF5722)),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
          onPressed: _registerNewShopWithSecretCode,
          child: const Text('Verify Code & Register Shop'),
        ),
        const Divider(height: 25),
        const Text('📦 Add Item to Shop', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                items: ['KG', 'Piece', '20 KG Box', 'Packet'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUnit = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder(), isDense: true)),
        CheckboxListTile(
          title: const Text('List as Wholesale Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          value: _isWholesaleItem,
          activeColor: Colors.purple,
          onChanged: (val) => setState(() => _isWholesaleItem = val ?? false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: _publishProduct,
          child: const Text('Publish Item Live 🚀'),
        ),
        const Divider(height: 25),
        const Text('📋 Manage / Delete Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...myProducts.map((prod) => Card(
          child: ListTile(
            title: Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('₹${prod['price']} / ${prod['unit']}', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  ViziagDatabase.productInventory.remove(prod);
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🗑️ Deleted ${prod['name']}')));
              },
            ),
          ),
        )),
      ],
    );
  }
}

// ==========================================
// TAB 3: USER MOBILE OTP & DELIVERY ADDRESS VIEW
// ==========================================
class UserLoginAndAddressView extends StatefulWidget {
  const UserLoginAndAddressView({super.key});

  @override
  State<UserLoginAndAddressView> createState() => _UserLoginAndAddressViewState();
}

class _UserLoginAndAddressViewState extends State<UserLoginAndAddressView> {
  final TextEditingController _userPhoneCtrl = TextEditingController(text: ViziagDatabase.currentUserPhone);
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController(text: ViziagDatabase.currentDeliveryAddress);
  bool _otpSent = false;

  void _sendOtp() {
    if (_userPhoneCtrl.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid 10-digit mobile number!')));
      return;
    }
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📱 OTP Sent! Use code: 1234')));
  }

  void _verifyOtpAndSaveAddress() {
    if (_otpCtrl.text.trim() != "1234") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Invalid OTP! Enter 1234'), backgroundColor: Colors.red));
      return;
    }
    if (_addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your delivery address!'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      ViziagDatabase.currentUserPhone = _userPhoneCtrl.text.trim();
      ViziagDatabase.currentDeliveryAddress = _addressCtrl.text.trim();
      ViziagDatabase.isUserLoggedIn = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Mobile Verified & Delivery Address Saved Successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('👤 Customer Mobile OTP & Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _userPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Your Mobile Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
          ),
          const SizedBox(height: 10),
          if (!_otpSent)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
              onPressed: _sendOtp,
              child: const Text('Send OTP'),
            ),
          if (_otpSent) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter OTP (Type 1234)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.security)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Delivery Address (Where you want items delivered)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: _verifyOtpAndSaveAddress,
              child: const Text('Verify OTP & Save Address'),
            ),
          ],
          if (ViziagDatabase.isUserLoggedIn) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Logged In Customer Profile:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Phone: ${ViziagDatabase.currentUserPhone}'),
                  Text('Address: ${ViziagDatabase.currentDeliveryAddress}'),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: SETTINGS
// ==========================================
class SettingsConfigView extends StatefulWidget {
  const SettingsConfigView({super.key});

  @override
  State<SettingsConfigView> createState() => _SettingsConfigViewState();
}

class _SettingsConfigViewState extends State<SettingsConfigView> {
  final TextEditingController _firebaseUrlCtrl = TextEditingController(text: ViziagDatabase.firebaseRestUrl);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚙️ App & Database Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _firebaseUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Firebase Database URL',
              border: OutlineInputBorder(),
              hintText: 'https://your-app-default-rtdb.firebaseio.com/',
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                ViziagDatabase.firebaseRestUrl = _firebaseUrlCtrl.text.trim();
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Settings Saved!')));
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
