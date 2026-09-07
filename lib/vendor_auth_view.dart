// ================= FILE: vendor_auth_view.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';
import 'vendor_dashboard_view.dart';

class VendorAuthView extends StatefulWidget {
  const VendorAuthView({super.key});

  @override
  State<VendorAuthView> createState() => _VendorAuthViewState();
}

class VendorAuthAndPortalView extends StatelessWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  Widget build(BuildContext context) {
    return const VendorAuthView();
  }
}

class _VendorAuthViewState extends State<VendorAuthView> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mpinController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  bool _isRegistering = false;

  void _handleAuth() {
    final phone = _phoneController.text.trim();
    final mpin = _mpinController.text.trim();
    final shopName = _shopNameController.text.trim();

    if (phone.isEmpty || mpin.isEmpty || (_isRegistering && shopName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया सभी आवश्यक जानकारी भरें')),
      );
      return;
    }

    // लोकल डेटाबेस में सेशन सेट करना
    EnterpriseDatabase.currentVendorId = phone;
    EnterpriseDatabase.currentShopName = _isRegistering ? shopName : "मेरी दुकान";

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VendorDashboardView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'वेंडर पोर्टल',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(y: 30),
                if (_isRegistering) ...[
                  TextField(
                    controller: _shopNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'दुकान का नाम',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'मोबाइल नंबर',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _mpinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '4-अंकों का MPIN',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _handleAuth,
                  child: Text(
                    _isRegistering ? 'रजिस्टर करें' : 'लॉगिन करें',
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                    });
                  },
                  child: Text(
                    _isRegistering ? 'पहले से खाता है? लॉगिन करें' : 'नया खाता बनाएँ (Register)',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
