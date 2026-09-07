// ================= FILE: vendor_auth_view.dart =================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'vendor_dashboard_view.dart';

class VendorAuthView extends StatefulWidget {
  const VendorAuthView({Key? key}) : super(key: key);

  @override
  _VendorAuthViewState createState() => _VendorAuthViewState();
}

class _VendorAuthViewState extends State<VendorAuthView> {
  bool isLogin = true;
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  bool isLoading = false;

  Future<void> handleAuth() async {
    final mobile = _mobileController.text.trim();
    final pin = _pinController.text.trim();

    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("कृपया 10 अंकों का सही मोबाइल नंबर दर्ज करें")),
      );
      return;
    }
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("4-अंकों का पिन (MPIN) अनिवार्य है")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse('${EnterpriseDatabase.firebaseRestUrl}/vendors.json');
      final response = await http.get(url);

      Map<String, dynamic> vendors = {};
      if (response.statusCode == 200 && response.body != 'null') {
        vendors = json.decode(response.body) as Map<String, dynamic>;
      }

      if (isLogin) {
        String? foundVendorId;
        Map<String, dynamic>? foundVendorData;

        vendors.forEach((key, value) {
          if (value['mobileNumber'] == mobile && value['pin'] == pin) {
            foundVendorId = key;
            foundVendorData = value;
          }
        });

        if (foundVendorId != null) {
          EnterpriseDatabase.currentVendorId = foundVendorId;
          EnterpriseDatabase.currentShopName = foundVendorData?['shopName'] ?? 'मेरी दुकान';
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VendorDashboardView()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("गलत मोबाइल नंबर या 4-पिन!")),
          );
        }
      } else {
        bool exists = vendors.values.any((v) => v['mobileNumber'] == mobile);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("यह मोबाइल नंबर पहले से रजिस्टर्ड है!")),
          );
        } else {
          final newVendorData = {
            'shopName': _shopNameController.text.trim().isEmpty ? 'मेरी दुकान' : _shopNameController.text.trim(),
            'ownerName': _ownerNameController.text.trim(),
            'mobileNumber': mobile,
            'pin': pin,
          };

          final postResponse = await http.post(url, body: json.encode(newVendorData));
          if (postResponse.statusCode == 200) {
            final responseData = json.decode(postResponse.body);
            EnterpriseDatabase.currentVendorId = responseData['name'];
            EnterpriseDatabase.currentShopName = newVendorData['shopName'];

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VendorDashboardView()),
            );
          }
        }
      }
    } catch (e) {
      print("Auth Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: const Color(0xFF1E222B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isLogin ? 'वेंडर लॉगिन (4-पिन)' : 'नया वेंडर रजिस्ट्रेशन',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (!isLogin) ...[
                    TextField(
                      controller: _shopNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'दुकान का नाम (Shop Name)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ownerNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'मालिक का नाम (Owner Name)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'मोबाइल नंबर (10 अंक)', labelStyle: TextStyle(color: Colors.white70), counterText: ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: '4-अंकों का पिन (MPIN)', labelStyle: TextStyle(color: Colors.white70), counterText: ''),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.all(12)),
                          onPressed: handleAuth,
                          child: Text(isLogin ? 'लॉगिन करें' : 'रजिस्टर करें', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin ? 'नया खाता बनाएँ? रजिस्टर करें' : 'पहले से खाता है? लॉगिन करें', style: const TextStyle(color: Colors.amberAccent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
