// ================= FILE: vendor_dashboard_view.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';

class VendorDashboardView extends StatefulWidget {
  const VendorDashboardView({super.key});

  @override
  State<VendorDashboardView> createState() => _VendorDashboardViewState();
}

class _VendorDashboardViewState extends State<VendorDashboardView> {
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('नया उत्पाद जोड़ें', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'उत्पाद का नाम',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'कीमत (₹)',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'स्टॉक मात्रा',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                setState(() {
                  EnterpriseDatabase.globalInventory.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'stock': int.tryParse(stockController.text) ?? 10,
                    'category': 'General',
                    'image': '',
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('जोड़ें', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          '${EnterpriseDatabase.activeShopProfile['shopName']} - डैशबोर्ड',
          style: const TextStyle(color: Colors.amber),
        ),
      ),
      body: EnterpriseDatabase.globalInventory.isEmpty
          ? const Center(
              child: Text(
                'कोई उत्पाद उपलब्ध नहीं है।\nनीचे दिए गए + बटन से नया उत्पाद जोड़ें।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: EnterpriseDatabase.globalInventory.length,
              itemBuilder: (context, index) {
                final item = EnterpriseDatabase.globalInventory[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      item['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'कीमत: ₹${item['price']} | स्टॉक: ${item['stock']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          EnterpriseDatabase.globalInventory.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
