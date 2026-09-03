import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // 📍 जीपीएस लोकेशन के लिए जरूरी पैकेज

void main() {
  runApp(const ViziagMartEnterpriseApp());
}

class ViziagMartEnterpriseApp extends StatelessWidget {
  const ViziagMartEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart - HyperLocal Mandi Marketplace',
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
  
  // टेम्पो / डिलीवरी पार्टनर डेटा मॉडल
  static Map<String, dynamic> tempoDriverProfile = {
    'driverName': 'राजेश कुमार (Tempo Driver)',
    'driverPhone': '9876543210',
    'vehicleNumber': 'HR-51-AB-1234',
    'vehicleModel': 'Mahindra Supro Delivery Van',
    'currentLocationName': 'Sector 15A Mandi Gate',
    'latitude': 28.4089,
    'longitude': 77.3178,
    'isAvailable': true,
  };

  static List<Map<String, dynamic>> mandisList = [
    {
      'mandiId': 'dabua_mandi',
      'mandiName': 'डबुआ मंडी (Dabua Mandi)',
      'location': 'Faridabad',
      'shops': [
        {
          'shopId': 'shop_01',
          'shopName': 'Tarun Fruit & Vegetable Shop',
          'shopNumber': 'Shop No. 12',
          'ownerName': 'Tarun Kumar',
          'ownerPhotoPath': '', 
          'phone': '9971968060',
          'whatsappNumber': '919971968060',
          'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
          'shopBannerPath': '', 
          'bio': 'अजोंदा की सबसे विश्वसनीय दुकान। ताज़ा फल और सब्जियां उचित दामों पर उपलब्ध।',
          'isOpen': true,
        }
      ]
    },
    {
      'mandiId': 'old_mandi',
      'mandiName': 'ओल्ड मंडी (Old Mandi Faridabad)',
      'location': 'Old Faridabad',
      'shops': []
    },
    {
      'mandiId': 'ballabhgarh_mandi',
      'mandiName': 'बल्लभगढ़ मंडी (Ballabhgarh Mandi)',
      'location': 'Ballabhgarh',
      'shops': []
    }
  ];

