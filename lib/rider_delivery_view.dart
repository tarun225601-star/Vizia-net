import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback (वाइब्रेशन) के लिए
import 'dart:async';
import 'database_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // WhatsApp पर भेजने के लिए

// 🚀 1. राइडर रजिस्ट्रेशन स्क्रीन (REST API आधारित)
class RiderRegistrationScreen extends StatefulWidget {
  const RiderRegistrationScreen({Key? key}) : super(key: key);

  @override
  _RiderRegistrationScreenState createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerRider() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String riderId = "rider_${DateTime.now().millisecondsSinceEpoch}";
        
        var riderData = {
          'riderId': riderId,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'vehicleNumber': _vehicleController.text.trim().toUpperCase(),
          'isReady': true,
        };

        await http.post(
          Uri.parse('${CakeDatabase.firebaseRestUrl}/riders.json'),
          body: json.encode(riderData),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 राइडर सफलतापूर्वक रजिस्टर हो गया!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ एरर: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("राइडर रजिस्ट्रेशन (Viziag Mart)", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
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
                  decoration: const InputDecoration(
                    labelText: "राइडर का पूरा नाम",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'कृपया नाम दर्ज करें' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "मोबाइल नंबर (WhatsApp के लिए)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) => value!.length < 10 ? 'सही मोबाइल नंबर दर्ज करें' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: "गाड़ी/बाइक का नंबर (जैसे DL01AB1234)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_bike),
                  ),
                  validator: (value) => value!.isEmpty ? 'गाड़ी का नंबर दर्ज करना अनिवार्य है' : null,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    onPressed: _isLoading ? null : _registerRider,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("राइडर रजिस्टर करें", style: TextStyle(fontSize: 18, color: Colors.white)),
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

// 🚀 2. वेंडर डैशबोर्ड से 'Dispatch' करने का REST API लॉजिक
class DeliveryDispatcherManager {
  static Future<String> dispatchOrderToAvailableRider(String orderKey, Map<String, dynamic> orderData) async {
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/riders.json'));
      if (res.statusCode != 200 || res.body == 'null' || res.body.isEmpty) {
        return "NO_RIDER_AVAILABLE";
      }

      Map<String, dynamic> data = json.decode(res.body);
      String? matchedRiderFirebaseKey;
      String riderPhone = '';
      String vehicleNo = '';

      data.forEach((key, val) {
        if (val['isReady'] == true && matchedRiderFirebaseKey == null) {
          matchedRiderFirebaseKey = key;
          riderPhone = val['phone'] ?? '';
          vehicleNo = val['vehicleNumber'] ?? '';
        }
      });

      if (matchedRiderFirebaseKey == null) {
        return "NO_RIDER_AVAILABLE";
      }

      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderKey.json'),
        body: json.encode({
          'riderPhone': riderPhone,
          'vehicleNumber': vehicleNo,
          'orderStatus': 'Out for Delivery',
        }),
      );

      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/riders/$matchedRiderFirebaseKey.json'),
        body: json.encode({'isReady': false}),
      );

      return "SUCCESS:$riderPhone";
    } catch (e) {
      return "ERROR: $e";
    }
  }
}

// 📱 3. राइडर का डैशबोर्ड व्यू (Porter स्टाइल - ₹40 फिक्स, 5KM दायरा और सुरक्षित Null Handling)
class RiderDeliveryScreen extends StatefulWidget {
  final String riderPhone;

  const RiderDeliveryScreen({
    Key? key, 
    this.riderPhone = '9971968060',
  }) : super(key: key);

  @override
  _RiderDeliveryScreenState createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  Map<String, dynamic> _currentOrder = {};
  bool _isLoadingOrder = true;
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _vibrationTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchAssignedOrder();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchAssignedOrder();
    });
  }

  Future<void> _fetchAssignedOrder() async {
    try {
      final res = await http.get(Uri.parse('${CakeDatabase.firebaseRestUrl}/orders.json'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        Map<String, dynamic> orders = json.decode(res.body);
        Map<String, dynamic>? activeOrder;

        orders.forEach((key, val) {
          if (val['orderStatus'] == 'Out for Delivery' && 
              val['riderPhone'].toString().trim() == widget.riderPhone.trim()) {
            activeOrder = val;
            activeOrder!['orderKey'] = key;
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
    String orderId = _currentOrder['orderId'] ?? '101';

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

    String targetPhone = widget.riderPhone.isEmpty ? '9971968060' : widget.riderPhone;
    String formattedPhone = targetPhone.startsWith('+') ? targetPhone : '+91$targetPhone';
    String url = "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasOrder = _currentOrder.isNotEmpty;

    return Scaffold(
      backgroundColor: hasOrder ? Colors.red[900] : Colors.white,
      appBar: AppBar(
        title: const Text("राइडर डैशबोर्ड (Porter स्टाइल)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📦 आर्डर ID: #${_currentOrder['orderId'] ?? 'N/A'}",
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
                                    Text(_currentOrder['deliveryAddress'] ?? _currentOrder['address'] ?? 'पता नहीं मिला',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 10),
                                    Text("👤 ग्राहक नाम: ${_currentOrder['customerName'] ?? 'कस्टमर'}", style: const TextStyle(color: Colors.black87)),
                                    Text("📞 फोन नंबर: ${_currentOrder['customerPhone'] ?? _currentOrder['phone'] ?? ''}", style: const TextStyle(color: Colors.black87)),
                                    const SizedBox(height: 10),
                                    Text("🛍️ कुल बिल राशि: ₹${_currentOrder['totalAmount'] ?? _currentOrder['total'] ?? '0'}", style: const TextStyle(color: Colors.black87)),
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
                            const Text(
                              "स्वागत है, राइडर पार्टनर!",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "फिक्स कमाई: ₹40 प्रति डिलीवरी (5 KM एरिया)\nफिलहाल कोई नया आर्डर नहीं है, वेंडर द्वारा भेजते ही दिखाई देगा।",
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
