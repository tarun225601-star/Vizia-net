                import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
// CENTRAL DATABASE & CLOUD SYNC MODEL
// ==========================================
class ViziagDatabase {
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/"; 

  static String currentUserPhone = "9971968060";
  static String currentCustomerName = "Tarun Kumar";
  static String currentDeliveryAddress = "Sector 15A Ajronda Sabji Mandi, Faridabad";
  
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
    }
  ];

  static List<Map<String, dynamic>> productInventory = [];
  static List<Map<String, dynamic>> cartItems = [];
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
    const CartAndWhatsAppCheckoutView(), 
    const SettingsConfigView(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.storefront, size: 12),
                label: const Text('Marketplace', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _selectedTabIndex = 1),
                icon: const Icon(Icons.store, size: 12),
                label: const Text('Vendor Portal', style: TextStyle(fontSize: 10)),
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
                    onTap: () => setState(() => _selectedTabIndex = 2),
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
                    onTap: () => setState(() => _selectedTabIndex = 2),
                    child: const Text('(Edit Profile)', style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _tabScreens[_selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex > 3 ? 3 : _selectedTabIndex,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 3) {
            setState(() => _selectedTabIndex = 3); // Cart Tab index
          } else {
            setState(() => _selectedTabIndex = index);
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Market'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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
// TAB 1: 3-GRID MARKETPLACE (CLOUD SYNCED)
// ==========================================
class MarketplaceBuyerView extends StatefulWidget {
  const MarketplaceBuyerView({super.key});

  @override
  State<MarketplaceBuyerView> createState() => _MarketplaceBuyerViewState();
}

class _MarketplaceBuyerViewState extends State<MarketplaceBuyerView> {
  bool isWholesaleMarket = false;
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
      final response = await http.get(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/products.json'),
      );

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

  void _addToCart(Map<String, dynamic> prod, double qty) {
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
          'shopName': prod['shopName'] ?? 'Tarun Fruit & Vegetable Shop',
        });
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🛒 Added $qty ${prod['unit'] ?? 'KG'} $prodName to Cart!'), duration: const Duration(milliseconds: 800)),
    );
  }

  Widget _buildCloudImageView(String? path, double height, double width, IconData fallbackIcon) {
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

  @override
  Widget build(BuildContext context) {
    var filteredProducts = ViziagDatabase.productInventory.where((p) => p['isWholesale'] == isWholesaleMarket).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              const Text('Cloud Synchronized Hyper-Local Market', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: _fetchProductsFromCloud,
                child: const Text('Sync Cloud', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        if (_isLoadingCloud)
          const LinearProgressIndicator(color: Color(0xFFFF5722)),

        // 3-Grid View Layout (3 Columns) with ONLY Add to Cart button (No direct WhatsApp button here)
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(child: Text('No products on cloud yet. Add items from Vendor Portal!'))
              : GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    var prod = filteredProducts[index];
                    String prodKey = prod['id'] ?? prod['name'];
                    double unitPrice = (prod['price'] ?? 100.0).toDouble();
                    double selectedQty = _itemQuantities[prodKey] ?? 1.0;
                    double totalPrice = unitPrice * selectedQty;

                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            child: _buildCloudImageView(prod['imagePath'], 75, double.infinity, Icons.fastfood),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(2)),
                                        child: Text(
                                          prod['shopName'] ?? 'Tarun shop',
                                          style: const TextStyle(fontSize: 7, color: Colors.blue, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        prod['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '₹${unitPrice.toInt()}/${prod['unit'] ?? 'kg'}',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Qty:', style: TextStyle(fontSize: 7)),
                                          const SizedBox(width: 2),
                                          SizedBox(
                                            width: 26,
                                            height: 16,
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 0)),
                                              controller: TextEditingController(text: selectedQty.toInt().toString())
                                                ..selection = TextSelection.fromPosition(TextPosition(offset: selectedQty.toInt().toString().length)),
                                              onChanged: (val) {
                                                double? q = double.tryParse(val);
                                                if (q != null && q > 0) {
                                                  setState(() => _itemQuantities[prodKey] = q);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Total: ₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      const SizedBox(height: 2),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 20,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE91E63),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () => _addToCard(prod, selectedQty),
                                          child: const Text('Add to Cart', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
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
        ),
      ],
    );
  }
}

// ==========================================
// TAB 2: VENDOR DASHBOARD & PERMANENT CLOUD UPLOAD
// ==========================================
class ShopRegisterAndUpdateView extends StatefulWidget {
  const ShopRegisterAndUpdateView({super.key});

  @override
  State<ShopRegisterAndUpdateView> createState() => _ShopRegisterAndUpdateViewState();
}

class _ShopRegisterAndUpdateViewState extends State<ShopRegisterAndUpdateView> {
  final TextEditingController _prodNameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();

  String _selectedUnit = 'KG';
  bool _isWholesaleItem = false;
  bool _isUploadingToCloud = false;
  String? _pickedProdImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      setState(() => _pickedProdImagePath = base64Image);
    }
  }

  Future<void> _publishProductToCloud() async {
    if (_prodNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item name and price!')));
      return;
    }

    setState(() => _isUploadingToCloud = true);
    var activeShop = ViziagDatabase.registeredShops[0];

    var newProduct = {
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚀 Saved on Firebase Cloud permanently! App uninstall safe.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
    } finally {
      setState(() => _isUploadingToCloud = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('📦 Add Item to Permanent Firebase Cloud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('Note: Photos and data saved here remain stored even if the app is uninstalled and reinstalled.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
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
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_a_photo, size: 14),
          label: Text(_pickedProdImagePath == null ? 'Select Image (Cloud Safe)' : 'Image Selected ✅'),
        ),
        const SizedBox(height: 15),
        _isUploadingToCloud
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
                onPressed: _publishProductToCloud,
                child: const Text('Publish & Save Permanently to Cloud 🚀'),
              ),
      ],
    );
  }
}

