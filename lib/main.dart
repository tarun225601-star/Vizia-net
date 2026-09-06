import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'marketplace_screen.dart';
import 'vendor_auth_and_portal.dart';
import 'cart_and_orders_view.dart';
import 'admin_master_dashboard.dart';

void main() {
  runApp(const ViziagMartEnterpriseApp());
}

class ViziagMartEnterpriseApp extends StatelessWidget {
  const ViziagMartEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart Enterprise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const ViziagMainHubScreen(),
    );
  }
}

class ViziagMainHubScreen extends StatefulWidget {
  const ViziagMainHubScreen({super.key});

  @override
  State<ViziagMainHubScreen> createState() => _ViziagMainHubScreenState();
}

class _ViziagMainHubScreenState extends State<ViziagMainHubScreen> {
  int _currentIndex = 0;

  final List<Widget> _navigationTabs = [
    const MarketplaceBuyerView(),
    const VendorAuthAndPortalView(),
    const CartAndOrdersView(),
  ];

  void _triggerMasterAdminDialog(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    const String masterSecretCode = "tarun#1";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('मास्टर एडमिन पैनल', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: pinController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'गुप्त कोड (tarun#1)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () {
              if (pinController.text.trim() == masterSecretCode) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminMasterDashboardScreen()),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ गलत गुप्त कोड दर्ज किया गया!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('खोलें', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int cartCount = EnterpriseDatabase.activeCart.fold(0, (sum, item) => sum + ((item['qty'] as num?)?.toInt() ?? 1));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          backgroundColor: const Color(0xFF0B0F19),
          elevation: 4,
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899)],
                ).createShader(bounds),
                child: const Text(
                  'VIZIAG MART',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.vpn_key, color: Color(0xFFF59E0B)),
                tooltip: 'Admin Access',
                onPressed: () => _triggerMasterAdminDialog(context),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
                icon: const Icon(Icons.store, size: 12),
                label: const Text('Shop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 12),
                label: const Text('Vendor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${EnterpriseDatabase.currentCustomerName} (${EnterpriseDatabase.currentDeliveryAddress})',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex > 2 ? 2 : _currentIndex,
          children: _navigationTabs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 2 ? 2 : _currentIndex,
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: const Color(0xFF0B0F19),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: 'Portal'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
}

Widget buildEnterpriseMediaLoader(String? path, double height, double width, IconData fallbackIcon) {
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http')) {
      return Image.network(path, height: height, width: width, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: const Color(0xFF334155), child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B))));
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
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B)),
  );
}
