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

  // Firebase REST API के जरिए राइडर रजिस्टर करने का फंक्शन
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
          'isReady': true, // रजिस्टर होते ही राइडर फ्री/रेडी माना जाएगा
        };

        // REST API के जरिए डेटा भेजना
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
      appBar: AppBar(
        title: const Text("राइडर रजिस्ट्रेशन (Viziag Mart)"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "अपने डिलीवरी पार्टनर (दोस्त) को यहाँ जोड़ें:",
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

      // 1. ऑर्डर को अपडेट करें
      await http.patch(
        Uri.parse('${CakeDatabase.firebaseRestUrl}/orders/$orderKey.json'),
        body: json.encode({
          'riderPhone': riderPhone,
          'vehicleNumber': vehicleNo,
          'orderStatus': 'Out for Delivery',
        }),
      );

      // 2. राइडर को व्यस्त (isReady: false) करें
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


// 📱 3. राइडर का डैशबोर्ड और अलर्ट स्क्रीन (सेफ डेटा और फिक्सड UI के साथ)
class RiderDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  final String riderPhone;

  const RiderDeliveryScreen({
    Key? key, 
    this.orderDetails = const {}, 
    this.riderPhone = '9971968060'
  }) : super(key: key);

  @override
  _RiderDeliveryScreenState createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    // अगर आर्डर मौजूद है तभी टाइमर और वाइब्रेशन चालू करें
    if (widget.orderDetails.isNotEmpty) {
      _startAlertAndTimer();
    }
  }

  void _startAlertAndTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });

    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remSec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remSec.toString().padLeft(2, '0')}';
  }

  Future<void> _sendDetailsToWhatsApp() async {
    String shopName = widget.orderDetails['shopName'] ?? CakeDatabase.bakeryShop['shopName'] ?? 'Viziag Mart';
    String pickupAddr = widget.orderDetails['pickupAddress'] ?? CakeDatabase.bakeryShop['address'] ?? 'Faridabad';
    String customerName = widget.orderDetails['customerName'] ?? 'कस्टमर';
    String customerPhone = widget.orderDetails['customerPhone'] ?? '';
    String deliveryAddr = widget.orderDetails['deliveryAddress'] ?? 'पता उपलब्ध नहीं';
    String orderId = widget.orderDetails['orderId'] ?? '101';
    String totalAmount = widget.orderDetails['totalAmount']?.toString() ?? '0';

    String message = '''
🚨 *नया डिलीवरी आर्डर मिला है!* 🚨

📦 *ऑर्डर आईडी:* #$orderId
💰 *कुल राशि:* ₹$totalAmount

🟢 *1. यहाँ से सामान उठाना है (Pickup):*
• दुकान: $shopName
• पता: $pickupAddr

🔴 *2. यहाँ सामान पहुँचाना है (Delivery):*
• ग्राहक: $customerName
• फोन: $customerPhone
• पता: $deliveryAddr

समय पर डिलीवरी पूरी करें! 🚀
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
    bool hasOrder = widget.orderDetails.isNotEmpty;

    return Scaffold(
      backgroundColor: hasOrder ? Colors.red[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text("राइडर डैशबोर्ड", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: hasOrder
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "🚨 नया आर्डर आया हुआ है:",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatTime(_secondsElapsed),
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📦 आर्डर ID: #${widget.orderDetails['orderId'] ?? 'N/A'}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Divider(thickness: 2),
                            const SizedBox(height: 10),
                            const Text("🟢 पिकअप एड्रेस (दुकान):",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                            Text(widget.orderDetails['pickupAddress'] ?? CakeDatabase.bakeryShop['address'] ?? 'Faridabad',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 15),
                            const Text("🔴 डिलीवरी एड्रेस (ग्राहक):",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                            Text(widget.orderDetails['deliveryAddress'] ?? 'पता नहीं मिला',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("👤 ग्राहक नाम: ${widget.orderDetails['customerName'] ?? 'Tarun Kumar'}"),
                            Text("📞 फोन नंबर: ${widget.orderDetails['customerPhone'] ?? '9971968060'}"),
                            const SizedBox(height: 10),
                            Text("💰 कुल राशि: ₹${widget.orderDetails['totalAmount'] ?? '0'}"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _vibrationTimer?.cancel();
                      _timer?.cancel();
                      _sendDetailsToWhatsApp();
                    },
                    child: const Text(
                      "आर्डर स्वीकार करें & WhatsApp पर भेजें",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 10),
                    const Text(
                      "फिलहाल कोई नया आर्डर नहीं है।\nवेंडर द्वारा आर्डर 'Dispatch' होने पर यहीं दिखाई देगा।",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
