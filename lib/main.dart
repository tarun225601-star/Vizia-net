import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
        primaryColor: const Color(0xFFFF5722),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'sans-serif',
      ),
      home: const ViziagHomePortal(),
    );
  }
}

// Global App State & Database Memory
class AppMemory {
  static String firebaseDatabaseUrl = "https://viziag-mart-default-rtdb.firebaseio.com/";
  
  static List<Map<String, dynamic>> products = [
    {
      'shopName': 'Tarun fruit shop',
      'name': 'Apple',
      'price': 100.0,
      'unit': 'KG',
      'location': 'Sector 15a ajronda sabji mandi faridabad',
      'inStock': true,
    },
    {
      'shopName': 'Tarun fruit shop',
      'name': 'Banana',
      'price': 70.0,
      'unit': 'Piece',
      'location': 'Sector 15a ajronda sabji mandi faridabad',
      'inStock': true,
    },
    {
      'shopName': 'Tarun fruit shop',
      'name': 'Roya gala apple',
      'price': 300.0,
      'unit': 'KG',
      'location': 'Sector 15a ajronda sabji mandi faridabad',
      'inStock': true,
    },
  ];

  static List<Map<String, dynamic>> shops = [
    {
      'name': 'Tarun fruit shop',
      'owner': 'Tarun kumar',
      'phone': '9971968060',
      'isApproved': true, // True = Live, False = Locked by Admin Gatekeeper
      'isBanned': false,
    }
  ];
}

// Main Hub combining Header Navigation just like your HTML screenshot
class ViziagHomePortal extends StatefulWidget {
  const ViziagHomePortal({super.key});

  @override
  State<ViziagHomePortal> createState() => _ViziagHomePortalState();
}

class _ViziagHomePortalState extends State<ViziagHomePortal> {
  int _currentIndex = 0; // 0: Marketplace, 1: Vendor Portal, 2: Admin Panel

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
                'Viziag\nMart',
                style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
              ),
              const Spacer(),
              // Top Navigation Buttons just like your screenshot header
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentIndex == 0 ? const Color(0xFFFF5722) : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
                icon: const Icon(Icons.home, size: 16),
                label: const Text('Marketplace', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentIndex == 1 ? const Color(0xFFFF5722) : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Icon(Icons.store, size: 16),
                label: const Text('Vendor Portal', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MarketplaceTabView(),
          VendorPortalTabView(),
        ],
      ),
      // Bottom Bar with Settings Shortcut
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF5722),
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const FirebaseSettingsScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shop Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Firebase Config'),
        ],
      ),
    );
  }
}

// 1. MARKETPLACE TAB VIEW (Exact replica of your Buyer UI Screenshot)
class MarketplaceTabView extends StatefulWidget {
  const MarketplaceTabView({super.key});

  @override
  State<MarketplaceTabView> createState() => _MarketplaceTabViewState();
}

class _MarketplaceTabViewState extends State<MarketplaceTabView> {
  String buyerName = "Tarun kumar";
  String buyerPhone = "9971968060";
  bool isVerifiedBuyer = true;

