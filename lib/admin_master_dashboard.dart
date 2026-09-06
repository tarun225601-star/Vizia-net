// ================= FILE 10 OF 10: admin_master_dashboard.dart =================
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class AdminMasterDashboardScreen extends StatefulWidget {
  const AdminMasterDashboardScreen({super.key});

  @override
  State<AdminMasterDashboardScreen> createState() => _AdminMasterDashboardScreenState();
}

class _AdminMasterDashboardScreenState extends State<AdminMasterDashboardScreen> {
  final TextEditingController _shopNameCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['shopName']);
  final TextEditingController _phoneCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['phone']);
  final TextEditingController _addressCtrl = TextEditingController(text: EnterpriseDatabase.activeShopProfile['address']);
  final TextEditingController _urlCtrl = TextEditingController(text: EnterpriseDatabase.firebaseRestUrl);
  
  bool _isSaving = false;
  bool _isClearing = false;

  Future<void> _saveMasterSettings() async {
    setState(() => _isSaving = true);
    try {
      EnterpriseDatabase.activeShopProfile['shopName'] = _shopNameCtrl.text.trim();
      EnterpriseDatabase.activeShopProfile['phone'] = _phoneCtrl.text.trim();
      EnterpriseDatabase.activeShopProfile['address'] = _addressCtrl.text.trim();
      EnterpriseDatabase.firebaseRestUrl = _urlCtrl.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ मास्टर सेटिंग्स सफलतापूर्वक अपडेट कर दी गईं!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ त्रुटि: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearAllCloudDatabase() async {
    setState(() => _isClearing = true);
    try {
      final response = await http.delete(Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/products.json'));
      if (response.statusCode == 200) {
        setState(() {
          EnterpriseDatabase.globalInventory.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ क्लाउड डेटाबेस पूरी तरह साफ़ कर दिया गया है!'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ डेटा साफ़ करने में त्रुटि: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('मास्टर एडमिन पैनल (Master Control)', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
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
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Text('ग्लोबल शॉप प्रोफ़ाइल कॉन्फ़िगरेशन', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _shopNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'दुकान का नाम (Shop Name)', labelStyle: TextStyle(color: Colors.grey), isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'वेंडर मोबाइल नंबर (Phone)', labelStyle: TextStyle(color: Colors.grey), isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: _addressCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'दुकान का पता (Address - Faridabad)', labelStyle: TextStyle(color: Colors.grey), isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: _urlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'फायरबेस REST URL', labelStyle: TextStyle(color: Colors.grey), isDense: true)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                    onPressed: _isSaving ? null : _saveMasterSettings,
                    child: _isSaving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('सेटिंग्स सेव करें (Save Master Config)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ खतरनाक एडमिन ऑपरेशंस (Danger Zone)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('क्लाउड डेटाबेस से सभी उत्पादों को हमेशा के लिए हटाने के लिए नीचे दिए गए बटन का उपयोग करें।', style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
                    onPressed: _isClearing ? null : _clearAllCloudDatabase,
                    child: _isClearing
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('क्लाउड डेटाबेस खाली करें (Purge Cloud DB)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
