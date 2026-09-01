import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const ViziagMartEnterpriseApp());
}

class ViziagMartEnterpriseApp extends StatelessWidget {
  const ViziagMartEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart - HyperLocal Marketplace & Vendor Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFF1A1A1A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        fontFamily: 'sans-serif',
      ),
      home: const ViziagMainHubScreen(),
    );
  }
}

// ==========================================
// CENTRAL DATABASE MODEL & FIREBASE SYNC
// ==========================================
class ViziagDatabase {
  static String firebaseRestUrl = "https://viziag-mart-default-rtdb.firebaseio.com/";
  static String activeCityZone = "Faridabad, Delhi & Gurgaon";
  
  static String currentBuyerName = "Tarun Kumar";
  static String currentBuyerPhone = "9971968060";

  static String currentVendorShop = "Tarun Fruit & Vegetable Shop";
  static String currentVendorPhone = "9971968060";

  // Master Product Inventory
  static List<Map<String, dynamic>> productInventory = [
    {
      'id': 'p_101',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'owner': 'Tarun Kumar',
      'name': 'Fresh Kashmiri Apple (Royal Gala)',
      'category': 'Fruits & Vegetables',
      'price': 120.0,
      'unit': 'KG',
      'stock': 50,
      'location': 'Sector 15A, Ajronda Sabji Mandi, Faridabad',
      'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
      'isWholesale': false,
      'gstRate': '0% GST',
      'deliveryType': '15 Min Express Delivery'
    },
    {
      'id': 'p_102',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'owner': 'Tarun Kumar',
      'name': 'Royal Gala Apple Box (Wholesale Bulk)',
      'category': 'Fruits & Vegetables',
      'price': 2200.0,
      'unit': '20 KG Box',
      'stock': 10,
      'location': 'Sector 15A, Ajronda Sabji Mandi, Faridabad',
      'imageUrl': 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2',
      'isWholesale': true, // होलसेल आइटम
      'gstRate': '0% GST',
      'deliveryType': 'Bulk Delivery'
    },
    {
      'id': 'p_103',
      'shopName': 'Shree Balaji Kirana Store',
      'owner': 'Mukesh Gupta',
      'name': 'Aashirvaad Shudh Chakki Atta',
      'category': 'Groceries & Staples',
      'price': 390.0,
      'unit': '10 KG Pack',
      'stock': 15,
      'location': 'Sector 16 Market, Faridabad',
      'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c',
      'isWholesale': false,
      'gstRate': '5% GST',
      'deliveryType': 'Same Day Delivery'
    },
  ];

  static List<Map<String, dynamic>> registeredShops = [
    {
      'shopId': 'shop_01',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'ownerName': 'Tarun Kumar',
      'phone': '9971968060',
      'category': 'Sabji & Fruits',
      'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
      'shopBanner': 'https://images.unsplash.com/photo-1542838132-92c53300491e',
      'isApproved': true,
    },
    {
      'shopId': 'shop_02',
      'shopName': 'Shree Balaji Kirana Store',
      'ownerName': 'Mukesh Gupta',
      'phone': '9811223344',
      'category': 'Grocery & Staples',
      'address': 'Sector 16 Market, Faridabad',
      'shopBanner': 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a',
      'isApproved': true,
    }
  ];

  // Firebase Realtime Sync Function via REST API
  static Future<void> syncDataToFirebase() async {
    try {
      final uri = Uri.parse("${firebaseRestUrl}viziag_data.json");
      final response = await http.put(
        uri,
        body: jsonEncode({
          'products': productInventory,
          'shops': registeredShops,
        }),
      );
      if (response.statusCode == 200) {
        if (kDebugMode) print("Data synced to Firebase successfully!");
      }
    } catch (e) {
      if (kDebugMode) print("Firebase sync error: $e");
    }
  }
}

