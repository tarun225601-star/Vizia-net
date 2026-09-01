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
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

// Global Mock Database & Config Storage
class AppDatabase {
  static String firebaseDatabaseUrl = "https://viziag-mart-default-rtdb.firebaseio.com/"; // Default fallback

  static List<Map<String, dynamic>> shops = [
    {
      'id': 'shop_1',
      'name': 'Tarun Fruit Shop',
      'owner': 'Tarun Kumar',
      'phone': '9971968060',
      'location': 'Sector 15a Faridabad',
      'isApproved': true,
      'isBanned': false,
    }
  ];

  static List<Map<String, dynamic>> products = [
    {
      'shopId': 'shop_1',
      'shopName': 'Tarun fruit shop',
      'name': '20L Water Jar (10 Min Delivery)',
      'price': 40.0,
      'unit': 'Jar',
      'location': 'Sector 15a Faridabad',
      'inStock': true,
    },
  ];
}

// 1. Role Selection Screen
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viziag Mart - HyperLocal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Firebase & App Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AppSettingsScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.storefront, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Viziag Mart',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Faridabad, Delhi & Gurgaon Secure Marketplace',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerMarketplaceScreen())),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('I am a Buyer (Marketplace)', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorLoginScreen())),
              icon: const Icon(Icons.store),
              label: const Text('Vendor Portal (Shop Login)', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), side: const BorderSide(color: Colors.deepOrange)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen())),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.deepOrange),
              label: const Text('Master Admin Panel (Gatekeeper)', style: TextStyle(color: Colors.black, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. App Settings Screen (To dynamic input Firebase URL)
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _urlController = TextEditingController(text: AppDatabase.firebaseDatabaseUrl);

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  // Load saved Firebase URL from phone memory
  _loadSavedUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('firebase_url') ?? AppDatabase.firebaseDatabaseUrl;
    });
  }

  // Save Firebase URL dynamically
  _saveUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_url', _urlController.text.trim());
    AppDatabase.firebaseDatabaseUrl = _urlController.text.trim();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Firebase URL Updated & Saved Successfully! 🚀')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase & Backend Settings'), backgroundColor: Colors.black87),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure Backend Database',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your Firebase Realtime Database or Firestore REST endpoint URL below so the app can sync data dynamically without hard-coding.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Firebase Database URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: _saveUrl,
              child: const Text('Save & Apply Configuration', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Buyer Marketplace Screen
class BuyerMarketplaceScreen extends StatelessWidget {
  const BuyerMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viziag Mart [Marketplace]'), backgroundColor: Colors.deepOrange),
      body: ListView.builder(
        itemCount: AppDatabase.products.length,
        itemBuilder: (context, index) {
          final product = AppDatabase.products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.deepOrange, child: Icon(Icons.water_drop, color: Colors.white)),
              title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${product['shopName']} • ${product['location']}\nPrice: ₹${product['price']}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order Placed! 10-minute delivery assigned.')),
                  );
                },
                child: const Text('Buy Now'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 4. Vendor Login Screen (With Approval Lock Check)
class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _phoneController = TextEditingController(text: '9971968060');
  final _shopNameController = TextEditingController(text: 'Tarun Fruit Shop');

  void _loginVendor(BuildContext context) {
    String phone = _phoneController.text.trim();
    String shopName = _shopNameController.text.trim();

    var existingShop = AppDatabase.shops.firstWhere(
      (s) => s['phone'] == phone,
      orElse: () => {},
    );

    if (existingShop.isEmpty) {
      existingShop = {
        'id': 'shop_${DateTime.now().millisecondsSinceEpoch}',
        'name': shopName,
        'phone': phone,
        'isApproved': false, // Locked until company approves
        'isBanned': false,
      };
      AppDatabase.shops.add(existingShop);
    }

    if (existingShop['isBanned'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Banned by Admin!')));
      return;
    }

    if (existingShop['isApproved'] == false) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => PendingScreen(shopName: shopName)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => VendorDashboard(shopName: shopName)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Portal Login'), backgroundColor: Colors.black87),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _shopNameController, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => _loginVendor(context),
              child: const Text('Login to Shop'),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Pending Approval Screen
class PendingScreen extends StatelessWidget {
  final String shopName;
  const PendingScreen({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shopName), backgroundColor: Colors.red),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            '🔒 Verification Pending!\n\nYour shop is in draft mode. Company admin physical verification is required to unlock.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// 6. Vendor Dashboard
class VendorDashboard extends StatelessWidget {
  final String shopName;
  const VendorDashboard({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$shopName [Active]'), backgroundColor: Colors.black),
      body: const Center(child: Text('Welcome to your active vendor dashboard!')),
    );
  }
}

// 7. Master Admin Panel
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Admin Panel'), backgroundColor: Colors.red.shade900),
      body: ListView.builder(
        itemCount: AppDatabase.shops.length,
        itemBuilder: (context, index) {
          var shop = AppDatabase.shops[index];
          return Card(
            child: ListTile(
              title: Text(shop['name']),
              subtitle: Text('Status: ${shop['isApproved'] ? 'Active ✅' : 'Pending 🔒'}'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: shop['isApproved'] ? Colors.grey : Colors.green),
                onPressed: () {
                  setState(() {
                    shop['isApproved'] = !shop['isApproved'];
                  });
                },
                child: Text(shop['isApproved'] ? 'Revoke' : 'Approve'),
              ),
            ),
          );
        },
      ),
    );
  }
}