// ==========================================
// TAB 3: CUSTOMER PROFILE CONFIG
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
// TAB 4: WHATSAPP CHECKOUT & BILLING CART VIEW
// ==========================================
class CartAndWhatsAppCheckoutView extends StatefulWidget {
  const CartAndWhatsAppCheckoutView({super.key});

  @override
  State<CartAndWhatsAppCheckoutView> createState() => _CartAndWhatsAppCheckoutViewState();
}

class _CartAndWhatsAppCheckoutViewState extends State<CartAndWhatsAppCheckoutView> {
  Future<void> _sendOrderToWhatsApp() async {
    if (ViziagDatabase.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }

    String vendorPhone = ViziagDatabase.registeredShops[0]['whatsappNumber'] ?? '919971968060';
    String message = "🛍️ *New Order from Viziag Mart*\n\n👤 *Customer:* ${ViziagDatabase.currentCustomerName}\n📞 *Phone:* ${ViziagDatabase.currentUserPhone}\n📍 *Address:* ${ViziagDatabase.currentDeliveryAddress}\n\n";

    double grandTotal = 0;
    for (int i = 0; i < ViziagDatabase.cartItems.length; i++) {
      var item = ViziagDatabase.cartItems[i];
      double itemTotal = (item['price'] as double) * (item['qty'] as double);
      grandTotal += itemTotal;
      message += "${i + 1}. ${item['name']} - ${item['qty']} ${item['unit']} = *₹${itemTotal.toStringAsFixed(0)}*\n";
    }
    message += "\n💰 *Grand Total: ₹${grandTotal.toStringAsFixed(0)}*";

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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)]),
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
                    child: ElevatedButton.icon(
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

// ==========================================
// TAB 5: SETTINGS & CONFIG
// ==========================================
class SettingsConfigView extends StatelessWidget {
  const SettingsConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('⚙️ Settings & Vendor Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Divider(),
        Text('All product images and details are safely synced with Firebase Cloud Realtime Database and remain persistent even after app reinstallation.'),
      ],
    );
  }
}
