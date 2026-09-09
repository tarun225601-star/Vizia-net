import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database_models.dart';
import 'marketplace_buyer_view.dart';
import 'cart_and_orders_view.dart';
import 'image_picker_helper.dart';
import 'rider_delivery_view.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init warning: $e");
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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CakeMainHubScreen(),
    );
  }
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
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              const Text(
                'VIZIAG MART',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.store, size: 14),
                label: const Text('Shop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.lock_outline, size: 14),
                label: const Text('Vendor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: Row(
                      children: [
                        Icon(Icons.person_pin_circle, color: Colors.green.shade700, size: 15),
                        const SizedBox(width: 6),
                        Text(CakeDatabase.currentCustomerName, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showProfileEditDialog(context),
                    child: Text('(Edit Profile & Address)', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedTabIndex > 3 ? 3 : _selectedTabIndex, children: _tabScreens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedTabIndex = i),
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
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
          title: const Text('Edit Profile & Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Location Note', isDense: true)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
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

class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  int _viewMode = 0;

  final regShopNameCtrl = TextEditingController();
  final regPhoneCtrl = TextEditingController();
  final regAddressCtrl = TextEditingController();
  final regPass1Ctrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();

  final loginPhoneCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();

  final adminCodeCtrl = TextEditingController();
  bool _isLoading = false;

  // Product Controllers for Vendor Dashboard
  final prodNameCtrl = TextEditingController();
  final prodPriceCtrl = TextEditingController();
  final prodDescCtrl = TextEditingController();
  String _selectedCategory = 'Fruits & Veg';
  String _productImageBase64 = '';

  Future<void> _submitRegistration() async {
    if (regPhoneCtrl.text.trim().length < 10 || regShopNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया दुकान का नाम और सही मोबाइल नंबर भरें!'), backgroundColor: Colors.red));
      return;
    }
    if (regPass1Ctrl.text.isEmpty || regPass1Ctrl.text != regPass2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ पासवर्ड मेल नहीं खा रहे हैं!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var shopData = {
        'name': regShopNameCtrl.text.trim(),
        'phone': regPhoneCtrl.text.trim(),
        'address': regAddressCtrl.text.trim().isEmpty ? 'Faridabad' : regAddressCtrl.text.trim(),
        'pass': regPass1Ctrl.text.trim(),
        'status': 'pending',
      };

      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'),
        body: json.encode(shopData),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⏳ रिक्वेस्ट सबमिट हो गई'),
            content: const Text('आपकी दुकान का रजिस्ट्रेशन हो गया है। मास्टर एडमिन (तरुण) द्वारा अप्रूव होने के बाद ही आप लॉगिन कर पाएंगे।'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _viewMode = 0);
                },
                child: const Text('ठीक है'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginVendor() async {
    String phone = loginPhoneCtrl.text.trim();
    String pass = loginPassCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया मोबाइल नंबर और पासवर्ड दर्ज करें!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'));
      bool isApproved = false;

      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        data.forEach((key, val) {
          if (val != null) {
            String vPhone = val['phone']?.toString().trim() ?? '';
            String vPass = val['pass']?.toString().trim() ?? '';
            String vStatus = val['status']?.toString().trim() ?? '';
            if (vPhone == phone && vPass == pass && vStatus == 'approved') {
              isApproved = true;
            }
          }
        });
      }

      if (isApproved) {
        setState(() => _viewMode = 3);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ स्वागत है! वेंडर डैशबोर्ड खुल गया है।'), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ लॉगिन असफल (Not Approved)'),
              content: const Text('आपकी दुकान अभी तक मास्टर एडमिन (तरुण) द्वारा अप्रूव नहीं की गई है! कृपया पहले अप्रूवल लें या सही डिटेल्स भरें।'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है')),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyAdminCode() {
    if (adminCodeCtrl.text.trim() == 'tarun#1') {
      setState(() => _viewMode = 5);
      adminCodeCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ गलत गुप्त कोड!'), backgroundColor: Colors.red));
    }
  }

  Future<void> _addNewProduct() async {
    if (prodNameCtrl.text.isEmpty || prodPriceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया प्रोडक्ट का नाम और कीमत भरें!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var newProduct = {
        'name': prodNameCtrl.text.trim(),
        'price': double.tryParse(prodPriceCtrl.text.trim()) ?? 0.0,
        'category': _selectedCategory,
        'description': prodDescCtrl.text.trim(),
        'image': _productImageBase64,
      };

      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json'),
        body: json.encode(newProduct),
      );

      prodNameCtrl.clear();
      prodPriceCtrl.clear();
      prodDescCtrl.clear();
      setState(() => _productImageBase64 = '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ प्रोडक्ट सफलतापूर्वक लाइव जोड़ दिया गया!'), backgroundColor: Colors.green));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode == 0) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 75, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🛍️ वेंडर पोर्टल', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('बिना एडमिन अप्रूवल के कोई भी वेंडर लॉगिन नहीं कर सकता', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: () => setState(() => _viewMode = 1),
                icon: const Icon(Icons.person_add),
                label: const Text('नई दुकान रजिस्टर करें (New Registration)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green, width: 2), foregroundColor: Colors.green.shade800),
                onPressed: () => setState(() => _viewMode = 2),
                icon: const Icon(Icons.login),
                label: const Text('वेंडर लॉगिन (Existing Vendor Login)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),

            const Spacer(),
            const Divider(),
            TextButton.icon(
              onPressed: () => setState(() => _viewMode = 4),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.green),
              label: const Text('मास्टर शॉप अप्रूवल डैशबोर्ड (Admin)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 1) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            const Center(child: Text('📝 नया वेंडर रजिस्ट्रेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            TextField(controller: regShopNameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम (Shop Name)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 15),
            TextField(controller: regPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: regAddressCtrl, decoration: const InputDecoration(labelText: 'दुकान का पता / लोकेशन', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 15),
            TextField(controller: regPass1Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड बनाएं', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 15),
            TextField(controller: regPass2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड दोबारा दर्ज करें', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _submitRegistration,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('अप्रूवल के लिए सबमिट करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    if (_viewMode == 2) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 65, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🔐 वेंडर लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('पहले एडमिन से अप्रूव कराना अनिवार्य है', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 25),
            TextField(controller: loginPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: loginPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _loginVendor,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('लॉगिन करें ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    // 3: Vendor Dashboard (Products Add View)
    if (_viewMode == 3) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                const Text('📦 वेंडर डैशबोर्ड (प्रोडक्ट जोड़ें)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => setState(() => _viewMode = 0), icon: const Icon(Icons.logout, color: Colors.red)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(controller: prodNameCtrl, decoration: const InputDecoration(labelText: 'प्रोडक्ट का नाम', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: prodPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'कीमत (₹)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'कैटेगरी', border: OutlineInputBorder()),
              items: ['Fruits & Veg', 'Bakery & Sweets', 'Dairy & Eggs', 'Snacks & Drinks'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val ?? 'Fruits & Veg'),
            ),
            const SizedBox(height: 15),
            TextField(controller: prodDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'प्रोडक्ट विवरण (Description)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Center(
              child: Column(
                children: [
                  buildShopOrProdImage(_productImageBase64, 100, 100, Icons.fastfood),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      String? base64Img = await pickAndConvertToBase64();
                      if (base64Img != null) {
                        setState(() => _productImageBase64 = base64Img);
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('प्रोडक्ट फोटो चुनें'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _addNewProduct,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('प्रोडक्ट लाइव करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    // 4: Master Admin Login
    if (_viewMode == 4) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 65, color: Colors.green),
            const SizedBox(height: 15),
            const Text('👑 मास्टर एडमिन लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            TextField(controller: adminCodeCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'गुप्त कोड दर्ज करें (Admin Code)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.security))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _verifyAdminCode,
                child: const Text('वेरिफाई करें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    // 5: Master Panel (Approve pending vendors)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👑 मास्टर अप्रूवल पैनल', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => setState(() => _viewMode = 0), icon: const Icon(Icons.arrow_back)),
            ],
          ),
          const Text('यहाँ से नई दुकानों को अप्रूव करें:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Divider(),
          Expanded(
            child: FutureBuilder<http.Response>(
              future: http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json')),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data?.body == 'null' || snapshot.data?.body.isEmpty == true) {
                  return const Center(child: Text('कोई पेंडिंग रिक्वेस्ट नहीं है'));
                }
                Map<String, dynamic> data = json.decode(snapshot.data!.body);
                List<MapEntry<String, dynamic>> items = data.entries.toList();

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var key = items[index].key;
                    var val = items[index].value;
                    String status = val['status'] ?? 'pending';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(val['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('📞 ${val['phone']} | पता: ${val['address']}\nस्थिति: $status'),
                        isThreeLine: true,
                        trailing: status == 'pending'
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(60, 32)),
                                onPressed: () async {
                                  await http.patch(
                                    Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests/$key.json'),
                                    body: json.encode({'status': 'approved'}),
                                  );
                                  setState(() {});
                                },
                                child: const Text('Approve', style: TextStyle(fontSize: 11)),
                              )
                            : const Chip(backgroundColor: Colors.greenAccent, label: Text('Approved', style: TextStyle(fontSize: 10))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// [ऊपर वाले कोड के बाद का बचा हुआ पूरा हिस्सा - MarketplaceBuyerView, CartAndOrdersView, RiderDeliveryScreen, और CakeDatabase]

class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'फ्रूट्स, सब्जियां या अन्य सामान खोजें...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Fruits & Veg', 'Bakery & Sweets', 'Dairy & Eggs', 'Snacks & Drinks'].map((cat) {
                    bool isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.green.shade700,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                        onSelected: (selected) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Product Catalog FutureBuilder
        Expanded(
          child: FutureBuilder<http.Response>(
            future: http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/products.json')),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.green));
              }
              if (!snapshot.hasData || snapshot.data?.body == 'null' || snapshot.data?.body.isEmpty == true) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text('अभी कोई प्रोडक्ट उपलब्ध नहीं है!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              Map<String, dynamic> data = json.decode(snapshot.data!.body);
              List<Map<String, dynamic>> products = [];
              data.forEach((key, val) {
                if (val != null) {
                  var p = Map<String, dynamic>.from(val);
                  p['id'] = key;
                  products.add(p);
                }
              });

              // Filter by category & search query
              var filteredProducts = products.where((p) {
                bool matchesCategory = _selectedCategory == 'All' || p['category'] == _selectedCategory;
                bool matchesSearch = (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                return matchesCategory && matchesSearch;
              }).toList();

              if (filteredProducts.isEmpty) {
                return const Center(child: Text('कोई प्रोडक्ट नहीं मिला!', style: TextStyle(color: Colors.grey)));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  var product = filteredProducts[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: buildShopOrProdImage(product['image'], double.infinity, double.infinity, Icons.fastfood),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('₹${product['price']}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w900, fontSize: 14)),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: EdgeInsets.zero),
                                  onPressed: () {
                                    setState(() {
                                      CakeDatabase.addToCart(product);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${product['name']} कार्ट में जोड़ दिया गया!'), duration: const Duration(seconds: 1)),
                                    );
                                  },
                                  child: const Text('कार्ट में डालें', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CartAndOrdersView extends StatefulWidget {
  const CartAndOrdersView({super.key});

  @override
  State<CartAndOrdersView> createState() => _CartAndOrdersViewState();
}

class _CartAndOrdersViewState extends State<CartAndOrdersView> {
  Future<void> _placeOrder() async {
    if (CakeDatabase.cartItems.isEmpty) return;

    double totalAmount = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0) * ((item['qty'] as num?)?.toInt() ?? 1));

    var orderData = {
      'customerName': CakeDatabase.currentCustomerName,
      'phone': CakeDatabase.currentUserPhone,
      'address': CakeDatabase.currentDeliveryAddress,
      'items': CakeDatabase.cartItems,
      'total': totalAmount,
      'status': 'Pending',
      'time': DateTime.now().toString(),
    };

    try {
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
            title: const Text('🎉 आर्डर सफल!'),
            content: const Text('आपका आर्डर सफलतापूर्वक प्लेस हो गया है। जल्द ही डिलीवरी पार्टनर आपके पास पहुंचेगा।'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ आर्डर भेजने में त्रुटि: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = CakeDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0) * ((item['qty'] as num?)?.toInt() ?? 1));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🛒 आपकी शॉपिंग कार्ट', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: CakeDatabase.cartItems.isEmpty
                ? const Center(child: Text('कार्ट खाली है!', style: TextStyle(color: Colors.grey, fontSize: 15)))
                : ListView.builder(
                    itemCount: CakeDatabase.cartItems.length,
                    itemBuilder: (context, index) {
                      var item = CakeDatabase.cartItems[index];
                      int qty = item['qty'] ?? 1;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('मूल्य: ₹${item['price']} x $qty = ₹${(item['price'] * qty)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    if (qty > 1) {
                                      item['qty'] = qty - 1;
                                    } else {
                                      CakeDatabase.cartItems.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                onPressed: () {
                                  setState(() {
                                    item['qty'] = qty + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (CakeDatabase.cartItems.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('कुल राशि (Total):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('₹$totalAmount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green.shade800)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _placeOrder,
                child: const Text('आर्डर कंफर्म करें (Place Order)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RiderDeliveryScreen extends StatelessWidget {
  const RiderDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<http.Response>(
        future: http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data?.body == 'null' || snapshot.data?.body.isEmpty == true) {
            return const Center(child: Text('कोई डिलीवरी आर्डर उपलब्ध नहीं है'));
          }

          Map<String, dynamic> data = json.decode(snapshot.data!.body);
          List<MapEntry<String, dynamic>> orders = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var key = orders[index].key;
              var val = orders[index].value;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('आर्डर ID: ${key.substring(0, 6)}...', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const Spacer(),
                          Chip(label: Text(val['status'] ?? 'Pending', style: const TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: Colors.orange),
                        ],
                      ),
                      const Divider(),
                      Text('ग्राहका नाम: ${val['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('मोबाइल: ${val['phone']}'),
                      Text('पता: ${val['address']}'),
                      const SizedBox(height: 6),
                      Text('कुल राशि: ₹${val['total']}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CakeDatabase {
  static String firebaseRestUrl = "https://viziag-mart-default-rtdb.firebaseio.com";
  static String currentCustomerName = "Tarun Kumar";
  static String currentUserPhone = "9971968060";
  static String currentDeliveryAddress = "Faridabad, Haryana";

  static List<Map<String, dynamic>> cartItems = [];

  static void addToCart(Map<String, dynamic> product) {
    var existing = cartItems.firstWhere((item) => item['id'] == product['id'], orElse: () => {});
    if (existing.isNotEmpty) {
      existing['qty'] = (existing['qty'] ?? 1) + 1;
    } else {
      var newItem = Map<String, dynamic>.from(product);
      newItem['qty'] = 1;
      cartItems.add(newItem);
    }
  }
}
