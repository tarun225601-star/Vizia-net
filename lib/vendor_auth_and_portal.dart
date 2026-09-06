// ================= FILE: vendor_auth_and_portal.dart =================
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  bool _isLoggedIn = false;
  int _portalTab = 0; // 0: Products, 1: Shop Profile, 2: Incoming Orders

  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController(text: 'Kg');

  // Shop Profile Controllers
  late TextEditingController _shopNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;

  String? _productImageBase64;
  String? _ownerPhotoBase64;
  String? _shopPhotoBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['shopName']);
    _ownerNameCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['ownerName']);
    _addressCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['address']);
    _phoneCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['phone']);
    _ownerPhotoBase64 = EnterpriseDatabase.activeShopProfile['ownerPhoto'];
    _shopPhotoBase64 = EnterpriseDatabase.activeShopProfile['shopPhoto'];
    _fetchVendorOrders();
  }

  // Pick Image and Convert to Base64
  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      Uint8List bytes = await image.readAsBytes();
      String base64String = base64Encode(bytes);
      setState(() {
        if (type == 'product') _productImageBase64 = base64String;
        if (type == 'owner') _ownerPhotoBase64 = base64String;
        if (type == 'shop') _shopPhotoBase64 = base64String;
      });
    }
  }

  Future<void> _fetchVendorOrders() async {
    try {
      final response = await http.get(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> loadedOrders = [];
        data.forEach((key, value) {
          var order = Map<String, dynamic>.from(value);
          order['orderKey'] = key;
          loadedOrders.add(order);
        });
        setState(() {
          EnterpriseDatabase.allOrders = loadedOrders.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<void> _addProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    var newProduct = {
      'name': _nameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'unit': _unitCtrl.text.trim(),
      'inStock': true,
      'image': _productImageBase64 ?? '',
    };

    try {
      final response = await http.post(
        Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products.json'),
        body: json.encode(newProduct),
      );
      if (response.statusCode == 200) {
        _nameCtrl.clear();
        _priceCtrl.clear();
        setState(() => _productImageBase64 = null);
        _fetchCloudProducts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ उत्पाद सफलतापर्वक जुड़ गया!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ एरर: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCloudProducts() async {
    final response = await http.get(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products.json'));
    if (response.statusCode == 200 && response.body != 'null') {
      Map<String, dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> fetchedList = [];
      data.forEach((key, value) {
        var item = Map<String, dynamic>.from(value);
        item['firebaseKey'] = key;
        fetchedList.add(item);
      });
      setState(() {
        EnterpriseDatabase.globalInventory = fetchedList;
      });
    }
  }

  Future<void> _deleteProduct(String key) async {
    await http.delete(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products/$key.json'));
    _fetchCloudProducts();
  }

  Future<void> _toggleStock(String key, bool currentStatus, Map<String, dynamic> item) async {
    item['inStock'] = !currentStatus;
    await http.put(
      Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products/$key.json'),
      body: json.encode(item),
    );
    _fetchCloudProducts();
  }

  Future<void> _saveShopProfile() async {
    setState(() => _isLoading = true);
    EnterpriseDatabase.activeShopProfile = {
      'shopName': _shopNameCtrl.text.trim(),
      'ownerName': _ownerNameCtrl.text.trim(),
      'ownerPhoto': _ownerPhotoBase64 ?? '',
      'shopPhoto': _shopPhotoBase64 ?? '',
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };

    try {
      await http.put(
        Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/shop_profile.json'),
        body: json.encode(EnterpriseDatabase.activeShopProfile),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ दुकान की प्रोफाइल सेव हो गई!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ एरर: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFFF59E0B)),
              const SizedBox(height: 16),
              const Text('वेंडर पोर्टल लॉगिन', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'पासवर्ड डालें...', hintStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                onPressed: () {
                  if (_passCtrl.text.trim() == 'tarun#1' || _passCtrl.text.trim() == '1234') {
                    setState(() => _isLoggedIn = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ गलत पासवर्ड!'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('लॉगिन करें'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Portal Sub-Navigation Tabs
        Container(
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _portalTab = 0),
                icon: Icon(Icons.inventory, color: _portalTab == 0 ? const Color(0xFFF59E0B) : Colors.grey, size: 16),
                label: Text('उत्पाद जोड़ें', style: TextStyle(color: _portalTab == 0 ? const Color(0xFFF59E0B) : Colors.grey, fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _portalTab = 1),
                icon: Icon(Icons.store, color: _portalTab == 1 ? const Color(0xFFF59E0B) : Colors.grey, size: 16),
                label: Text('शॉप प्रोफाइल', style: TextStyle(color: _portalTab == 1 ? const Color(0xFFF59E0B) : Colors.grey, fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _portalTab = 2);
                  _fetchVendorOrders();
                },
                icon: Icon(Icons.receipt_long, color: _portalTab == 2 ? const Color(0xFFF59E0B) : Colors.grey, size: 16),
                label: Text('ऑर्डर्स डैशबोर्ड', style: TextStyle(color: _portalTab == 2 ? const Color(0xFFF59E0B) : Colors.grey, fontSize: 11)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _portalTab == 0
              ? _buildProductManagementView()
              : _portalTab == 1
                  ? _buildShopProfileView()
                  : _buildOrdersDashboardView(),
        ),
      ],
    );
  }

  // 1. Product Management & Image Base64 Upload
  Widget _buildProductManagementView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('नया सामान जोड़ें (Base64 Image Supported)', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'सामान का नाम (Name)', labelStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'कीमत (₹)', labelStyle: TextStyle(color: Colors.grey)))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _unitCtrl, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'यूनिट (Kg/Pcs)', labelStyle: TextStyle(color: Colors.grey)))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
              onPressed: () => _pickImage('product'),
              icon: const Icon(Icons.image, size: 16),
              label: const Text('फोटो चुनें', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 10),
            if (_productImageBase64 != null)
              const Text('✅ फोटो चुनी गई', style: TextStyle(color: Colors.green, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
          onPressed: _isLoading ? null : _addProduct,
          child: const Text('डेटाबेस में जोड़ें', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Divider(color: Colors.grey, height: 30),
        const Text('मौजूदा प्रोडक्ट्स सूची:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: EnterpriseDatabase.globalInventory.length,
          itemBuilder: (context, index) {
            var item = EnterpriseDatabase.globalInventory[index];
            bool inStock = item['inStock'] ?? true;
            return Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                leading: item['image'] != null && item['image'].isNotEmpty
                    ? Image.memory(base64Decode(item['image']), width: 40, height: 40, fit: BoxFit.cover)
                    : const Icon(Icons.eco, color: Color(0xFFF59E0B)),
                title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('₹${item['price']} / ${item['unit']} | ${inStock ? "In Stock" : "Out of Stock"}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: inStock,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (val) => _toggleStock(item['firebaseKey'], inStock, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () => _deleteProduct(item['firebaseKey']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. Shop Profile View (Owner Photo, Shop Photo, Full Address Base64)
  Widget _buildShopProfileView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('दुकान और ओनर की जानकारी (Base64 Setup)', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        TextField(controller: _shopNameCtrl, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'शॉप का नाम (Shop Name)', labelStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 8),
        TextField(controller: _ownerNameCtrl, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'ओनर का नाम (Owner Name)', labelStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 8),
        TextField(controller: _addressCtrl, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'पूरा एड्रेस (Full Address)', labelStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 8),
        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'मोबाइल नंबर (Phone)', labelStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text('ओनर की फोटो', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  _ownerPhotoBase64 != null && _ownerPhotoBase64!.isNotEmpty
                      ? Image.memory(base64Decode(_ownerPhotoBase64!), height: 60, width: 60, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 40, color: Colors.grey),
                  TextButton(onPressed: () => _pickImage('owner'), child: const Text('फोटो बदलें', style: TextStyle(fontSize: 10))),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text('शॉप की फोटो', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  _shopPhotoBase64 != null && _shopPhotoBase64!.isNotEmpty
                      ? Image.memory(base64Decode(_shopPhotoBase64!), height: 60, width: 60, fit: BoxFit.cover)
                      : const Icon(Icons.store, size: 40, color: Colors.grey),
                  TextButton(onPressed: () => _pickImage('shop'), child: const Text('फोटो बदलें', style: TextStyle(fontSize: 10))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
          onPressed: _isLoading ? null : _saveShopProfile,
          child: const Text('शॉप प्रोफाइल सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // 3. Vendor Orders Dashboard View
  Widget _buildOrdersDashboardView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ग्राहकों के लाइव ऑर्डर्स', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFF59E0B), size: 18),
              onPressed: _fetchVendorOrders,
            ),
          ],
        ),
        const SizedBox(height: 8),
        EnterpriseDatabase.allOrders.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('कोई नया ऑर्डर प्राप्त नहीं हुआ है।', style: TextStyle(color: Colors.grey, fontSize: 11))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: EnterpriseDatabase.allOrders.length,
                itemBuilder: (context, index) {
                  var order = EnterpriseDatabase.allOrders[index];
                  List items = order['items'] ?? [];
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ऑर्डर आईडी: ${order['orderKey']?.substring(0, 8) ?? 'N/A'}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('ग्राहक: ${order['customerName'] ?? 'Unknown'} (${order['customerPhone'] ?? ''})', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          Text('पता: ${order['customerAddress'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          const Divider(color: Colors.grey),
                          ...items.map<Widget>((i) => Text('• ${i['name']} (${i['qty']} ${i['unit']}) - ₹${i['price']}', style: const TextStyle(color: Colors.white70, fontSize: 10))),
                          const Divider(color: Colors.grey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('कुल राशि: ₹${order['totalAmount'] ?? 0}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(order['timestamp'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