  static List<Map<String, dynamic>> productInventory = [];
  static List<Map<String, dynamic>> cartItems = [];
  static List<Map<String, dynamic>> fetchedCustomerOrders = [];
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
    const MandiDirectoryView(), 
    const VendorAuthAndPortalView(), 
    const TempoDriverDashboardView(), // 🚚 अपडेटेड टेम्पो ड्राइवर डैशबोर्ड (क्लाउड जीपीएस सिंक के साथ)
    const UserLoginAndAddressView(),
    const CartAndWhatsAppCheckoutView(), 
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.storefront, size: 12),
                label: const Text('Market', style: TextStyle(fontSize: 9)),
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
              const SizedBox(width: 3),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 2),
                icon: const Icon(Icons.local_shipping, size: 12),
                label: const Text('Tempo GPS', style: TextStyle(fontSize: 9)),
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
                    onTap: () => setState(() => _selectedTabIndex = 3),
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
                    onTap: () => setState(() => _selectedTabIndex = 3),
                    child: const Text('(Edit Profile & Address)', style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _tabScreens[_selectedTabIndex > 4 ? 4 : _selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 3) {
            setState(() => _selectedTabIndex = 4); 
          } else if (index == 2) {
            setState(() => _selectedTabIndex = 3); 
          } else {
            setState(() => _selectedTabIndex = index);
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Market'),
          const BottomNavigationBarItem(icon: Icon(Icons.lock_person_outlined), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Tempo GPS'),
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
// STEP 1: MULTI-MANDI & SHOP DIRECTORY VIEW
// ==========================================
class MandiDirectoryView extends StatelessWidget {
  const MandiDirectoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('🌾 चुनी हुई मंडी चुनें (Select Mandi)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ViziagDatabase.mandisList.length,
          itemBuilder: (context, index) {
            var mandi = ViziagDatabase.mandisList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFF5722),
                  child: Icon(Icons.storefront, color: Colors.white),
                ),
                title: Text(mandi['mandiName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('स्थान: ${mandi['location']} • ${mandi['shops'].length} दुकानें उपलब्ध', style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFF5722)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MandiShopsScreen(mandiData: mandi)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class MandiShopsScreen extends StatelessWidget {
  final Map<String, dynamic> mandiData;
  const MandiShopsScreen({super.key, required this.mandiData});

  @override
  Widget build(BuildContext context) {
    List shops = mandiData['shops'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(mandiData['mandiName'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: shops.isEmpty
          ? const Center(child: Text('इस मंडी में अभी कोई दुकान रजिस्टर्ड नहीं है।'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                var shop = shops[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: buildShopOrProdImage(shop['ownerPhotoPath'], 50, 50, Icons.person),
                    ),
                    title: Text(shop['shopName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${shop['shopNumber']} • ${shop['address']}', style: const TextStyle(fontSize: 10)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white, minimumSize: const Size(60, 30)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MarketplaceBuyerView(selectedShop: shop)),
                        );
                      },
                      child: const Text('माल देखें', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// MARKETPLACE BUYER VIEW (IN-APP LIVE GPS TRACKING)
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  final Map<String, dynamic>? selectedShop;
  const MarketplaceBuyerView({super.key, this.selectedShop});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  bool isFruitTab = true; 
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

  // 🛰️ फायरबेस से टेम्पो की लाइव लोकेशन फेच करके इन-ऐप दिखाना
  Future<void> _fetchAndShowLiveTempoTracking() async {
    try {
      final response = await http.get(Uri.parse('${ViziagDatabase.firebaseRestUrl}/tempo_location.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        var cloudData = json.decode(response.body);
        setState(() {
          ViziagDatabase.tempoDriverProfile['latitude'] = cloudData['latitude'] ?? ViziagDatabase.tempoDriverProfile['latitude'];
          ViziagDatabase.tempoDriverProfile['longitude'] = cloudData['longitude'] ?? ViziagDatabase.tempoDriverProfile['longitude'];
          ViziagDatabase.tempoDriverProfile['currentLocationName'] = cloudData['locationName'] ?? 'Live GPS Updated';
        });
      }
    } catch (e) {
      debugPrint("Error fetching tempo location: $e");
    }

    var tempo = ViziagDatabase.tempoDriverProfile;
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚚 Live Tempo GPS Tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${tempo['driverName']}'),
            Text('Phone: ${tempo['driverPhone']}'),
            Text('Vehicle: ${tempo['vehicleModel']} [${tempo['vehicleNumber']}]'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 Current Coordinates:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  Text('Latitude: ${tempo['latitude']}'),
                  Text('Longitude: ${tempo['longitude']}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('📍 गाड़ी आपके ऑर्डर के लिए क्लाउड लाइव जीपीएस से ट्रैक हो रही है।', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: tempo['driverPhone'])),
            child: const Text('Call Driver 📞'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> prod, double qty) {
    var shop = widget.selectedShop ?? ViziagDatabase.mandisList[0]['shops'][0];
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

  Future<void> _callSupplier(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कॉल करने में असमर्थ!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var shop = widget.selectedShop ?? ViziagDatabase.mandisList[0]['shops'][0];
    var filteredProducts = ViziagDatabase.productInventory.where((p) {
      bool matchesCategory = isFruitTab ? (p['category'] == 'Fruit' || p['category'] == null) : (p['category'] == 'Vegetable');
      return matchesCategory;
    }).toList();

    var tempo = ViziagDatabase.tempoDriverProfile;

    return Scaffold(
      appBar: widget.selectedShop != null
          ? AppBar(title: Text(shop['shopName'], style: const TextStyle(fontSize: 14)), backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white)
          : null,
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.white, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🚚 लाइव टेम्पो/जीपीएस स्टेटस', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('ड्राइवर: ${tempo['driverName']} (${tempo['vehicleNumber']})', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      Text('लोकेशन: ${tempo['currentLocationName']}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade900, minimumSize: const Size(60, 30)),
                  onPressed: _fetchAndShowLiveTempoTracking, // 📍 खरीदार यहीं क्लिक करके इन-ऐप जीपीएस लाइव देखेगा
                  child: const Text('Track GPS', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                ToggleButtons(
                  isSelected: [isFruitTab, !isFruitTab],
                  onPressed: (index) => setState(() => isFruitTab = index == 0),
                  borderRadius: BorderRadius.circular(6),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFFFF5722),
                  color: Colors.black,
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 90),
                  children: const [
                    Text('🍎 Fruit (फल)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('🥦 Vegetable (सब्जी)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
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

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, spreadRadius: 1)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
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
                            Text('📞 ${shop['phone']}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _callSupplier(shop['phone'] ?? '9971968060'),
                        icon: const Icon(Icons.phone, size: 14),
                        label: const Text('Call', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('✨ मंडी के थोक भाव & आइटम्स (Wholesale Catalog)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),

          filteredProducts.isEmpty
              ? const Padding(padding: EdgeInsets.all(30.0), child: Center(child: Text('इस श्रेणी में अभी कोई आइटम उपलब्ध नहीं है!')))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                child: buildShopOrProdImage(prod['imagePath'], 120, double.infinity, Icons.fastfood),
                              ),
                              if (!inStock)
                                Container(
                                  height: 120,
                                  color: Colors.black.withOpacity(0.6),
                                  child: const Center(
                                    child: Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('₹${unitPrice.toInt()}/${prod['unit'] ?? 'kg'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Qty:', style: TextStyle(fontSize: 10)),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 35,
                                            height: 22,
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
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
                                      Text('Total: ₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 26,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: inStock ? const Color(0xFFFF5722) : Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: inStock ? () => _addToCart(prod, selectedQty) : null,
                                          child: Text(inStock ? 'Add to Cart' : 'Out of Stock', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}

// ==========================================
// 🚚 TEMPO DRIVER DASHBOARD (CLOUD GPS LIVE SYNC)
// ==========================================
class TempoDriverDashboardView extends StatefulWidget {
  const TempoDriverDashboardView({super.key});

  @override
  State<TempoDriverDashboardView> createState() => _TempoDriverDashboardViewState();
}

class _TempoDriverDashboardViewState extends State<TempoDriverDashboardView> {
  bool _isFetchingOrders = false;
  bool _isUpdatingGps = false;

  // 📥 फायरबेस से ग्राहकों के सारे ऑर्डर फेच करना
  Future<void> _fetchCustomerOrdersFromFirebase() async {
    setState(() => _isFetchingOrders = true);
    try {
      final response = await http.get(Uri.parse('${ViziagDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> ordersList = [];
        data.forEach((key, value) {
          var order = Map<String, dynamic>.from(value);
          order['orderKey'] = key;
          ordersList.add(order);
        });
        setState(() {
          ViziagDatabase.fetchedCustomerOrders = ordersList.reversed.toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${ordersList.length} ऑर्डर सफलतापूर्व फेच हो गए!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ अभी कोई नया ऑर्डर नहीं मिला है।'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isFetchingOrders = false);
    }
  }

  // 🛰️ ड्राइवर फोन के GPS से रियल लोकेशन निकालकर सीधे Firebase पर सिंक करेगा (नो व्हाट्सएप)
  Future<void> _updateLiveGpsToCloud() async {
    setState(() => _isUpdatingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया फोन का जीपीएस (Location) चालू करें!')));
        setState(() => _isUpdatingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ जीपीएस की अनुमति (Permission) आवश्यक है!')));
          setState(() => _isUpdatingGps = false);
          return;
        }
      }

      // करंट कोऑर्डिनेट्स फेच करना
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      var gpsPayload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': 'Faridabad Live Transit',
        'updatedAt': DateTime.now().toIso8601String(),
        'driverName': ViziagDatabase.tempoDriverProfile['driverName'],
        'vehicleNumber': ViziagDatabase.tempoDriverProfile['vehicleNumber'],
      };

      // फायरबेस पर डायरेक्ट लाइव लोकेशन सिंक (Put/Patch)
      final response = await http.put(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/tempo_location.json'),
        body: json.encode(gpsPayload),
      );

      if (response.statusCode == 200) {
        setState(() {
          ViziagDatabase.tempoDriverProfile['latitude'] = position.latitude;
          ViziagDatabase.tempoDriverProfile['longitude'] = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚀 Live GPS Location Cloud पर सिंक हो गई! ग्राहक अब ऐप में देख सकते हैं।'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS Sync Error: $e')));
    } finally {
      setState(() => _isUpdatingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var orders = ViziagDatabase.fetchedCustomerOrders;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          const Text('🚚 टेम्पो ड्राइवर डैशबोर्ड & लाइव जीपीएस', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('ड्राइवर यहाँ से आर्डर फेच करेगा और अपनी लाइव जीपीएस लोकेशन सीधे क्लाउड पर अपडेट करेगा।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),

          // 🛰️ Live GPS Update Button (replaces WhatsApp location)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: _isUpdatingGps ? null : _updateLiveGpsToCloud,
              icon: const Icon(Icons.gps_fixed),
              label: Text(_isUpdatingGps ? 'Syncing GPS...' : '🛰️ Update & Sync Live GPS to Cloud 📍', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),

          // 📥 Fetch Orders Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
              onPressed: _isFetchingOrders ? null : _fetchCustomerOrdersFromFirebase,
              icon: const Icon(Icons.download_done),
              label: Text(_isFetchingOrders ? 'Fetching Orders...' : '📥 Fetch All Customer Orders from Firebase 🚀', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 15),

          const Text('📦 फेच किए गए ग्राहकों के ऑर्डर्स (Active Orders List):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          orders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('कोई आर्डर फेच नहीं हुआ है। ऊपर दिए गए बटन पर क्लिक करें।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('👤 ${order['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('📞 ${order['customerPhone']}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('📍 पता: ${order['customerAddress']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 6),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Text('🛒 कुल राशि: ₹${order['grandTotal'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ दोनों पिन मेल नहीं खा रहे हैं!'), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 पिन सफलतापूर्व सेव हो गया!'), backgroundColor: Colors.green));
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
                    _isRegisteringNew ? '🛠️ नया पिन बनाएं (Create PIN)' : '🔐 दुकानदार लॉगिन (Vendor Login)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  if (!_isRegisteringNew) ...[
                    TextField(controller: _loginPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _loginPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-अंक का पिन', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white), onPressed: _verifyOrLoginVendor, child: const Text('लॉगिन करें')),
                    const SizedBox(height: 10),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = true), child: const Text('नया अकाउंट है? पिन सेट करें')),
                  ] else ...[
                    TextField(controller: _regPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _createPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'पिन दर्ज करें', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 10),
                    TextField(controller: _reEnterPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'दोबारा पिन डालें', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _saveNewVendorPin, child: const Text('पिन सेव करें और लॉगिन करें')),
                    const SizedBox(height: 10),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = false), child: const Text('पहले से पिन है? लॉगिन करें')),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const ShopRegisterAndUpdateView();
  }
}

// ==========================================
// VENDOR PORTAL VIEW
// ==========================================
class ShopRegisterAndUpdateView extends StatefulWidget {
  const ShopRegisterAndUpdateView({super.key});

  @override
  State<ShopRegisterAndUpdateView> createState() => _ShopRegisterAndUpdateViewState();
}

class _ShopRegisterAndUpdateViewState extends State<ShopRegisterAndUpdateView> {
  Map<String, dynamic> get activeShop => ViziagDatabase.mandisList[0]['shops'][0];

  late final TextEditingController _shopNameCtrl = TextEditingController(text: activeShop['shopName']);
  late final TextEditingController _ownerNameCtrl = TextEditingController(text: activeShop['ownerName']);
  late final TextEditingController _shopWhatsappCtrl = TextEditingController(text: activeShop['whatsappNumber']);
  late final TextEditingController _shopAddressCtrl = TextEditingController(text: activeShop['address']);
  late final TextEditingController _shopBioCtrl = TextEditingController(text: activeShop['bio']);

  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();

  String _selectedUnit = 'KG';
  String _selectedCategory = 'Fruit';
  bool _isUploadingToCloud = false;
  String? _pickedProdImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _saveShopDetailsToCloud() async {
    setState(() {
      activeShop['shopName'] = _shopNameCtrl.text.trim();
      activeShop['ownerName'] = _ownerNameCtrl.text.trim();
      activeShop['whatsappNumber'] = _shopWhatsappCtrl.text.trim();
      activeShop['address'] = _shopAddressCtrl.text.trim();
      activeShop['bio'] = _shopBioCtrl.text.trim();
    });

    try {
      await http.put(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/shop_profile.json'),
        body: json.encode(activeShop),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shop details synced with Cloud!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud sync error: $e')));
    }
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
        activeShop['ownerPhotoPath'] = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
      _saveShopDetailsToCloud();
    }
  }

  Future<void> _pickShopBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        activeShop['shopBannerPath'] = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
      _saveShopDetailsToCloud();
    }
  }

  Future<void> _publishProductToCloud() async {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item name and price!')));
      return;
    }

    setState(() => _isUploadingToCloud = true);

    var newProduct = {
      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
      'shopName': activeShop['shopName'],
      'owner': activeShop['ownerName'],
      'name': _prodNameCtrl.text,
      'price': double.tryParse(_priceCtrl.text) ?? 100.0,
      'unit': _selectedUnit,
      'stock': int.tryParse(_stockCtrl.text) ?? 20,
      'imagePath': _pickedProdImagePath ?? '',
      'category': _selectedCategory,
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

  @override
  Widget build(BuildContext context) {
    bool isShopOpen = activeShop['isOpen'] ?? true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🛠️ Vendor Control Panel & Shop Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

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
                  setState(() => activeShop['isOpen'] = val);
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
        TextField(controller: _shopWhatsappCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp Number (e.g. 919971968060)', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _shopAddressCtrl, decoration: const InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _shopBioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Shop Bio / Description', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: _saveShopDetailsToCloud,
          child: const Text('Save Shop & Permanent Sync'),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: ElevatedButton.icon(onPressed: _pickOwnerPhoto, icon: const Icon(Icons.person, size: 14), label: const Text('Owner Photo', style: TextStyle(fontSize: 11)))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(onPressed: _pickShopBanner, icon: const Icon(Icons.store, size: 14), label: const Text('Banner Photo', style: TextStyle(fontSize: 11)))),
          ],
        ),
        const Divider(height: 25),

        const Text('📦 Add New Item (Fruit / Vegetable)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
            const Text('Category: '),
            ChoiceChip(label: const Text('Fruit (फल)'), selected: _selectedCategory == 'Fruit', onSelected: (val) => setState(() => _selectedCategory = 'Fruit')),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Vegetable (सब्जी)'), selected: _selectedCategory == 'Vegetable', onSelected: (val) => setState(() => _selectedCategory = 'Vegetable')),
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
      ],
    );
  }
}

// ==========================================
// USER PROFILE VIEW
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
// WHATSAPP CHECKOUT CART (FIREBASE ORDER PUSH)
// ==========================================
class CartAndWhatsAppCheckoutView extends StatefulWidget {
  const CartAndWhatsAppCheckoutView({super.key});

  @override
  State<CartAndWhatsAppCheckoutView> createState() => _CartAndWhatsAppCheckoutViewState();
}

class _CartAndWhatsAppCheckoutViewState extends State<CartAndWhatsAppCheckoutView> {
  bool _isPlacingOrder = false;

  Future<void> _sendOrderToWhatsApp() async {
    if (ViziagDatabase.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }

    setState(() => _isPlacingOrder = true);

    double grandTotal = ViziagDatabase.cartItems.fold(0, (sum, item) => sum + ((item['price'] as double) * (item['qty'] as double)));

    var orderData = {
      'orderId': 'ord_${DateTime.now().millisecondsSinceEpoch}',
      'customerName': ViziagDatabase.currentCustomerName,
      'customerPhone': ViziagDatabase.currentUserPhone,
      'customerAddress': ViziagDatabase.currentDeliveryAddress,
      'items': ViziagDatabase.cartItems,
      'grandTotal': grandTotal,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await http.post(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/orders.json'),
        body: json.encode(orderData),
      );
    } catch (e) {
      debugPrint("Order sync error: $e");
    }

    setState(() => _isPlacingOrder = false);

    String vendorPhone = ViziagDatabase.mandisList[0]['shops'][0]['whatsappNumber'] ?? '919971968060';
    String message = "🛍️ *New Order from Viziag Mart*\n\n👤 *Customer:* ${ViziagDatabase.currentCustomerName}\n📞 *Phone:* ${ViziagDatabase.currentUserPhone}\n📍 *Address:* ${ViziagDatabase.currentDeliveryAddress}\n\n";

    for (int i = 0; i < ViziagDatabase.cartItems.length; i++) {
      var item = ViziagDatabase.cartItems[i];
      double itemTotal = (item['price'] as double) * (item['qty'] as double);
      message += "${i + 1}. ${item['name']} - ${item['qty']} ${item['unit']} = *₹${itemTotal.toStringAsFixed(0)}*\n";
    }
    message += "\n💰 *Grand Total: ₹${grandTotal.toStringAsFixed(0)}*\n\nभाई, ऑर्डर पैक कर देना। ड्राइवर ने जीपीएस लोकेशन ऐप पर लाइव कर दी है!";

    String whatsappUrl = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ WhatsApp is not installed!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
                    child: _isPlacingOrder
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
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
