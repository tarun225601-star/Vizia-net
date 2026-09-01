import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
// CENTRAL DATABASE MODEL & SHARED APP STATE
// ==========================================
class ViziagDatabase {
  static String firebaseRestUrl = "https://viziag-mart-default-rtdb.firebaseio.com/";
  static String activeCityZone = "Faridabad, Delhi & Gurgaon";
  
  // Buyer Session State
  static String currentBuyerName = "Tarun Kumar";
  static String currentBuyerPhone = "9971968060";
  static bool isBuyerLoggedIn = true;

  // Vendor Session State
  static String currentVendorShop = "Tarun Fruit & Vegetable Shop";
  static String currentVendorPhone = "9971968060";
  static bool isVendorApproved = true;

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
      'isAvailable': true,
      'gstRate': '0% GST (Tax Free)',
      'deliveryType': '15 Min Express Delivery'
    },
    {
      'id': 'p_102',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'owner': 'Tarun Kumar',
      'name': 'Organic Cavendish Bananas',
      'category': 'Fruits & Vegetables',
      'price': 60.0,
      'unit': 'Dozen',
      'stock': 30,
      'location': 'Sector 15A, Ajronda Sabji Mandi, Faridabad',
      'imageUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e',
      'isAvailable': true,
      'gstRate': '0% GST (Tax Free)',
      'deliveryType': 'Home Delivery Available'
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
      'isAvailable': true,
      'gstRate': '5% GST',
      'deliveryType': 'Same Day Delivery'
    },
    {
      'id': 'p_104',
      'shopName': 'Sharma Dairy & Milk Booth',
      'owner': 'Ramesh Sharma',
      'name': 'Amul Taaza Toned Fresh Milk',
      'category': 'Dairy & Bakery',
      'price': 32.0,
      'unit': '500 ML Packet',
      'stock': 100,
      'location': 'Nehru Ground, NIT Faridabad',
      'imageUrl': 'https://images.unsplash.com/photo-1550583724-b2692b85b150',
      'isAvailable': true,
      'gstRate': '0% GST (Tax Free)',
      'deliveryType': 'Morning Express (6 AM)'
    },
  ];

  // Registered Shops Directory for Gatekeeper Admin Control
  static List<Map<String, dynamic>> registeredShops = [
    {
      'shopId': 'shop_01',
      'shopName': 'Tarun Fruit & Vegetable Shop',
      'ownerName': 'Tarun Kumar',
      'phone': '9971968060',
      'category': 'Sabji & Fruits',
      'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
      'isApproved': true,
      'isBanned': false,
      'registeredDate': '2026-01-15'
    },
    {
      'shopId': 'shop_02',
      'shopName': 'Shree Balaji Kirana Store',
      'ownerName': 'Mukesh Gupta',
      'phone': '9811223344',
      'category': 'Grocery & Staples',
      'address': 'Sector 16 Market, Faridabad',
      'isApproved': true,
      'isBanned': false,
      'registeredDate': '2026-02-01'
    },
    {
      'shopId': 'shop_03',
      'shopName': 'Aggarwal Sweets & Namkeen',
      'ownerName': 'Anil Aggarwal',
      'phone': '9911887766',
      'category': 'Snacks & Sweets',
      'address': 'Mathura Road, Bata Chowk, Faridabad',
      'isApproved': false, // Pending Gatekeeper Approval
      'isBanned': false,
      'registeredDate': '2026-03-01'
    }
  ];

  // Customer Orders Cart / History
  static List<Map<String, dynamic>> activeOrders = [];
}

// ==========================================
// MAIN NAVIGATION HUB (Black Top Bar & Tabs)
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
              // Logo & Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Viziag Mart',
                    style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    ViziagDatabase.activeCityZone,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              const Spacer(),
              // Top Quick Nav Buttons
              _buildHeaderNavButton('Marketplace', Icons.shopping_bag, 0),
              const SizedBox(width: 4),
              _buildHeaderNavButton('Vendor', Icons.storefront, 1),
              const SizedBox(width: 4),
              _buildHeaderNavButton('Gatekeeper', Icons.admin_panel_settings, 2),
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
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Buyer Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop Portal'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Admin Panel'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        tooltip: 'Firebase DB Settings',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => const FirebaseBackendConfigScreen()));
        },
        child: const Icon(Icons.settings_input_component),
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
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: MARKETPLACE BUYER VIEW
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String selectedCategoryFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  void _openBuyerLoginModal() {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController(text: ViziagDatabase.currentBuyerName);
        final phoneCtrl = TextEditingController(text: ViziagDatabase.currentBuyerPhone);
        return AlertDialog(
          title: const Text('👤 Buyer Identity & Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number (10 Digits)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  ViziagDatabase.currentBuyerName = nameCtrl.text;
                  ViziagDatabase.currentBuyerPhone = phoneCtrl.text;
                  ViziagDatabase.isBuyerLoggedIn = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buyer profile updated successfully!')));
              },
              child: const Text('Save & Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredProducts = ViziagDatabase.productInventory.where((p) {
      bool matchesCategory = selectedCategoryFilter == 'All' || p['category'] == selectedCategoryFilter;
      bool matchesSearch = p['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           p['shopName'].toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Buyer Status Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.amber.shade100,
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.deepOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified Buyer: ${ViziagDatabase.currentBuyerName} (${ViziagDatabase.currentBuyerPhone})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _openBuyerLoginModal,
                child: const Text('Change', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        // Search & Filter Header
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search local items (e.g. Apple, Milk, Atta)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() {}); })
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 10),
              // Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Fruits & Vegetables', 'Groceries & Staples', 'Dairy & Bakery'].map((cat) {
                    bool isSelected = selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF5722),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        onSelected: (selected) {
                          setState(() {
                            selectedCategoryFilter = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Products List Grid/Cards
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(child: Text('No hyper-local items found in this category.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    var prod = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 85,
                                height: 85,
                                color: Colors.grey.shade200,
                                child: Image.network(
                                  prod['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Icon(Icons.store, size: 40, color: Colors.deepOrange),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      prod['shopName'],
                                      style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    prod['name'],
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${prod['price']} (${prod['unit']}) • ${prod['gstRate']}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '🚚 ${prod['deliveryType']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  Text(
                                    '📍 ${prod['location']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53935),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          ViziagDatabase.activeOrders.add({
                                            'item': prod['name'],
                                            'price': prod['price'],
                                            'shop': prod['shopName'],
                                            'buyer': ViziagDatabase.currentBuyerName,
                                            'time': DateTime.now().toString()
                                          });
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('🛒 Order Placed successfully for ${prod['name']}!')),
                                        );
                                      },
                                      icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                                      label: const Text('Instant Buy / Cart Order', style: TextStyle(fontSize: 12)),
                                    ),
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
        ),
      ],
    );
  }
}

