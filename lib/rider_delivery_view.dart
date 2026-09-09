import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert'; // 👈 यह इम्पोर्ट जोड़ दिया गया है (एरर खत्म)
import 'database_models.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderDeliveryScreen extends StatefulWidget {
  final String riderPhone;

  const RiderDeliveryScreen({
    Key? key, 
    this.riderPhone = '',
  }) : super(key: key);

  @override
  _RiderDeliveryScreenState createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  
  bool _isCheckingSession = true;
  bool _isRegistered = false;
  bool _isLoading = false;

  Map<String, dynamic> _currentOrder = {};
  bool _isLoadingOrder = true;
  String _activeRiderPhone = '';
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _vibrationTimer;
  StreamSubscription<DatabaseEvent>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _checkSavedRider();
  }

  Future<void> _checkSavedRider() async {
    final prefs = await SharedPreferences.getInstance();
    String savedPhone = prefs.getString('saved_rider_phone') ?? '';

    if (savedPhone.isNotEmpty) {
      setState(() {
        _activeRiderPhone = savedPhone;
        _isRegistered = true;
        _isCheckingSession = false;
      });
      _loadCachedOrderAndListen();
    } else {
      setState(() {
        _isRegistered = false;
        _isCheckingSession = false;
      });
    }
  }

  // 1️⃣ पहले लोकल स्टोरेज से तुरंत डेटा दिखाओ ताकि लोडिंग न हो
  Future<void> _loadCachedOrderAndListen() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedOrderJson = prefs.getString('cached_active_order_$_activeRiderPhone');
    if (cachedOrderJson != null) {
      try {
        Map<String, dynamic> cachedMap = json.decode(cachedOrderJson);
        if (mounted) {
          setState(() {
            _currentOrder = cachedMap;
            _isLoadingOrder = false;
          });
        }
      } catch (_) {}
    }
    
    // 2️⃣ अब Firebase का रियलटाइम लिसनर चालू करो
    _startRealtimeOrderListener();
  }

  Future<void> _registerRider() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String riderId = "rider_${DateTime.now().millisecondsSinceEpoch}";
        String phone = _phoneController.text.trim();
        String vehicleNumber = _vehicleController.text.trim().toUpperCase();
        String name = _nameController.text.trim();
        
        var riderData = {
          'riderId': riderId,
          'name': name,
          'phone': phone,
          'vehicleNumber': vehicleNumber,
          'isReady': true,
        };

        DatabaseReference ref = FirebaseDatabase.instance.ref('riders').push();
        await ref.set(riderData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_rider_phone', phone);
        await prefs.setString('saved_rider_name', name);
        await prefs.setString('saved_vehicle_number', vehicleNumber);

        if (mounted) {
          setState(() {
            _activeRiderPhone = phone;
            _isRegistered = true;
            _isLoading = false;
          });
          _loadCachedOrderAndListen();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 राइडर सफलतापूर्वक रजिस्टर हो गया!")),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ एरर: $e")),
          );
        }
      }
    }
  }

  // 🟢 रियलटाइम आर्डर लिसनर
  void _startRealtimeOrderListener() {
    _orderSubscription?.cancel();
    DatabaseReference ordersRef = FirebaseDatabase.instance.ref('orders');

    _orderSubscription = ordersRef.onValue.listen((event) {
      final data = event.snapshot.value;
      Map<String, dynamic>? activeOrder;

      if (data != null && data is Map) {
        data.forEach((key, val) {
          if (val != null && val is Map) {
            String status = val['orderStatus'] ?? val['status'] ?? '';
            String rPhone = val['riderPhone'] ?? val['phone'] ?? '';
            
            if (status == 'Out for Delivery' && rPhone.toString().trim() == _activeRiderPhone.trim()) {
              activeOrder = Map<String, dynamic>.from(val);
              activeOrder!['orderKey'] = key;
            }
          }
        });
      }

      if (mounted) {
        setState(() {
          bool wasEmpty = _currentOrder.isEmpty;
          _currentOrder = activeOrder ?? {};
          _isLoadingOrder = false;

          if (wasEmpty && _currentOrder.isNotEmpty) {
            _startAlertAndTimer();
          } else if (_currentOrder.isEmpty) {
            _stopAlertAndTimer();
          }
        });

        // लोकल स्टोरेज में सेव करें
        _saveOrderToCache();
      }
    });
  }

  Future<void> _saveOrderToCache() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentOrder.isNotEmpty) {
      prefs.setString('cached_active_order_$_activeRiderPhone', json.encode(_currentOrder));
    } else {
      prefs.remove('cached_active_order_$_activeRiderPhone');
    }
  }

  void _startAlertAndTimer() {
    _timer?.cancel();
    _vibrationTimer?.cancel();

    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopAlertAndTimer() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
  }

  @override
  void dispose() {
    _stopAlertAndTimer();
    _orderSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remSec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remSec.toString().padLeft(2, '0')}';
  }

  Future<void> _sendDetailsToWhatsApp() async {
    String shopName = _currentOrder['shopName'] ?? CakeDatabase.bakeryShop['shopName'] ?? 'Viziag Mart';
    String pickupAddr = _currentOrder['pickupAddress'] ?? _currentOrder['address'] ?? CakeDatabase.bakeryShop['address'] ?? 'Faridabad';
    String customerName = _currentOrder['customerName'] ?? 'कस्टमर';
    String customerPhone = _currentOrder['customerPhone'] ?? _currentOrder['phone'] ?? '';
    String deliveryAddr = _currentOrder['deliveryAddress'] ?? _currentOrder['address'] ?? 'पता उपलब्ध नहीं';
    String orderId = _currentOrder['orderId'] ?? _currentOrder['orderKey']?.toString().substring(1) ?? '101';

    String message = '''
🛵 *डिफ़ॉल्ट डिलीवरी आर्डर* 🛵

📦 *ऑर्डर आईडी:* #$orderId
💵 *राइडर कमाई:* ₹40 फिक्स

🟢 *1. पिकअप (यहाँ से माल उठाएं):*
• दुकान: $shopName
• पता: $pickupAddr

🔴 *2. ड्रॉप (यहाँ माल पहुँचाएं):*
• ग्राहक: $customerName
• फोन: $customerPhone
• पता: $deliveryAddr

समय पर सुरक्षित डिलीवरी करें! 🚀
''';

    String targetPhone = _activeRiderPhone.isEmpty ? '9971968060' : _activeRiderPhone;
    String formattedPhone = targetPhone.startsWith('+') ? targetPhone : '+91$targetPhone';
    String url = "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (!_isRegistered) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("राइडर रजिस्ट्रेशन (Viziag Mart)", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green[700],
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    "अपने डिलीवरी पार्टनर को यहाँ जोड़ें:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "राइडर का पूरा नाम", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    validator: (value) => value!.isEmpty ? 'कृपया नाम दर्ज करें' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "मोबाइल नंबर", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    validator: (value) => value!.length < 10 ? 'सही मोबाइल नंबर दर्ज करें' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(labelText: "गाड़ी/बाइक नंबर", border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_bike)),
                    validator: (value) => value!.isEmpty ? 'गाड़ी का नंबर दर्ज करें' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      onPressed: _isLoading ? null : _registerRider,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("राइडर रजिस्टर करें", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    bool hasOrder = _currentOrder.isNotEmpty;

    return Scaffold(
      backgroundColor: hasOrder ? Colors.red[900] : Colors.white,
      appBar: AppBar(
        title: Text("राइडर डैशबोर्ड ($_activeRiderPhone)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingOrder
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: hasOrder
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "🚨 नया डिलीवरी आर्डर आया है!",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatTime(_secondsElapsed),
                            style: const TextStyle(color: Colors.yellowAccent, fontSize: 45, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📦 आर्डर ID: #${_currentOrder['orderId'] ?? _currentOrder['orderKey'] ?? 'N/A'}",
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const Divider(thickness: 2),
                                    const SizedBox(height: 10),
                                    const Text("🟢 पिकअप पता:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                    Text(_currentOrder['pickupAddress'] ?? _currentOrder['address'] ?? 'Faridabad',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    const SizedBox(height: 15),
                                    const Text("🔴 डिलीवरी पता:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                    Text(_currentOrder['deliveryAddress'] ?? _currentOrder['address'] ?? 'Faridabad',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 10),
                                    Text("👤 ग्राहक नाम: ${_currentOrder['customerName'] ?? 'Tarun'}", style: const TextStyle(color: Colors.black87)),
                                    Text("📞 फोन: ${_currentOrder['customerPhone'] ?? _currentOrder['phone'] ?? ''}", style: const TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _stopAlertAndTimer();
                              _sendDetailsToWhatsApp();
                            },
                            child: const Text(
                              "आर्डर स्वीकार करें & WhatsApp पर भेजें",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delivery_dining, size: 80, color: Colors.green[700]),
                            const SizedBox(height: 20),
                            const Text("स्वागत है, राइडर पार्टनर!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            const Text(
                              "रियलटाइम मोड एक्टिव है। नया आर्डर आते ही अपने आप स्क्रीन पर प्रकट हो जाएगा!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }
}
