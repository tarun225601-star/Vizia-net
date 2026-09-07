// ================= MAIN ENTRY POINT (main.dart) - Bulletproof =================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'cart_and_orders_view.dart';
import 'vendor_auth_and_portal.dart';
import 'admin_master_dashboard.dart';
import 'product_details_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ViziagMartApp());
}

class ViziagMartApp extends StatelessWidget {
  const ViziagMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart Enterprise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFFF59E0B),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCloudProducts();
  }

  Future<void> _fetchCloudProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedList = [];
        data.forEach((key, value) {
          if (value != null) {
            var item = Map<String, dynamic>.from(value);
            item['firebaseKey'] = key;
            fetchedList.add(item);
          }
        });
        if (mounted) {
          setState(() {
            EnterpriseDatabase.globalInventory = fetchedList;
          });
        }
      }
    } catch (e) {
      debugPrint('Cloud fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAdminPinDialog() {
    TextEditingController pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('सुरक्षित एडमिन पिन दर्ज करें', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          maxLength: 10,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'गुप्त पिन डालें...', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            onPressed: () {
              if (pinCtrl.text.trim() == 'tarun#1') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminMasterDashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ गलत एडमिन पिन!'), backgroundColor: Colors.red));
              }
            },
            child: const Text('खोलें'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Shop Marketplace View
      RefreshIndicator(
        onRefresh: _fetchCloudProducts,
        color: const Color(0xFFF59E0B),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(EnterpriseDatabase.activeShopProfile['shopName'] ?? 'मेरी दुकान', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('📍 ${EnterpriseDatabase.activeShopProfile['address'] ?? 'Faridabad'}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('उपलब्ध कैटलॉग (Live Inventory)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
                  )
                : EnterpriseDatabase.globalInventory.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(child: Text('कोई उत्पाद उपलब्ध नहीं है। वेंडर पोर्टल से जोड़ें।', style: TextStyle(color: Colors.grey, fontSize: 11))),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              var item = EnterpriseDatabase.globalInventory[index];
                              bool inStock = item['inStock'] ?? true;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsScreen(product: item),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade800),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          width: double.infinity,
                                          child: const Icon(Icons.eco, color: Color(0xFFF59E0B), size: 36),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1),
                                      Text('₹${item['price']} / ${item['unit'] ?? 'Kg'}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Text(inStock ? '🟢 In Stock' : '🔴 Out of Stock', style: TextStyle(color: inStock ? Colors.green : Colors.red, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: EnterpriseDatabase.globalInventory.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
      // Vendor Portal View
      const VendorAuthAndPortalView(),
      // Cart & Orders View
      const CartAndOrdersView(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('VIZIAG MART', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key, color: Color(0xFFF59E0B), size: 20),
            onPressed: _showAdminPinDialog,
            tooltip: 'Master Admin',
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (val) => setState(() => _currentIndex = val),
        backgroundColor: const Color(0xFF0B0F19),
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Vendor Portal'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart & Orders'),
        ],
      ),
    );
  }
}