// ==========================================
// TAB 2: VENDOR PORTAL & ITEM MANAGEMENT VIEW
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
  String _selectedGst = '0% GST (Tax Free)';
  String _selectedDeliveryOption = 'Home Delivery Available';

  void _publishProductLive() {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter product name and price!')));
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
        'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c53300491e',
        'isAvailable': true,
        'gstRate': _selectedGst,
        'deliveryType': _selectedDeliveryOption
      });
    });

    _prodNameCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Product Published Live Successfully on Viziag Mart!')));
  }

  @override
  Widget build(BuildContext context) {
    var vendorProducts = ViziagDatabase.productInventory.where((p) => p['shopName'] == ViziagDatabase.currentVendorShop).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vendor Header Banner
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
                    Text('Owner: Tarun Kumar • Ph: ${ViziagDatabase.currentVendorPhone}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text('Status: Active & Live ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('📦 Add / Manage Product Item (Vendor Form)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Photo Upload Fake Simulator
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Product Photo Attachment', border: OutlineInputBorder()),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera / Gallery opened successfully!')));
                },
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Choose File'),
              ),
              const SizedBox(width: 12),
              const Text('No file chosen', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _prodNameCtrl,
          decoration: const InputDecoration(labelText: 'Product Name (e.g. Samosa, Apple, Atta)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(labelText: 'Product Category', border: OutlineInputBorder()),
          items: ['Fruits & Vegetables', 'Groceries & Staples', 'Dairy & Bakery', 'Fast Food & Snacks']
              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Rate Type', border: OutlineInputBorder()),
                items: ['KG', 'Piece', 'Dozen', 'Packet', '10 KG Pack']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUnit = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGst,
                decoration: const InputDecoration(labelText: 'GST Rate', border: OutlineInputBorder()),
                items: ['0% GST (Tax Free)', '5% GST', '12% GST', '18% GST']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGst = val!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Qty', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedDeliveryOption,
          decoration: const InputDecoration(labelText: 'Delivery Offering', border: OutlineInputBorder()),
          items: ['Home Delivery Available', '15 Min Express Delivery', 'Pickup Only', 'Same Day Delivery']
              .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (val) => setState(() => _selectedDeliveryOption = val!),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _publishProductLive,
          child: const Text('Publish Product Live 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 25),
        const Text('📋 Your Uploaded Inventory List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Live Uploaded Items List
        ...vendorProducts.map((vp) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(vp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Price: ₹${vp['price']} (${vp['unit']}) • Stock: ${vp['stock']}\nDelivery: ${vp['deliveryType']}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () {
                setState(() {
                  ViziagDatabase.productInventory.remove(vp);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully!')));
              },
            ),
          ),
        )),
      ],
    );
  }
}

// ==========================================
// TAB 3: MASTER ADMIN GATEKEEPER VIEW
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
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFFFF5722), size: 36),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Master Admin Gatekeeper', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Control Shop Approvals & Security Bans', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('🛡️ Registered Shops Directory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...ViziagDatabase.registeredShops.map((shop) {
          bool isApproved = shop['isApproved'];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            child: ListTile(
              title: Text(shop['shopName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Owner: ${shop['ownerName']} • Ph: ${shop['phone']}\nAddress: ${shop['address']}\nStatus: ${isApproved ? 'Active & Verified ✅' : 'Locked (Pending Review) 🔒'}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApproved ? Colors.red.shade700 : Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    shop['isApproved'] = !isApproved;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Shop status updated for ${shop['shopName']}!')),
                  );
                },
                child: Text(isApproved ? 'Revoke' : 'Approve'),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ==========================================
// FIREBASE BACKEND CONFIG SCREEN
// ==========================================
class FirebaseBackendConfigScreen extends StatefulWidget {
  const FirebaseBackendConfigScreen({super.key});

  @override
  State<FirebaseBackendConfigScreen> createState() => _FirebaseBackendConfigScreenState();
}

class _FirebaseBackendConfigScreenState extends State<FirebaseBackendConfigScreen> {
  final TextEditingController _urlController = TextEditingController(text: ViziagDatabase.firebaseRestUrl);

  void _saveConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_url', _urlController.text);
    ViziagDatabase.firebaseRestUrl = _urlController.text;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔥 Firebase Realtime Database URL Saved & Applied Successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Backend Database'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure Backend Database',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Firebase Realtime Database or Firestore REST endpoint URL below so the app can sync data dynamically without hard-coding.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Firebase Database URL',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveConfiguration,
                child: const Text('Save & Apply Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
