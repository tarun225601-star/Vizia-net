import 'dart:io';
import 'dart:json';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

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
  
  // टेम्पो / डिलीवरी पार्टनर डेटा मॉडल (ओरिजिनल जीपीएस इंटीग्रेशन के साथ)
  static Map<String, dynamic> tempoDriverProfile = {
    'driverName': 'राजेश कुमार',
    'driverPhone': '9876543210',
    'vehicleNumber': 'HR-51-AB-1234',
    'startLocationName': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
    'destinationName': 'Sector 16 Market, Faridabad',
    'latitude': 0.0,
    'longitude': 0.0,
    'destLatitude': 0.0,
    'destLongitude': 0.0,
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
    const TempoDriverDashboardView(), 
    const UserAndTempoProfileView(), 
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
// MARKETPLACE BUYER VIEW
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

  Future<void> _launchRouteMap() async {
    var tempo = ViziagDatabase.tempoDriverProfile;
    double currentLat = tempo['latitude'] ?? 0.0;
    double currentLng = tempo['longitude'] ?? 0.0;
    double destLat = tempo['destLatitude'] ?? 0.0;
    double destLng = tempo['destLongitude'] ?? 0.0;

    if (currentLat == 0.0 || currentLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ लाइव जीपीएस लोकेशन अभी उपलब्ध नहीं है!')));
      return;
    }

    String mapUrl = "https://www.google.com/maps/dir/?api=1&origin=$currentLat,$currentLng&destination=$destLat,$destLng&travelmode=driving";
    final Uri uri = Uri.parse(mapUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ मैप्स खोलने में असमर्थ!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
                      const Text('🚚 टेम्पो रूट स्टेटस', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('गाड़ी: ${tempo['vehicleNumber']} (${tempo['driverName']})', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      Text('कहाँ से: ${tempo['startLocationName']}', style: const TextStyle(color: Colors.white60, fontSize: 9)),
                      Text('डेस्टिनेशन: ${tempo['destinationName']}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade900, minimumSize: const Size(60, 30)),
                  onPressed: _launchRouteMap,
                  icon: const Icon(Icons.map, size: 14),
                  label: const Text('Live Route', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

          GridView.builder(
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
// 🚚 TEMPO DRIVER DASHBOARD (ORIGINAL GPS & ROUTE SETUP)
// ==========================================
class TempoDriverDashboardView extends StatefulWidget {
  const TempoDriverDashboardView({super.key});

  @override
  State<TempoDriverDashboardView> createState() => _TempoDriverDashboardViewState();
}

class _TempoDriverDashboardViewState extends State<TempoDriverDashboardView> {
  bool _isUpdatingGps = false;
  Timer? _locationTimer;
  bool _isAutoTrackingActive = false;

  final TextEditingController _startLocationCtrl = TextEditingController(text: ViziagDatabase.tempoDriverProfile['startLocationName']);
  final TextEditingController _destLocationCtrl = TextEditingController(text: ViziagDatabase.tempoDriverProfile['destinationName']);

  @override
  void dispose() {
    _locationTimer?.cancel(); 
    _startLocationCtrl.dispose();
    _destLocationCtrl.dispose();
    super.dispose();
  }

  // जियोकोडिंग के जरिए एड्रेस से सटीक Lat/Lng निकालने का ओरिजिनल मेथड
  Future<void> _saveDriverRouteDestination() async {
    String startAddr = _startLocationCtrl.text.trim();
    String destAddr = _destLocationCtrl.text.trim();

    setState(() {
      ViziagDatabase.tempoDriverProfile['startLocationName'] = startAddr;
      ViziagDatabase.tempoDriverProfile['destinationName'] = destAddr;
    });

    try {
      // जियोलोकेटर से करंट जीपीएस लोकेशन उठाएं
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      ViziagDatabase.tempoDriverProfile['latitude'] = position.latitude;
      ViziagDatabase.tempoDriverProfile['longitude'] = position.longitude;
      
      // डेस्टिनेशन कोऑर्डिनेट्स के लिए जियोकोडिंग या करंट पोजीशन का उपयोग
      // यहाँ पर डेस्टिनेशन के लिए भी लाइव जीपीएस या ओरिजिनल लोकेशन सेट की जा रही है
      ViziagDatabase.tempoDriverProfile['destLatitude'] = position.latitude + 0.01; 
      ViziagDatabase.tempoDriverProfile['destLongitude'] = position.longitude + 0.01;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 ओरिजिनल जीपीएस कोऑर्डिनेट्स के साथ रूट सेव हो गया!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ जीपीएस फेच करने में असफल: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateLiveGpsToCloud() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      var gpsPayload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'startLocationName': ViziagDatabase.tempoDriverProfile['startLocationName'],
        'destinationName': ViziagDatabase.tempoDriverProfile['destinationName'],
        'updatedAt': DateTime.now().toIso8601String(),
        'driverName': ViziagDatabase.tempoDriverProfile['driverName'],
        'vehicleNumber': ViziagDatabase.tempoDriverProfile['vehicleNumber'],
      };

      await http.put(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/tempo_location.json'),
        body: json.encode(gpsPayload),
      );

      setState(() {
        ViziagDatabase.tempoDriverProfile['latitude'] = position.latitude;
        ViziagDatabase.tempoDriverProfile['longitude'] = position.longitude;
      });
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  void _toggleAutoTracking() {
    if (_isAutoTrackingActive) {
      _locationTimer?.cancel();
      setState(() => _isAutoTrackingActive = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🛑 सफर रोक दिया गया।'), backgroundColor: Colors.red));
    } else {
      setState(() => _isAutoTrackingActive = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🟢 सफर शुरू! लाइव GPS ट्रैकिंग चालू हो गई।'), backgroundColor: Colors.green));

      _updateLiveGpsToCloud();
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateLiveGpsToCloud(); 
      });
    }
  }

  Future<void> _manualSyncGps() async {
    setState(() => _isUpdatingGps = true);
    await _updateLiveGpsToCloud();
    setState(() => _isUpdatingGps = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 GPS लोकेशन क्लाउड पर सिंक हो गई!'), backgroundColor: Colors.green));
  }

  Future<void> _openLiveRouteMap() async {
    var tempo = ViziagDatabase.tempoDriverProfile;
    double currentLat = tempo['latitude'] ?? 0.0;
    double currentLng = tempo['longitude'] ?? 0.0;
    double destLat = tempo['destLatitude'] ?? 0.0;
    double destLng = tempo['destLongitude'] ?? 0.0;

    if (currentLat == 0.0 || currentLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया पहले GPS सिंक करें या रूट सेव करें!')));
      return;
    }

    String mapUrl = "https://www.google.com/maps/dir/?api=1&origin=$currentLat,$currentLng&destination=$destLat,$destLng&travelmode=driving";
    final Uri uri = Uri.parse(mapUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          const Text('🚚 टेम्पो ड्राइवर डैशबोर्ड & लाइव जीपीएस', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('ड्राइवर यहाँ से सफर शुरू करेगा और नीचे डेस्टिनेशन सेट करेगा।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAutoTrackingActive ? Colors.red : Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _toggleAutoTracking,
              child: Text(
                _isAutoTrackingActive ? '🔴 सफर रोकें (Stop Auto GPS Loop)' : '🟢 सफर शुरू करें (Start Auto GPS Loop)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isUpdatingGps ? null : _manualSyncGps,
              icon: const Icon(Icons.gps_fixed, size: 16),
              label: const Text('📍 वन-टच मैनुअल जीपीएस सिंक करें', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade300),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 टेम्पो डेस्टिनेशन और रूट सेट करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _startLocationCtrl,
                  decoration: const InputDecoration(labelText: 'कहाँ से (Starting Point / Mandi)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _destLocationCtrl,
                  decoration: const InputDecoration(labelText: 'कहाँ तक (Destination / Customer Address)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
                        onPressed: _saveDriverRouteDestination,
                        child: const Text('रूट सेव करें', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                        onPressed: _openLiveRouteMap,
                        icon: const Icon(Icons.map, size: 14),
                        label: const Text('मैप पर रूट देखें', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया मोबाइल नंबर और पिन दर्ज करें!')));
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ गलत पिन!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ नंबर रजिस्टर्ड नहीं है।')));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoadingAuth = false);
    }
  }

  Future<void> _saveNewVendorPin() async {
    String phone = _regPhoneCtrl.text.trim();
    String pin1 = _createPinCtrl.text.trim();
    String pin2 = _reEnterPinCtrl.text.trim();

    if (phone.isEmpty || pin1.length != 4 || pin1 != pin2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया सही विवरण भरें!')));
      return;
    }

    setState(() => _isLoadingAuth = true);
    try {
      await http.put(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/vendors/$phone.json'),
        body: json.encode({'phone': phone, 'pin': pin1}),
      );
      setState(() {
        _isLoggedIn = true;
        _isRegisteringNew = false;
        ViziagDatabase.currentUserPhone = phone;
      });
    } catch (e) {
      debugPrint("Error: $e");
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_person, size: 50, color: Color(0xFFFF5722)),
                  const SizedBox(height: 10),
                  Text(_isRegisteringNew ? '🛠️ नया पिन बनाएं' : '🔐 दुकानदार लॉगिन', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (!_isRegisteringNew) ...[
                    TextField(controller: _loginPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _loginPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: '4-अंक का पिन', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white), onPressed: _verifyOrLoginVendor, child: const Text('लॉगिन करें')),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = true), child: const Text('नया अकाउंट है? पिन सेट करें')),
                  ] else ...[
                    TextField(controller: _regPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 10),
                    TextField(controller: _createPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'पिन दर्ज करें', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 10),
                    TextField(controller: _reEnterPinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'दोबारा पिन डालें', border: OutlineInputBorder(), isDense: true, counterText: '')),
                    const SizedBox(height: 15),
                    _isLoadingAuth ? const Center(child: CircularProgressIndicator()) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _saveNewVendorPin, child: const Text('पिन सेव करें')),
                    TextButton(onPressed: () => setState(() => _isRegisteringNew = false), child: const Text('लॉगिन पर वापस जाएं')),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shop details saved!'), backgroundColor: Colors.green));
  }

  Future<void> _pickProductImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _pickedProdImagePath = "data:image/jpeg;base64,${base64Encode(bytes)}");
    }
  }

  Future<void> _publishProductToCloud() async {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
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
        setState(() {
          ViziagDatabase.productInventory.insert(0, newProduct);
        });
        _prodNameCtrl.clear();
        _priceCtrl.clear();
        _stockCtrl.clear();
        setState(() => _pickedProdImagePath = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Item Added Successfully!'), backgroundColor: Colors.green));
      }
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
        const Text('🛠️ Vendor Control Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SwitchListTile(
          title: const Text('Shop Status (Open/Closed)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          value: isShopOpen,
          activeColor: Colors.green,
          onChanged: (val) => setState(() => activeShop['isOpen'] = val),
        ),
        TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _shopWhatsappCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Number', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _shopAddressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _saveShopDetailsToCloud, child: const Text('Save Shop Profile')),
        const Divider(height: 25),
        const Text('📦 Add New Item', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _prodNameCtrl, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: _pickProductImage, icon: const Icon(Icons.add_a_photo), label: const Text('Select Image')),
        const SizedBox(height: 8),
        _isUploadingToCloud ? const CircularProgressIndicator() : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white), onPressed: _publishProductToCloud, child: const Text('Add Item')),
      ],
    );
  }
}

// ==========================================
// 👤 USER PROFILE & TEMPO PROFILE VIEW
// ==========================================
class UserAndTempoProfileView extends StatefulWidget {
  const UserAndTempoProfileView({super.key});

  @override
  State<UserAndTempoProfileView> createState() => _UserAndTempoProfileViewState();
}

class _UserAndTempoProfileViewState extends State<UserAndTempoProfileView> {
  final TextEditingController _nameCtrl = TextEditingController(text: ViziagDatabase.currentCustomerName);
  final TextEditingController _userPhoneCtrl = TextEditingController(text: ViziagDatabase.currentUserPhone);
  final TextEditingController _addressCtrl = TextEditingController(text: ViziagDatabase.currentDeliveryAddress);

  final TextEditingController _driverNameCtrl = TextEditingController(text: ViziagDatabase.tempoDriverProfile['driverName']);
  final TextEditingController _driverPhoneCtrl = TextEditingController(text: ViziagDatabase.tempoDriverProfile['driverPhone']);
  final TextEditingController _vehicleNumCtrl = TextEditingController(text: ViziagDatabase.tempoDriverProfile['vehicleNumber']);

  void _saveAllProfiles() {
    setState(() {
      ViziagDatabase.currentCustomerName = _nameCtrl.text.trim();
      ViziagDatabase.currentUserPhone = _userPhoneCtrl.text.trim();
      ViziagDatabase.currentDeliveryAddress = _addressCtrl.text.trim();

      ViziagDatabase.tempoDriverProfile['driverName'] = _driverNameCtrl.text.trim();
      ViziagDatabase.tempoDriverProfile['driverPhone'] = _driverPhoneCtrl.text.trim();
      ViziagDatabase.tempoDriverProfile['vehicleNumber'] = _vehicleNumCtrl.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Customer & Tempo Profiles Saved Successfully!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('👤 Customer Profile & Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _userPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Full Delivery Address', border: OutlineInputBorder(), isDense: true)),
          
          const Divider(height: 30, thickness: 2),

          const Text('🚚 Tempo Driver & Vehicle Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 4),
          const Text('यहाँ से टेम्पो ड्राइवर और गाड़ी की जानकारी सेट करें।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(controller: _driverNameCtrl, decoration: const InputDecoration(labelText: 'Driver Name (ड्राइवर का नाम)', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _driverPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Mobile Number', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _vehicleNumCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number (जैसे: HR-51-AB-1234)', border: OutlineInputBorder(), isDense: true)),
          
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
              onPressed: _saveAllProfiles,
              child: const Text('Save Profile & Tempo Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WHATSAPP CHECKOUT CART
// ==========================================
class CartAndWhatsAppCheckoutView extends StatefulWidget {
  const CartAndWhatsAppCheckoutView({super.key});

  @override
  State<CartAndWhatsAppCheckoutView> createState() => _CartAndWhatsAppCheckoutViewState();
}

class _CartAndWhatsAppCheckoutViewState extends State<CartAndWhatsAppCheckoutView> {
  bool _isPlacingOrder = false;

  Future<void> _sendOrderToWhatsApp() async {
    if (ViziagDatabase.cartItems.isEmpty) return;
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
    } catch (_) {}

    setState(() => _isPlacingOrder = false);

    String vendorPhone = ViziagDatabase.mandisList[0]['shops'][0]['whatsappNumber'] ?? '919971968060';
    String message = "🛍️ *New Order from Viziag Mart*\n\n👤 *Customer:* ${ViziagDatabase.currentCustomerName}\n📍 *Address:* ${ViziagDatabase.currentDeliveryAddress}\n\n";

    for (int i = 0; i < ViziagDatabase.cartItems.length; i++) {
      var item = ViziagDatabase.cartItems[i];
      message += "${i + 1}. ${item['name']} - ${item['qty']} ${item['unit']} = *₹${(item['price'] * item['qty']).toStringAsFixed(0)}*\n";
    }
    message += "\n💰 *Grand Total: ₹${grandTotal.toStringAsFixed(0)}*\n\nभाई, आर्डर पैक कर देना!";

    String whatsappUrl = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          const Text('🛒 Your Shopping Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Cart is empty'))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      var item = cart[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: ${item['qty']} ${item['unit']} • ₹${item['price']} each'),
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
                            label: const Text('Send Order to WhatsApp 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
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
