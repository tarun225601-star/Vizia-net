import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/"; 
  static String activeCityZone = "Faridabad, Delhi & Gurgaon";

  static String currentUserPhone = "";
  static String currentDeliveryAddress = "";
  static bool isUserLoggedIn = false;

  static bool isShopRegistered = true; 

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
      'isOpen': true,
      'isApproved': true,
    }
  ];

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
      'imagePath': '',
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Order placed successfully!'), backgroundColor: Colors.green),
    );
  }

  Widget _buildImageView(String? path, double height, double width, IconData fallbackIcon) {
    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), height: height, width: width, fit: BoxFit.cover);
    }
    return Container(
      height: height,
      width: width,
      color: Colors.grey.shade300,
      child: Icon(fallbackIcon, size: height * 0.4, color: Colors.grey.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                          child: _buildImageView(shop['shopBannerPath'], 90, double.infinity, Icons.store),
                        ),
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            color: Colors.black.withOpacity(0.4),
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
                                child: ClipOval(
                                  child: _buildImageView(shop['ownerPhotoPath'], 36, 36, Icons.person),
                                ),
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
                                child: _buildImageView(prod['imagePath'], 45, 45, Icons.fastfood),
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
                                  backgroundColor: const Color(0xFF25D366), 
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
// TAB 2: VENDOR DASHBOARD & ITEM PUBLISH FORM
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
  final TextEditingController _whatsappCtrl = TextEditingController(); 
  final TextEditingController _addressCtrl = TextEditingController();

  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();

  String _selectedUnit = 'KG';
  bool _isWholesaleItem = false;

  String? _pickedOwnerPhotoPath;
  String? _pickedShopBannerPath;
  String? _pickedProdImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'owner') _pickedOwnerPhotoPath = image.path;
        if (type == 'banner') _pickedShopBannerPath = image.path;
        if (type == 'product') _pickedProdImagePath = image.path;
      });
    }
  }

  void _registerShopDirectly() {
    if (_shopNameCtrl.text.isEmpty || _whatsappCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill shop name and WhatsApp number!')));
      return;
    }

    setState(() {
      ViziagDatabase.registeredShops.insert(0, {
        'shopId': 'shop_${DateTime.now().millisecondsSinceEpoch}',
        'shopName': _shopNameCtrl.text,
        'ownerName': _ownerNameCtrl.text,
        'ownerPhotoPath': _pickedOwnerPhotoPath ?? '',
        'phone': _phoneCtrl.text,
        'whatsappNumber': _whatsappCtrl.text,
        'category': 'General Store',
        'address': _addressCtrl.text,
        'shopBannerPath': _pickedShopBannerPath ?? '',
        'isOpen': true,
        'isApproved': true,
      });
      ViziagDatabase.isShopRegistered = true; 
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Shop Registered Successfully!'), backgroundColor: Colors.green),
    );
  }

  void _publishProduct() {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item name and price!')));
      return;
    }

    var activeShop = ViziagDatabase.registeredShops[0];

    setState(() {
      ViziagDatabase.productInventory.insert(0, {
        'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
        'shopName': activeShop['shopName'],
        'owner': activeShop['ownerName'],
        'name': _prodNameCtrl.text,
        'category': 'General',
        'price': double.tryParse(_priceCtrl.text) ?? 100.0,
        'unit': _selectedUnit,
        'stock': int.tryParse(_stockCtrl.text) ?? 20,
        'location': activeShop['address'],
        'imagePath': _pickedProdImagePath ?? '',
        'isWholesale': _isWholesaleItem,
        'deliveryType': _isWholesaleItem ? 'Bulk Delivery' : 'Express Delivery'
      });
    });

    _prodNameCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.clear();
    setState(() {
      _pickedProdImagePath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Product Published Live Successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    if (!ViziagDatabase.isShopRegistered) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('🏪 Register Your Shop (One-Time)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(child: Text(_pickedOwnerPhotoPath == null ? 'Owner Photo: Not Selected' : 'Owner Photo: Selected ✅', style: const TextStyle(fontSize: 12))),
              ElevatedButton.icon(
                onPressed: () => _pickImage('owner'),
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Gallery se Chunein'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Calling Mobile Number', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _whatsappCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp Number (For Orders)', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Shop Address / Location', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: Text(_pickedShopBannerPath == null ? 'Shop Banner: Not Selected' : 'Shop Banner: Selected ✅', style: const TextStyle(fontSize: 12))),
              ElevatedButton.icon(
                onPressed: () => _pickImage('banner'),
                icon: const Icon(Icons.image, size: 16),
                label: const Text('Gallery se Chunein'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
            onPressed: _registerShopDirectly,
            child: const Text('Register Shop Now'),
          ),
        ],
      );
    }

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
        const SizedBox(height: 15),
        const Text('📦 Add Item to Shop (Gallery Photo)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(child: Text(_pickedProdImagePath == null ? 'Item Photo: Not Selected' : 'Item Photo: Selected ✅', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
              onPressed: () => _pickImage('product'),
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Gallery se Photo Chunein'),
            ),
          ],
        ),
        const SizedBox(height: 8),

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
            leading: prod['imagePath'] != null && prod['imagePath'].isNotEmpty
                ? Image.file(File(prod['imagePath']), width: 40, height: 40, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 40),
            title: Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('₹${prod['price']} / ${prod['unit']} • Stock: ${prod['stock']}', style: const TextStyle(fontSize: 11)),
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
      // FIX: backgroundColor सही जगह (SnackBar के अंदर) सेट किया गया है और const हटाया गया है
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid OTP! Enter 1234'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      ViziagDatabase.currentUserPhone = _userPhoneCtrl.text.trim();
      ViziagDatabase.currentDeliveryAddress = _addressCtrl.text.trim();
      ViziagDatabase.isUserLoggedIn = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Mobile Verified & Delivery Address Saved Successfully!'),
        backgroundColor: Colors.green,
      ),
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
  const SettingsConfigView(
      {super.key});

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
              labelText: 'Firebase Database URL (Hardcoded Active)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          const Text('Note: Firebase URL is securely configured in the app backend.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