// ==========================================
// MAIN HUB SCREEN WITH MARKETPLACE TABS
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
    const VendorPortalManageView(),
    const MasterGatekeeperAdminView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 4,
          title: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Viziag Mart Enterprise',
                    style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(ViziagDatabase.activeCityZone, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              const Spacer(),
              _buildHeaderNavButton('Market', Icons.storefront, 0),
              const SizedBox(width: 4),
              _buildHeaderNavButton('Vendor', Icons.edit_shop, 1),
              const SizedBox(width: 4),
              _buildHeaderNavButton('Admin', Icons.security, 2),
            ],
          ),
        ),
      ),
      body: _tabScreens[_selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Shop Portal'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin Gatekeeper'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        tooltip: 'Sync Firebase DB',
        onPressed: () async {
          await ViziagDatabase.syncDataToFirebase();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔥 Data successfully pushed to Firebase Realtime Database!')),
          );
        },
        child: const Icon(Icons.cloud_upload),
      ),
    );
  }

  Widget _buildHeaderNavButton(String title, IconData icon, int tabIndex) {
    bool isSelected = _selectedTabIndex == tabIndex;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: RETAIL & WHOLESALE MARKETPLACE VIEW
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  bool isWholesaleMarket = false; // दो अलग डैशबोर्ड टॉगल: रिटेल vs होलसेल मार्केटप्लेस

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // मार्केटप्लेस टाइप टॉगल बार (Retail vs Wholesale)
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isWholesaleMarket ? const Color(0xFFFF5722) : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => isWholesaleMarket = false),
                  icon: const Icon(Icons.shopping_bag, size: 16),
                  label: const Text('🛍️ Retail Marketplace', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWholesaleMarket ? Colors.purple.shade700 : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => isWholesaleMarket = true),
                  icon: const Icon(Icons.inventory_2, size: 16),
                  label: const Text('📦 Wholesale Hub', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        
        // दुकान-वार (Shop-wise) लिस्टिंग डैशबोर्ड
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: ViziagDatabase.registeredShops.map((shop) {
              // इस दुकान के प्रोडक्ट्स फ़िल्टर करें (रिटेल या होलसेल के आधार पर)
              var shopProducts = ViziagDatabase.productInventory.where((p) =>
                p['shopName'] == shop['shopName'] && p['isWholesale'] == isWholesaleMarket
              ).toList();

              if (shopProducts.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // दुकान का बैनर और प्रोफाइल हेडर
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: Image.network(
                            shop['shopBanner'] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e',
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(height: 110, color: Colors.grey),
                          ),
                        ),
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFFF5722),
                                child: Icon(Icons.store, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop['shopName'],
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Owner: ${shop['ownerName']} • ${shop['address']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                    
                    // दुकान के अंदर के सारे आइटम (सेब, अनार, आदि)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: shopProducts.map((prod) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  prod['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Icon(Icons.fastfood, size: 40),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('₹${prod['price']} / ${prod['unit']} • Stock: ${prod['stock']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('🚚 ${prod['deliveryType']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isWholesaleMarket ? Colors.purple : const Color(0xFFFF5722),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('🛒 Ordered ${prod['name']} from ${shop['shopName']}!')),
                                  );
                                },
                                child: const Text('Buy Now', style: TextStyle(fontSize: 11)),
                              )
                            ],
                          ),
                        )).toList(),
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
// TAB 2: VENDOR PORTAL & FIXED IMAGE PICKER
// ==========================================
class VendorPortalManageView extends StatefulWidget {
  const VendorPortalManageView({super.key});

  @override
  State<VendorPortalManageView> createState() => _VendorPortalManageViewState();
}

class _VendorPortalManageViewState extends State<VendorPortalManageView> {
  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();

  String _selectedCategory = 'Fruits & Vegetables';
  String _selectedUnit = 'KG';
  bool _isWholesaleItem = false; // होलसेल या रिटेल चेकबॉक्स
  
  XFile? _pickedImageFile;
  Uint8List? _webImageBytes;
  final ImageSpanPicker = ImagePicker();