  void _openBuyerLoginModal() {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController(text: buyerName);
        final phoneCtrl = TextEditingController(text: buyerPhone);
        return AlertDialog(
          title: const Text('👤 Buyer Details & Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number (10 Digits)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  buyerName = nameCtrl.text;
                  buyerPhone = phoneCtrl.text;
                  isVerifiedBuyer = true;
                });
                Navigator.pop(context);
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
    return Column(
      children: [
        // Top Banner like your screenshot: "Verified Buyer: Tarun kumar (Logout)"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Text('Local Hyper-Local Market', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              GestureDetector(
                onTap: _openBuyerLoginModal,
                child: Text(
                  isVerifiedBuyer ? '✅ Verified Buyer: $buyerName' : 'Login / Register',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Product List Grid/Cards
        Expanded(
          child: ListView.builder(
            itemCount: AppMemory.products.length,
            itemBuilder: (context, index) {
              var p = AppMemory.products[index];
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood, size: 40, color: Colors.deepOrange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text(p['shopName'], style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text(p['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('₹${p['price']} (${p['unit']})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                            const Text('🚚 Home Delivery Available', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('📍 ${p['location']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white).wrap(
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order placed for ${p['name']}!')));
                                  },
                                  child: const Text('🛒 Add to Cart'),
                                ),
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

// 2. VENDOR PORTAL TAB VIEW (Exact replica of your Vendor Form & Product Upload Screenshot)
class VendorPortalTabView extends StatefulWidget {
  const VendorPortalTabView({super.key});

  @override
  State<VendorPortalTabView> createState() => _VendorPortalTabViewState();
}

class _VendorPortalTabViewState extends State<VendorPortalTabView> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String selectedUnit = 'Per KG';
  String selectedGst = '0% GST (Tax Free)';
  String selectedDelivery = 'Home Delivery Available';

  void _publishProduct() {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
    setState(() {
      AppMemory.products.add({
        'shopName': 'Tarun fruit shop',
        'name': nameCtrl.text,
        'price': double.parse(priceCtrl.text),
        'unit': selectedUnit,
        'location': 'Sector 15a ajronda sabji mandi faridabad',
        'inStock': true,
      });
    });
    nameCtrl.clear();
    priceCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Published Live Successfully! 🚀')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vendor Header
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tarun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                Text('Mobile: 9971968060', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                // Master Admin Panel Shortcut for testing gatekeeper
                Navigator.push(context, MaterialPageRoute(builder: (c) => const MasterAdminGatekeeperScreen()));
              },
              icon: const Icon(Icons.admin_panel_settings, size: 16),
              label: const Text('Admin Gatekeeper'),
            ),
          ],
        ),
        const Divider(height: 30),
        const Text('📦 Add / Manage Product Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // Product Photo Field
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Product Photo', border: OutlineInputBorder()),
          child: Row(
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Choose File')),
              const SizedBox(width: 10),
              const Text('No file chosen', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name (e.g. Samosa / Apple)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: selectedUnit,
          decoration: const InputDecoration(labelText: 'Pricing Type (Rate Type)', border: OutlineInputBorder()),
          items: ['Per Piece', 'Per KG', 'Per Jar'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => selectedUnit = val!),
        ),
        const SizedBox(height: 12),
        
        TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: selectedGst,
          decoration: const InputDecoration(labelText: 'GST Rate (%)', border: OutlineInputBorder()),
          items: ['0% GST (Tax Free)', '5% GST', '12% GST'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => selectedGst = val!),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedDelivery,
          decoration: const InputDecoration(labelText: 'Delivery Option', border: OutlineInputBorder()),
          items: ['Home Delivery Available', 'Pickup Only', '10 Min Express'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => selectedDelivery = val!),
        ),
        const SizedBox(height: 15),

        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
          onPressed: _publishProduct,
          child: const Text('Publish Product Live 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 25),
        const Text('📋 Your Uploaded Items (Compact View)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // List of uploaded items
        ...AppMemory.products.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${p['price']} (${p['unit']})\nStatus: In Stock ✅'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => AppMemory.products.remove(p)),
            ),
          ),
        )),
      ],
    );
  }
}

// 3. MASTER ADMIN GATEKEEPER SCREEN (Where company controls shop activation & instant ban)
class MasterAdminGatekeeperScreen extends StatefulWidget {
  const MasterAdminGatekeeperScreen({super.key});

  @override
  State<MasterAdminGatekeeperScreen> createState() => _MasterAdminGatekeeperScreenState();
}

class _MasterAdminGatekeeperScreenState extends State<MasterAdminGatekeeperScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Admin Gatekeeper Panel'), backgroundColor: Colors.black),
      body: ListView.builder(
        itemCount: AppMemory.shops.length,
        itemBuilder: (context, index) {
          var s = AppMemory.shops[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Owner: ${s['owner']} • Phone: ${s['phone']}\nApproval Status: ${s['isApproved'] ? 'Active ✅' : 'Locked 🔒'}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: s['isApproved'] ? Colors.red : Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() {
                        s['isApproved'] = !s['isApproved'];
                      });
                    },
                    child: Text(s['isApproved'] ? 'Revoke' : 'Approve Shop'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 4. Firebase Config Screen
class FirebaseSettingsScreen extends StatefulWidget {
  const FirebaseSettingsScreen({super.key});

  @override
  State<FirebaseSettingsScreen> createState() => _FirebaseSettingsScreenState();
}

class _FirebaseSettingsScreenState extends State<FirebaseSettingsScreen> {
  final urlCtrl = TextEditingController(text: AppMemory.firebaseDatabaseUrl);

  _save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fb_url', urlCtrl.text);
    AppMemory.firebaseDatabaseUrl = urlCtrl.text;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase URL Saved!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Backend URL'), backgroundColor: Colors.black87),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Firebase Realtime DB URL', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: _save,
              child: const Text('Save Configuration'),
            ),
          ],
        ),
      ),
    );
  }
}
