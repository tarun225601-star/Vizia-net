import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback (वाइब्रेशन) के लिए
import 'dart:async';
import 'database_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // WhatsApp पर भेजने के लिए

// 🚀 1. राइडर रजिस्ट्रेशन स्क्रीन (जहाँ राइडर अपना नाम, फोन और गाड़ी नंबर दर्ज करेगा)
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

  // Firebase में राइडर रजिस्टर करने का फंक्शन
  Future<void> _registerRider() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String riderId = "rider_${DateTime.now().millisecondsSinceEpoch}";
        
        // Firestore में राइडर का डेटा सेव करना
        await FirebaseFirestore.instance.collection('riders').doc(riderId).set({
          'riderId': riderId,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'vehicleNumber': _vehicleController.text.trim().toUpperCase(),
          'isReady': true, // रजिस्टर होते ही राइडर को फ्री/रेडी मान लिया जाएगा
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 राइडर सफलतापूर्वक रजिस्टर हो गया!")),
        );

        Navigator.pop(context); // रजिस्टर होने के बाद वापस पीछे जाएं
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ एरर: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
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
              
              // राइडर का नाम
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

              // मोबाइल नंबर
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

              // गाड़ी का नंबर (Vehicle Number)
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

              // सबमिट बटन
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


// 🚀 2. वेंडर डैशबोर्ड से 'Dispatch' करने का कोर लॉजिक
class DeliveryDispatcherManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> dispatchOrderToAvailableRider(String orderId, Map<String, dynamic> orderData) async {
    try {
      // डेटाबेस से पहला खाली (isReady: true) राइडर खोजो
      QuerySnapshot availableRiders = await _firestore
          .collection('riders')
          .where('isReady', isEqualTo: true)
          .limit(1)
          .get();

      if (availableRiders.docs.isEmpty) {
        return "NO_RIDER_AVAILABLE"; // अगर सभी राइडर बिजी हैं
      }

      var riderDoc = availableRiders.docs.first;
      String riderId = riderDoc.id;
      String riderPhone = riderDoc['phone'] ?? '';
      String vehicleNo = riderDoc['vehicleNumber'] ?? '';

      // ट्रांजैक्शन के जरिए ऑर्डर असाइन करो और राइडर को बिजी करो
      await _firestore.runTransaction((transaction) async {
        transaction.update(_firestore.collection('orders').doc(orderId), {
          'assignedRiderId': riderId,
          'riderPhone': riderPhone,
          'vehicleNumber': vehicleNo,
          'orderStatus': 'Out for Delivery',
        });

        transaction.update(_firestore.collection('riders').doc(riderId), {
          'isReady': false, // राइडर अब व्यस्त हो गया
        });
      });

      return "SUCCESS:$riderPhone";
    } catch (e) {
      return "ERROR: $e";
    }
  }
}


// 📱 3. राइडर का डैशबोर्ड और अलर्ट स्क्रीन
class RiderDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  final String riderPhone;

  const RiderDeliveryScreen({Key? key, required this.orderDetails, required this.riderPhone}) : super(key: key);

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
    _startAlertAndTimer();
  }

  // टाइमर और लगातार हैप्टिक वाइब्रेशन शुरू करने का लॉजिक
  void _startAlertAndTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });

    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.heavyImpact(); // जोरदार वाइब्रेशन झटका
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

  // व्हाट्सएप पर आर्डर भेजने का फंक्शन
  Future<void> _sendDetailsToWhatsApp() async {
    String shopName = widget.orderDetails['shopName'] ?? CakeDatabase.bakeryShop['shopName'];
    String pickupAddr = widget.orderDetails['pickupAddress'] ?? CakeDatabase.bakeryShop['address'];
    String customerName = widget.orderDetails['customerName'] ?? 'कस्टमर';
    String customerPhone = widget.orderDetails['customerPhone'] ?? '';
    String deliveryAddr = widget.orderDetails['deliveryAddress'] ?? 'पता उपलब्ध नहीं';
    String orderId = widget.orderDetails['orderId'] ?? '101';
    String totalAmount = widget.orderDetails['totalAmount'] ?? '0';

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

    String formattedPhone = widget.riderPhone.startsWith('+') ? widget.riderPhone : '+91${widget.riderPhone}';
    String url = "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900], // अर्जेंट लुक के लिए लाल रंग
      appBar: AppBar(
        title: const Text("🚨 नया आर्डर अलर्ट", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "ऑर्डर आए हुए समय हो गया:",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 10),
            
            // ⏱️ बड़े अक्षरों में चलने वाला टाइमर
            Text(
              _formatTime(_secondsElapsed),
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 60,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 20),

            // 📍 दुकान और ग्राहक का पता फ्लैश करने वाला कार्ड
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
                      Text("📦 आर्डर ID: #${widget.orderDetails['orderId'] ?? '01'}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(thickness: 2),
                      const SizedBox(height: 10),
                      
                      const Text("🟢 पिकअप एड्रेस (दुकान):",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(widget.orderDetails['pickupAddress'] ?? CakeDatabase.bakeryShop['address'],
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),

                      const Text("🔴 डिलीवरी एड्रेस (ग्राहक):",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text(widget.orderDetails['deliveryAddress'] ?? 'डिफ़ॉल्ट पता',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text("👤 ग्राहक नाम: ${widget.orderDetails['customerName'] ?? 'Tarun Kumar'}"),
                      Text("📞 फोन नंबर: ${widget.orderDetails['customerPhone'] ?? '9971968060'}"),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ आर्डर स्वीकार करने और WhatsApp पर भेजने का बटन
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _vibrationTimer?.cancel();
                _timer?.cancel();
                _sendDetailsToWhatsApp(); // WhatsApp पर एड्रेस भेजने का ट्रिगर
                Navigator.pop(context);
              },
              child: const Text(
                "आर्डर स्वीकार करें & WhatsApp पर भेजें",
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
