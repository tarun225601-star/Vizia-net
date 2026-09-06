// ================= FILE 4 OF 10: vendor_auth_and_portal.dart =================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  bool _isLoggedIn = false;
  final TextEditingController _pinController = TextEditingController();
  final String _vendorSecretPin = "9971";

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person, size: 50, color: Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                const Text('वेंडर पोर्टल लॉगिन (Vendor Login)', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('सुरक्षित एक्सेस के लिए अपना 4-अंकों का पिन दर्ज करें', style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'PIN दर्ज करें',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 38),
                  ),
                  onPressed: () {
                    if (_pinController.text.trim() == _vendorSecretPin) {
                      setState(() => _isLoggedIn = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ गलत पिन! (डिफ़ॉल्ट पिन: 9971)'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('पोर्टल खोलें', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const VendorDashboardManagementScreen();
  }
}

class VendorDashboardManagementScreen extends StatefulWidget {
  const VendorDashboardManagementScreen({super.key});

  @override
  State<VendorDashboardManagementScreen> createState() => _VendorDashboardManagementScreenState();
}

class _VendorDashboardManagementScreenState extends State<VendorDashboardManagementScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController(text: 'Kg');
  final TextEditingController _imageCtrl = TextEditingController();
  String _selectedCategory = 'Fresh Fruits';
  bool _inStock = true;
  bool _isUploading = false;

  final List<String> _categories = ['Fresh Fruits', 'Vegetables', 'Organic Items', 'Daily Essentials'];

  Future<void> _uploadProductToCloud() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया नाम और कीमत भरें!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final newProduct = {
        'name': _nameCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'unit': _unitCtrl.text.trim(),
        'category': _selectedCategory,
        'imageUrl': _imageCtrl.text.trim().isEmpty ? 'https://images.unsplash.com/photo-1610832958506-aa56368176cf' : _imageCtrl.text.trim(),
        'inStock': _inStock,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await http.post(
        Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products.json'),
        body: json.encode(newProduct),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ उत्पाद सफलतापूर्वक जोड़ दिया गया!'), backgroundColor: Colors.green));
        _nameCtrl.clear();
        _priceCtrl.clear();
        _imageCtrl.clear();
        // रिफ्रेश के लिए तुरंत डेटा फेच करें
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ अपलोड त्रुटि: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProduct(String firebaseKey) async {
    try {
      await http.delete(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products/$firebaseKey.json'));
      setState(() {
        EnterpriseDatabase.globalInventory.removeWhere((p) => p['firebaseKey'] == firebaseKey);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ उत्पाद हटा दिया गया!'), backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ त्रुटि: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📦 नया उत्पाद जोड़ें (Add Inventory Item)', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'उत्पाद का नाम (Item Name)', labelStyle: TextStyle(color: Colors.grey), isDense: true)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'कीमत (Price ₹)', labelStyle: TextStyle(color: Colors.grey), isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _unitCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'यूनिट (Kg / Packet)', labelStyle: TextStyle(color: Colors.grey), isDense: true))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: _imageCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'इमेज URL (Image Link / Optional)', labelStyle: TextStyle(color: Colors.grey), isDense: true)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'कैटेगरी (Category)', labelStyle: TextStyle(color: Colors.grey), isDense: true),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12, color: Colors.white)))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? 'Fresh Fruits'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('स्टॉक में उपलब्ध है?', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  const Spacer(),
                  Switch(value: _inStock, activeColor: const Color(0xFFF59E0B), onChanged: (val) => setState(() => _inStock = val)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                  onPressed: _isUploading ? null : _uploadProductToCloud,
                  child: _isUploading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('क्लाउड पर सेव करें (Publish Product)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('📋 आपके मौजूदा उत्पाद (Manage Inventory):', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        EnterpriseDatabase.globalInventory.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('कोई उत्पाद नहीं मिला। ऊपर से नया जोड़ें।', style: TextStyle(color: Colors.grey, fontSize: 11))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: EnterpriseDatabase.globalInventory.length,
                itemBuilder: (context, index) {
                  var item = EnterpriseDatabase.globalInventory[index];
                  bool inStock = item['inStock'] ?? true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('₹${item['price']} / ${item['unit']} | ${inStock ? "🟢 In Stock" : "🔴 Out of Stock"}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteProduct(item['firebaseKey']),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
