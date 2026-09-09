import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'database_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  Timer? _pollingTimer;

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
      // 🟢 ऐप खुलते ही तुरंत लोकल कैश्ड आर्डर दिखाओ ताकि लोडिंग न दिखे
      _loadCachedOrdersAndPoll();
    } else {
      setState(() {
        _isRegistered = false;
        _isCheckingSession = false;
      });
    }
  }

  // 1️⃣ पहले लोकल स्टोरेज से तुरंत डेटा दिखाओ (बिना लोडिंग टाइम के)
  Future<void> _loadCachedOrdersAndPoll() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedOrderJson = prefs.getString('cached_active_order_$_activeRiderPhone');
    if (cachedOrderJson != null) {
      try {
        Map<String, dynamic> cachedMap = json.decode(cachedOrderJson);
        if (mounted) {
          setState(() {
            _currentOrder = cachedMap;
            _isLoadingOrder = false; // तुरंत लोडिंग खत्म
          });
        }
      } catch (_) {}
    }
    
    // फिर बैकग्राउंड में सर्वर से लेटेस्ट आर्डर चेक करो
    _startOrderPolling();
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

        await http.post(
          Uri.parse('${CakeDatabase.firebaseRestUrl}/riders.json'),
          body: json.encode(riderData),
        );

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
          _loadCachedOrdersAndPoll();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 राइडर सफलतापर्वक रजिस्टर हो गया!")),
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

  void _startOrderPolling() {
    _fetchAssignedOrder();
    _pollingTimer?.cancel();
    // हर 5 सेकंड में सिर्फ बैकग्राउंड सिंक (हल्का फेच)
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchAssignedOrder();
    });
  }

  Future<void> _fetchAssignedOrder() async {
    if (_activeRiderPhone.isEmpty) return;

    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> orders = json.decode(res.body);
        Map<String, dynamic>? activeOrder;

        orders.forEach((key, val) {
          if (val != null) {
            String status = val['orderStatus'] ?? val['status'] ?? '';
            String rPhone = val['riderPhone'] ?? val['phone'] ?? '';
            
            if (status == 'Out for Delivery' && rPhone.toString().trim() == _activeRiderPhone.trim()) {
              activeOrder = Map<String, dynamic>.from(val);
              activeOrder!['orderKey'] = key;
            }
          }
        });

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

          // 🟢 लोकल स्टोरेज में तुरंत सेव करो ताकि अगली बार बिना लोडिंग के दिखे
          final prefs = await SharedPreferences.getInstance();
          if (_currentOrder.isNotEmpty) {
            prefs.setString('cached_active_order_$_activeRiderPhone', json.encode(_currentOrder));
          } else {
            prefs.remove('cached_active_order_$_activeRiderPhone');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _currentOrder = {};
            _isLoadingOrder = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOrder = false);
      }
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
    _pollingTimer?.cancel();
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
🛵 *Porter स्टाइल डिलीवरी आर्डर (5 किमी के अंदर)* 🛵

📦 *ऑर्डर आईडी:* #$orderId
💵 *राइडर कमाई:* ₹40 फिक्स

🟢 *1. पिकअप (यहाँ से माल उठाएं):*
• दुकान: $shopName
• पता: $pickupAddr

🔴 *2. ड्रॉप (यहाँ माल पहुँचाएं - Max 5 KM):*
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
                    "अपने डिलीवरी पार्टनर को यहाँ जोड़ें (डेटा लोकल सेव रहेगा):",
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
                    decoration: const InputDecoration(labelText: "मोबाइल नंबर (WhatsApp के लिए)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    validator: (value) => value!.length < 10 ? 'सही मोबाइल नंबर दर्ज करें' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(labelText: "गाड़ी/बाइक का नंबर (जैसे DL01AB1234)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_bike)),
                    validator: (value) => value!.isEmpty ? 'गाड़ी का नंबर दर्ज करना अनिवार्य है' : null,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoadingOrder = true);
              _fetchAssignedOrder();
            },
          )
        ],
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
                            "🚨 नया डिलीवरी आर्डर (5 KM एरिया)! उठाइए:",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatTime(_secondsElapsed),
                            style: const TextStyle(color: Colors.yellowAccent, fontSize: 45, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("💰 राइडर कमाई: ₹40 फिक्स", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                Text("📍 दायरा: < 5 KM", style: TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
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
                                    const Text("🟢 1. यहाँ से माल उठाना है (Pickup):",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                    Text(_currentOrder['pickupAddress'] ?? _currentOrder['address'] ?? 'Faridabad',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    const SizedBox(height: 15),
                                    const Text("🔴 2. यहाँ माल छोड़ना है (Delivery Address - 5 KM):",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                    Text(_currentOrder['deliveryAddress'] ?? _currentOrder['address'] ?? 'Faridabad Sector 15A',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 10),
                                    Text("👤 ग्राहक नाम: ${_currentOrder['customerName'] ?? 'Tarun Kumar'}", style: const TextStyle(color: Colors.black87)),
                                    Text("📞 फोन नंबर: ${_currentOrder['customerPhone'] ?? _currentOrder['phone'] ?? '9971968060'}", style: const TextStyle(color: Colors.black87)),
                                    const SizedBox(height: 10),
                                    Text("🛍️ कुल बिल राशि: ₹${_currentOrder['totalAmount'] ?? _currentOrder['total'] ?? '200'}", style: const TextStyle(color: Colors.black87)),
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
                            Text(
                              "रजिस्टर्ड नंबर: $_activeRiderPhone\nफिक्स कमाई: ₹40 प्रति डिलीवरी (5 KM एरिया)\nफिलहाल कोई नया आर्डर नहीं है, वेंडर द्वारा भेजते ही दिखाई देगा।",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }
}
