import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key});

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  bool _isLoggedIn = false;
  bool _isAdminLoggedIn = false;
  bool _isRegistering = false;
  bool _isLoading = false;
  
  // Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regVehicleController = TextEditingController();
  final _regPasswordController = TextEditingController();

  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _pendingRiders = [];

  // 1. लॉगिन चेक (मोबाइल नंबर + पासवर्ड या आपका गुप्त एडमिन पासवर्ड)
  Future<void> _loginRider() async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showMsg('कृपया मोबाइल नंबर और पासवर्ड दर्ज करें!', Colors.red);
      return;
    }

    // यहाँ आप अपना मोबाइल नंबर और नीचे गुप्त पासवर्ड 'tarun#1' डालेंगे तो एडमिन पैनल खुलेगा
    if (password == 'tarun#1') {
      setState(() {
        _isAdminLoggedIn = true;
        _isLoggedIn = true;
      });
      _showMsg('👑 एडमिन पैनल लॉगिन सफल!', Colors.green);
      _fetchPendingRiders();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/riders.json'));
      if (res.statusCode == 200 && res.body != 'null') {
        Map<String, dynamic> data = json.decode(res.body);
        bool found = false;
        bool approved = false;

        data.forEach((key, value) {
          if (value is Map && value['phone'] == phone && value['password'] == password) {
            found = true;
            if (value['isApproved'] == true) {
              approved = true;
            }
          }
        });

        if (found && approved) {
          setState(() {
            _isLoggedIn = true;
            _isAdminLoggedIn = false;
            _isLoading = false;
          });
          _showMsg('🎉 राइडर लॉगिन सफल!', Colors.green);
          _fetchAssignedOrders();
        } else if (found && !approved) {
          setState(() => _isLoading = false);
          _showMsg('⏳ आपका अकाउंट अभी एडमिन द्वारा अप्रूव नहीं किया गया है!', Colors.orange);
        } else {
          setState(() => _isLoading = false);
          _showMsg('गलत मोबाइल नंबर या पासवर्ड!', Colors.red);
        }
      } else {
        setState(() => _isLoading = false);
        _showMsg('कोई राइडर रजिस्टर्ड नहीं है!', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg('एरर: $e', Colors.red);
    }
  }

  // 2. नया राइडर रजिस्ट्रेशन (पेंडिंग - isApproved: false)
  Future<void> _registerRider() async {
    String name = _regNameController.text.trim();
    String phone = _regPhoneController.text.trim();
    String vehicle = _regVehicleController.text.trim();
    String password = _regPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty || vehicle.isEmpty || password.isEmpty) {
      _showMsg('सभी फील्ड भरना अनिवार्य है!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/riders.json'),
        body: json.encode({
          'name': name,
          'phone': phone,
          'vehicle': vehicle,
          'password': password,
          'isApproved': false, // फ्रॉड रोकने के लिए पेंडिंग रहेगा
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      setState(() {
        _isLoading = false;
        _isRegistering = false;
      });
      _showMsg('✅ रजिस्ट्रेशन सफल! एडमिन अप्रूवल के बाद ही लॉगिन कर सकेंगे।', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg('रजिस्ट्रेशन एरर: $e', Colors.red);
    }
  }

  // 3. पेंडिंग राइडर्स फेच करना
  Future<void> _fetchPendingRiders() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/riders.json'));
      if (res.statusCode == 200 && res.body != 'null') {
        Map<String, dynamic> data = json.decode(res.body);
        List<Map<String, dynamic>> list = [];
        data.forEach((key, value) {
          if (value is Map) {
            var r = Map<String, dynamic>.from(value);
            r['riderId'] = key;
            if (r['isApproved'] != true) {
              list.add(r);
            }
          }
        });
        setState(() => _pendingRiders = list);
      }
    } catch (e) {
      debugPrint("Fetch pending error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 4. राइडर अप्रूव करना
  Future<void> _approveRider(String riderId) async {
    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/riders/$riderId.json'),
        body: json.encode({'isApproved': true}),
      );
      _showMsg('✅ राइडर सक्सेसफुली अप्रूव हो गया!', Colors.green);
      _fetchPendingRiders();
    } catch (e) {
      _showMsg('अप्रूवल एरर: $e', Colors.red);
    }
  }

  void _showMsg(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  // 5. लाइव ऑर्डर्स फेच करना
  Future<void> _fetchAssignedOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> loadedOrders = [];
        data.forEach((key, value) {
          if (value is Map) {
            var order = Map<String, dynamic>.from(value);
            order['orderId'] = key;
            loadedOrders.add(order);
          }
        });
        if (mounted) {
          setState(() {
            _activeOrders = loadedOrders.reversed.toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Rider fetch orders error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderId.json'),
        body: json.encode({'orderStatus': newStatus, 'status': newStatus}),
      );
      _showMsg('✅ आर्डर स्टेटस बदलकर "$newStatus" कर दिया गया है!', Colors.green);
      _fetchAssignedOrders();
    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(_isRegistering ? '📝 नया राइडर रजिस्ट्रेशन' : '🚴‍♂️ राइडर पोर्टल लॉगिन', 
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _isRegistering ? _buildRegisterForm() : _buildLoginForm(),
              ),
            ),
          ),
        ),
      );
    }

    if (_isAdminLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('👑 एडमिन: राइडर अप्रूवल पैनल', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () => setState(() { _isLoggedIn = false; _isAdminLoggedIn = false; }),
              tooltip: 'लॉग आउट',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _pendingRiders.isEmpty
                ? const Center(child: Text('कोई नया राइडर अप्रूवल के लिए पेंडिंग नहीं है!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pendingRiders.length,
                    itemBuilder: (context, index) {
                      var rider = _pendingRiders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(rider['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('फोन: ${rider['phone']}\nवाहन: ${rider['vehicle']}'),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _approveRider(rider['riderId']),
                            child: const Text('Approve'),
                          ),
                        ),
                      );
                    },
                  ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('🚴‍♂️ राइडर डिलीवरी डैशबोर्ड', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.green.shade700),
            onPressed: _fetchAssignedOrders,
            tooltip: 'रिफ्रेश करें',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => setState(() => _isLoggedIn = false),
            tooltip: 'लॉग आउट',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _activeOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('कोई नया डिलीवरी ऑर्डर उपलब्ध नहीं है!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAssignedOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _activeOrders.length,
                    itemBuilder: (context, index) {
                      var order = _activeOrders[index];
                      String orderId = order['orderId'] ?? '';
                      String customerName = order['customerName'] ?? order['name'] ?? 'Customer';
                      String phone = order['customerPhone'] ?? order['phone'] ?? '';
                      String deliveryAddress = order['customerAddress'] ?? order['deliveryAddress'] ?? order['address'] ?? 'पता उपलब्ध नहीं';
                      
                      String shopName = order['shopName'] ?? 'Tarun Fruit & Vegetable Shop';
                      String pickupAddress = order['shopAddress'] ?? 'Sector 15A, Faridabad';
                      String status = order['orderStatus'] ?? order['status'] ?? 'Pending ⏳';
                      var items = order['items'] as List<dynamic>? ?? [];
                      double totalAmount = (order['totalAmount'] ?? order['grandTotal'] ?? 0.0).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('📦 Order ID: ${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status.contains('Delivered') ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, 
                                        color: status.contains('Delivered') ? Colors.green.shade800 : Colors.orange.shade800)),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.store, size: 15, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('पिकअप (Shop): $shopName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue))),
                                    ]),
                                    const SizedBox(height: 4),
                                    Padding(padding: const EdgeInsets.only(left: 21), child: Text(pickupAddress, style: const TextStyle(fontSize: 11))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.person_pin_circle, size: 15, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('डिलीवरी: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent))),
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Padding(padding: const EdgeInsets.only(left: 21), child: Text(deliveryAddress, style: const TextStyle(fontSize: 11))),
                                  ],
                                ),
                              ),
                              const Divider(height: 16),
                              const Text('खरीदे गए आइटम्स:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              ...items.map((item) {
                                var m = item is Map ? item : {};
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('• ${m['name'] ?? 'Item'} (${m['qty'] ?? 1} ${m['unit'] ?? 'Kg'})', style: const TextStyle(fontSize: 12)),
                                    Text('₹${((m['price'] ?? 0.0) * (m['qty'] ?? 1.0)).toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                );
                              }),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('कुल राशि: ₹${totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                  Text('कुल आइटम्स: ${items.length}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                    onPressed: () => _updateOrderStatus(orderId, 'Out for Delivery 🚴‍♂️'),
                                    icon: const Icon(Icons.directions_bike, size: 14),
                                    label: const Text('Out for Delivery', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                                    onPressed: () => _updateOrderStatus(orderId, 'Delivered 🎉'),
                                    icon: const Icon(Icons.check_circle, size: 14),
                                    label: const Text('Delivered', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('अपने मोबाइल नंबर और पासवर्ड से लॉगिन करें', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _isLoading ? null : _loginRider,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('लॉगिन करें', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _isRegistering = true),
          child: const Text('नया राइडर हैं? यहाँ रजिस्टर करें', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('नया डिलीवरी बॉय अकाउंट बनाएं', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(controller: _regNameController, decoration: const InputDecoration(labelText: 'पूरा नाम', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _regPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _regVehicleController, decoration: const InputDecoration(labelText: 'वाहन विवरण (उदा: Bike / Scooty)', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _regPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _isLoading ? null : _registerRider,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('रजिस्टर करें', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _isRegistering = false),
          child: const Text('पहले से अकाउंट है? लॉगिन करें', style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }
}
