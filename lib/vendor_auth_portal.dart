import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'database_models.dart';

class VendorAuthAndPortalView extends StatefulWidget {
  const VendorAuthAndPortalView({super.key});

  @override
  State<VendorAuthAndPortalView> createState() => _VendorAuthAndPortalViewState();
}

class _VendorAuthAndPortalViewState extends State<VendorAuthAndPortalView> {
  int _viewMode = 0;

  final regShopNameCtrl = TextEditingController();
  final regPhoneCtrl = TextEditingController();
  final regAddressCtrl = TextEditingController();
  final regPass1Ctrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();

  final loginPhoneCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isShopOpen = true; 

  List<Map<String, dynamic>> _vendorOrders = [];
  Timer? _orderFetchTimer;
  int _lastOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _isShopOpen = CakeDatabase.bakeryShop['isOpen'] ?? true;
  }

  @override
  void dispose() {
    _orderFetchTimer?.cancel();
    regShopNameCtrl.dispose();
    regPhoneCtrl.dispose();
    regAddressCtrl.dispose();
    regPass1Ctrl.dispose();
    regPass2Ctrl.dispose();
    loginPhoneCtrl.dispose();
    loginPassCtrl.dispose();
    super.dispose();
  }

  void _startVendorOrderListener() {
    _fetchVendorOrders();
    _orderFetchTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_viewMode == 3) {
        await _fetchVendorOrders(isBackgroundCheck: true);
      }
    });
  }

  // 🚀 केवल नए और लाइव ऑर्डर फेच करेगा, डिलीवर हुए आर्डर अपने आप छंट जाएंगे
  Future<void> _fetchVendorOrders({bool isBackgroundCheck = false}) async {
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        List<Map<String, dynamic>> loadedOrders = [];
        
        data.forEach((key, val) {
          if (val is Map) {
            var ord = Map<String, dynamic>.from(val);
            ord['orderId'] = key;
            
            // स्टेटस चेक: केवल वही आर्डर रखेंगे जो डिलीवर नहीं हुए हैं
            String status = ord['orderStatus'] ?? ord['status'] ?? 'Pending';
            if (!status.toLowerCase().contains('delivered')) {
              loadedOrders.add(ord);
            }
          }
        });

        loadedOrders = loadedOrders.reversed.toList();

        if (mounted) {
          if (isBackgroundCheck && loadedOrders.length > _lastOrderCount) {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 नया आर्डर प्राप्त हुआ है!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }

          setState(() {
            _vendorOrders = loadedOrders;
            _lastOrderCount = loadedOrders.length;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _vendorOrders = [];
            _lastOrderCount = 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Vendor fetch error: $e");
    }
  }

  // 🗑️ हर ऑर्डर पर डिलीट बटन का फंक्शन
  Future<void> _deleteOrder(String orderId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ आर्डर डिलीट करें?'),
        content: const Text('क्या आप इस आर्डर को हमेशा के लिए हटाना चाहते हैं?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('नहीं')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('हाँ, डिलीट करें', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await http.delete(
          Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderId.json'),
        );

        if (res.statusCode == 200) {
          HapticFeedback.mediumImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🗑️ आर्डर हमेशा के लिए डिलीट कर दिया गया!'), backgroundColor: Colors.red),
            );
          }
          _fetchVendorOrders();
        }
      } catch (e) {
        debugPrint("Delete order error: $e");
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderId.json'),
        body: json.encode({'status': newStatus, 'orderStatus': newStatus}),
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ आर्डर स्टेटस बदलकर "$newStatus" कर दिया गया!'), backgroundColor: Colors.green));
      }
      _fetchVendorOrders();
    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  // ⏱️ समय और डेट को सही फॉर्मेट में दिखाने वाला फंक्शन
  String _getTimeAgo(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'अभी-अभी';
    try {
      DateTime orderTime = DateTime.parse(timeStr);
      Duration diff = DateTime.now().difference(orderTime);
      if (diff.inMinutes < 1) return 'अभी-अभी';
      if (diff.inMinutes < 60) return '${diff.inMinutes} मिनट पहले';
      if (diff.inHours < 24) return '${diff.inHours} घंटे पहले';
      return '${orderTime.day}/${orderTime.month} ${orderTime.hour.toString().padLeft(2, '0')}:${orderTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _submitRegistration() async {
    if (regPhoneCtrl.text.trim().length < 10 || regShopNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया दुकान का नाम और सही मोबाइल नंबर भरें!'), backgroundColor: Colors.red));
      return;
    }
    if (regPass1Ctrl.text.isEmpty || regPass1Ctrl.text != regPass2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ पासवर्ड मेल नहीं खा रहे हैं!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var shopData = {
        'name': regShopNameCtrl.text.trim(),
        'phone': regPhoneCtrl.text.trim(),
        'address': regAddressCtrl.text.trim().isEmpty ? 'Faridabad' : regAddressCtrl.text.trim(),
        'pass': regPass1Ctrl.text.trim(),
        'status': 'pending',
      };

      await http.post(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'),
        body: json.encode(shopData),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⏳ रिक्वेस्ट सबमिट हो गई'),
            content: const Text('आपकी दुकान का रजिस्ट्रेशन हो गया है। मास्टर एडमिन द्वारा अप्रूव होने के बाद ही आप लॉगिन कर पाएंगे।'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _viewMode = 0);
                },
                child: const Text('ठीक है'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginVendor() async {
    String phone = loginPhoneCtrl.text.trim();
    String pass = loginPassCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ कृपया मोबाइल नंबर और पासवर्ड दर्ज करें!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/vendor_requests.json'));
      bool isApproved = false;

      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(res.body);
        data.forEach((key, val) {
          if (val['phone'] == phone && val['pass'] == pass && val['status'] == 'approved') {
            isApproved = true;
          }
        });
      }

      if (isApproved) {
        setState(() => _viewMode = 3);
        _startVendorOrderListener();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ स्वागत है! वेंडर डैशबोर्ड खुल गया है।'), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ लॉगिन असफल (Not Approved)'),
              content: const Text('आपकी दुकान अभी तक मास्टर एडमिन द्वारा अप्रूव नहीं की गई है!'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है')),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleShopStatus(bool value) async {
    setState(() => _isShopOpen = value);
    CakeDatabase.bakeryShop['isOpen'] = value;

    try {
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/shop_profile.json'),
        body: json.encode({'isOpen': value}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '🟢 दुकान अब खुली (Open) है।' : '🔴 दुकान अब बंद (Closed) कर दी गई है।'),
            backgroundColor: value ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Shop status update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode == 0) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 75, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🛍️ वेंडर पोर्टल', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('दुकानदार लॉगिन और नया रजिस्ट्रेशन', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: () => setState(() => _viewMode = 1),
                icon: const Icon(Icons.person_add),
                label: const Text('नई दुकान रजिस्टर करें (New Registration)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green, width: 2), foregroundColor: Colors.green.shade800),
                onPressed: () => setState(() => _viewMode = 2),
                icon: const Icon(Icons.login),
                label: const Text('वेंडर लॉगिन (Existing Vendor Login)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 1) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            const Center(child: Text('📝 नया वेंडर रजिस्ट्रेशन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            TextField(controller: regShopNameCtrl, decoration: const InputDecoration(labelText: 'दुकान का नाम (Shop Name)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 15),
            TextField(controller: regPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: regAddressCtrl, decoration: const InputDecoration(labelText: 'दुकान का पता / लोकेशन', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 15),
            TextField(controller: regPass1Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड बनाएं', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 15),
            TextField(controller: regPass2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड दोबारा दर्ज करें', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _submitRegistration,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('अप्रूवल के लिए सबमिट करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं')),
          ],
        ),
      );
    }

    if (_viewMode == 2) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 65, color: Colors.green),
            const SizedBox(height: 15),
            const Text('🔐 वेंडर लॉगिन', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('वेंडर पोर्टल में आपका स्वागत है', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 25),
            TextField(controller: loginPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), counterText: '', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: loginPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'पासवर्ड', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _loginVendor,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('लॉगिन करें ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _viewMode = 0), child: const Text('← वापस जाएं', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('दुकान की स्थिति', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        _isShopOpen ? '🟢 खुली हुई है (Open)' : '🔴 बंद है (Closed)',
                        style: TextStyle(color: _isShopOpen ? Colors.green.shade700 : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isShopOpen,
                    activeColor: Colors.green,
                    onChanged: _toggleShopStatus,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red, size: 22),
                    onPressed: () {
                      _orderFetchTimer?.cancel();
                      setState(() => _viewMode = 0);
                    },
                    tooltip: 'लॉग आउट',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📦 नए लाइव ऑर्डर्स', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.green, size: 20),
                onPressed: () => _fetchVendorOrders(),
                tooltip: 'रिफ्रेश करें',
              ),
            ],
          ),
          const Divider(height: 8),

          Expanded(
            child: _vendorOrders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('अभी कोई नया ऑर्डर नहीं है...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _vendorOrders.length,
                    itemBuilder: (context, index) {
                      var ord = _vendorOrders[index];
                      String orderId = ord['orderId'] ?? '';
                      String customerName = ord['customerName'] ?? 'Customer';
                      String phone = ord['customerPhone'] ?? '';
                      String address = ord['customerAddress'] ?? ord['deliveryAddress'] ?? 'पता नहीं';
                      String status = ord['orderStatus'] ?? ord['status'] ?? 'Pending ⏳';
                      var items = ord['items'] as List<dynamic>? ?? [];
                      double total = (ord['grandTotal'] ?? ord['totalAmount'] ?? 0.0).toDouble();
                      
                      // ⏱️ टाइम और डेट प्राप्त करें (कई बार डेटाबेस में orderTime या timestamp होता है)
                      String timeAgo = _getTimeAgo(ord['orderTime'] ?? ord['timestamp']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('📦 #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                                  
                                  Row(
                                    children: [
                                      // ⏱️ यहाँ टाइमर और डेट स्पष्ट रूप से दिखाई देगा
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 10, color: Colors.black54),
                                            const SizedBox(width: 4),
                                            Text(timeAgo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 🗑️ हर ऑर्डर पर डिलीट बटन
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => _deleteOrder(orderId),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'ऑर्डर डिलीट करें',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ग्राहक: $customerName ($phone)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: status.contains('Accepted') ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, 
                                        color: status.contains('Accepted') ? Colors.green.shade800 : Colors.orange.shade800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('पता: $address', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const Divider(height: 12),
                              ...items.map((it) => Text('• ${it['name']} (x${it['qty']}) - ₹${it['price']}', style: const TextStyle(fontSize: 11))),
                              const SizedBox(height: 8),
                              
                              // 🔘 एक्सेप्ट और एक्शन बटन्स
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('कुल: ₹${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  
                                  Row(
                                    children: [
                                      // अगर आर्डर अभी पेंडिंग है तो एक्सेप्ट बटन दिखाओ
                                      if (!status.contains('Accepted') && !status.contains('Out for Delivery'))
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700, 
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          onPressed: () => _updateOrderStatus(orderId, 'Accepted by Vendor 🟢'),
                                          icon: const Icon(Icons.check, size: 14),
                                          label: const Text('ऑर्डर एक्सेप्ट करें', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),

                                      // अगर एक्सेप्ट हो गया है, तो डिलीवरी के लिए भेजने का बटन दिखाओ
                                      if (status.contains('Accepted')) ...[
                                        const SizedBox(width: 6),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange.shade800,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          ),
                                          onPressed: () => _updateOrderStatus(orderId, 'Out for Delivery 🚴‍♂️'),
                                          icon: const Icon(Icons.delivery_dining, size: 14),
                                          label: const Text('Out for Delivery', style: TextStyle(fontSize: 10)),
                                        ),
                                      ],
                                    ],
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
        ],
      ),
    );
  }
}