  // इमेज पिकर सॉल्यूशन (गैलरी से फोटो उठाने के लिए - वेब और मोबाइल दोनों सपोर्टेड)
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await ImageSpanPicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _pickedImageFile = pickedFile;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _pickedImageFile = pickedFile;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📸 Image loaded successfully from gallery!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _publishProduct() {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item name and price!')));
      return;
    }

    setState(() {
      ViziagDatabase.productInventory.insert(0, {
        'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
        'shopName': ViziagDatabase.currentVendorShop,
        'owner': 'Tarun Kumar',
        'name': _prodNameCtrl.text,
        'category': _selectedCategory,
        'price': double.tryParse(_priceCtrl.text) ?? 100.0,
        'unit': _selectedUnit,
        'stock': int.tryParse(_stockCtrl.text) ?? 20,
        'location': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
        'imageUrl': _pickedImageFile != null 
            ? _pickedImageFile!.path 
            : 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        'isWholesale': _isWholesaleItem,
        'gstRate': '0% GST',
        'deliveryType': _isWholesaleItem ? 'Bulk Delivery Available' : 'Express Delivery'
      });
    });

    _prodNameCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.clear();
    setState(() {
      _pickedImageFile = null;
      _webImageBytes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Product Published Live Successfully on Shop Dashboard!')));
  }

  @override
  Widget build(BuildContext context) {
    var myProducts = ViziagDatabase.productInventory.where((p) => p['shopName'] == ViziagDatabase.currentVendorShop).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // वेंडर शॉप प्रोफाइल हेडर
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.deepOrange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.store, color: Colors.deepOrange, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ViziagDatabase.currentVendorShop, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Status: Active Vendor Dashboard ✅', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('📦 Add New Item to Shop Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // फिक्स्ड इमेज पिकर यूआई
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Item Gallery Photo', border: OutlineInputBorder()),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Pick from Gallery'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _pickedImageFile != null ? _pickedImageFile!.name : 'No image selected',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _prodNameCtrl,
          decoration: const InputDecoration(labelText: 'Item Name (e.g. Kashmiri Apple / Banana Box)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Rate Unit', border: OutlineInputBorder()),
                items: ['KG', 'Piece', 'Dozen', '20 KG Box', 'Packet'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUnit = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _stockCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Available Stock Quantity', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),

        // होलसेल आइटम चेकबॉक्स
        CheckboxListTile(
          title: const Text('List as Wholesale Item (होलसेल मार्केट में दिखाएं)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          value: _isWholesaleItem,
          activeColor: Colors.purple,
          onChanged: (val) => setState(() => _isWholesaleItem = val ?? false),
        ),
        const SizedBox(height: 10),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _publishProduct,
          child: const Text('Publish Item Live 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        const Text('📋 Your Shop Current Inventory', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...myProducts.map((prod) => Card(
          child: ListTile(
            title: Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${prod['price']} / ${prod['unit']} • ${prod['isWholesale'] ? '📦 Wholesale' : '🛍️ Retail'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => ViziagDatabase.productInventory.remove(prod)),
            ),
          ),
        )),
      ],
    );
  }
}

// ==========================================
// TAB 3: ADMIN GATEKEEPER VIEW
// ==========================================
class MasterGatekeeperAdminView extends StatefulWidget {
  const MasterGatekeeperAdminView({super.key});

  @override
  State<MasterGatekeeperAdminView> createState() => _MasterGatekeeperAdminViewState();
}

class _MasterGatekeeperAdminViewState extends State<MasterGatekeeperAdminView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFFFF5722), size: 36),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Gatekeeper Hub', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Approve or Restrict Registered Shops', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('🛡️ Shops Management Directory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...ViziagDatabase.registeredShops.map((shop) {
          bool isApproved = shop['isApproved'];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(shop['shopName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Owner: ${shop['ownerName']} • ${shop['address']}\nStatus: ${isApproved ? 'Active ✅' : 'Locked 🔒'}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApproved ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => setState(() => shop['isApproved'] = !isApproved),
                child: Text(isApproved ? 'Revoke' : 'Approve'),
              ),
            ),
          );
        }),
      ],
    );
  }
}
