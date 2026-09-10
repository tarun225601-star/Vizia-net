import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key});

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  // Profile Controllers
  final TextEditingController nameController = TextEditingController(text: 'Tarun Kumar');
  final TextEditingController phoneController = TextEditingController(text: '9971968060');
  final TextEditingController vehicleController = TextEditingController(text: 'HR-51-AB-1234');
  final TextEditingController addressController = TextEditingController(text: 'Faridabad Hub, Haryana');

  bool isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadRiderProfile();
  }

  Future<void> _loadRiderProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        nameController.text = prefs.getString('rider_name') ?? 'Tarun Kumar';
        phoneController.text = prefs.getString('rider_phone') ?? '9971968060';
        vehicleController.text = prefs.getString('rider_vehicle') ?? 'HR-51-AB-1234';
        addressController.text = prefs.getString('rider_address') ?? 'Faridabad Hub, Haryana';
      });
    } catch (e) {
      debugPrint("Load profile error: $e");
    }
  }

  Future<void> _saveRiderProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rider_name', nameController.text.trim());
      await prefs.setString('rider_phone', phoneController.text.trim());
      await prefs.setString('rider_vehicle', vehicleController.text.trim());
      await prefs.setString('rider_address', addressController.text.trim());

      setState(() => isEditingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Save profile error: $e");
    }
  }

  Future<void> _updateOrderStatus(String orderKey, String newStatus) async {
    try {
      await FirebaseDatabase.instance.ref('orders/$orderKey').update({
        'status': newStatus,
        'riderPhone': phoneController.text,
        'vehicleNumber': vehicleController.text,
      });
    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          title: const Text('Rider Delivery Dashboard', style: TextStyle(color: Color(0xFFF59E0B))),
          backgroundColor: const Color(0xFF1E293B),
          bottom: const TabBar(
            labelColor: Color(0xFFF59E0B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFF59E0B),
            tabs: [
              Tab(icon: Icon(Icons.delivery_dining), text: 'Active Orders'),
              Tab(icon: Icon(Icons.person), text: 'Rider Profile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Active Orders View
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref('orders').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text('No active delivery orders found.', style: TextStyle(color: Colors.grey)),
                  );
                }
                try {
                  Map map = snapshot.data!.snapshot.value as Map;
                  List keys = map.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      try {
                        HapticFeedback.mediumImpact();
                      } catch (_) {}

                      String key = keys[index];
                      var ord = map[key];
                      String status = ord['status'] ?? 'Pending';
                      var items = ord['items'] ?? [];

                      String itemsSummary = '';
                      if (items is List) {
                        itemsSummary = items.map((i) => '${i['name']} (₹${i['price']})').join(', ');
                      }

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order Total: ₹${ord['total'] ?? 0}',
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getStatusColor(status)),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Items: $itemsSummary', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('Pickup/Delivery Hub: ${addressController.text}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const Divider(color: Colors.white24, height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Color(0xFFF59E0B)),
                                    onPressed: () async {
                                      try {
                                        final Uri phoneUri = Uri.parse('tel:${phoneController.text}');
                                        if (await canLaunchUrl(phoneUri)) {
                                          await launchUrl(phoneUri);
                                        }
                                      } catch (e) {
                                        debugPrint("Phone launch error: $e");
                                      }
                                    },
                                  ),
                                  Row(
                                    children: [
                                      if (status == 'Pending')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                          onPressed: () => _updateOrderStatus(key, 'Accepted'),
                                          child: const Text('Accept'),
                                        ),
                                      if (status == 'Accepted')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                                          onPressed: () => _updateOrderStatus(key, 'Picked Up'),
                                          child: const Text('Picked Up'),
                                        ),
                                      if (status == 'Picked Up')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                          onPressed: () => _updateOrderStatus(key, 'Delivered'),
                                          child: const Text('Delivered'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } catch (e) {
                  return Center(child: Text('Order load error: $e', style: const TextStyle(color: Colors.red)));
                }
              },
            ),

            // Tab 2: Rider Profile View & Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFFF59E0B),
                      child: Icon(Icons.delivery_dining, size: 50, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    enabled: isEditingProfile,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Rider Full Name',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    enabled: isEditingProfile,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: vehicleController,
                    enabled: isEditingProfile,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number (गाड़ी नंबर)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    enabled: isEditingProfile,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Full Address (फुल एड्रेस)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B))),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (isEditingProfile) {
                        _saveRiderProfile();
                      } else {
                        setState(() => isEditingProfile = true);
                      }
                    },
                    child: Text(
                      isEditingProfile ? 'Save Profile' : 'Edit Profile',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orangeAccent;
      case 'Accepted':
        return Colors.blueAccent;
      case 'Picked Up':
        return Colors.purpleAccent;
      case 'Delivered':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }
}
