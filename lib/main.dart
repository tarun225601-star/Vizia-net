import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ViziagMartDriverApp());
}

// ==========================================
// 🗄️ DATABASE & GLOBAL STATE MANAGER
// ==========================================
class ViziagDatabase {
  // अपनी Firebase Realtime Database की बेस URL यहाँ डालें
  static String firebaseRestUrl = 'https://viziag-mart-default-rtdb.firebaseio.com';
  
  static Map<String, dynamic> tempoDriverProfile = {
    'driverName': 'Ramesh Kumar (Tempo Driver)',
    'vehicleNumber': 'HR-51-AB-1234',
    'latitude': 28.4089,
    'longitude': 77.3178,
  };

  static List<Map<String, dynamic>> fetchedCustomerOrders = [];
}

// ==========================================
// 🚀 MAIN APP ENTRY POINT
// ==========================================
class ViziagMartDriverApp extends StatelessWidget {
  const ViziagMartDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart Tempo Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const TempoDriverHome(),
    );
  }
}

// ==========================================
// 📱 HOME SCREEN WITH TABS / DASHBOARD
// ==========================================
class TempoDriverHome extends StatefulWidget {
  const TempoDriverHome({super.key});

  @override
  State<TempoDriverHome> createState() => _TempoDriverHomeState();
}

class _TempoDriverHomeState extends State<TempoDriverHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TempoDriverDashboardView(),
    const MandiDirectoryView(),
    const DriverProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        title: const Text('🚛 Viziag Mart Driver Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('कोई नया नोटिफिकेशन नहीं है')),
              );
            },
          )
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'डैशबोर्ड & GPS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'मंडी डायरेक्टरी',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'प्रोफाइल',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🚚 1. TEMPO DRIVER DASHBOARD (AUTO GPS LIVE SYNC)
// ==========================================
class TempoDriverDashboardView extends StatefulWidget {
  const TempoDriverDashboardView({super.key});

  @override
  State<TempoDriverDashboardView> createState() => _TempoDriverDashboardViewState();
}

class _TempoDriverDashboardViewState extends State<TempoDriverDashboardView> {
  bool _isFetchingOrders = false;
  bool _isAutoGpsRunning = false;
  Timer? _gpsTimer;

  @override
  void dispose() {
    _gpsTimer?.cancel(); // स्क्रीन हटने पर टाइमर बंद करें ताकि मेमोरी लीक न हो
    super.dispose();
  }

  // 📥 फायरबेस से ग्राहकों के सारे आर्डर फेच करना
  Future<void> _fetchCustomerOrdersFromFirebase() async {
    setState(() => _isFetchingOrders = true);
    try {
      final response = await http.get(Uri.parse('${ViziagDatabase.firebaseRestUrl}/orders.json'));
      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> ordersList = [];
        data.forEach((key, value) {
          var order = Map<String, dynamic>.from(value);
          order['orderKey'] = key;
          ordersList.add(order);
        });
        setState(() {
          ViziagDatabase.fetchedCustomerOrders = ordersList.reversed.toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ सभी ग्राहक आर्डर सफलतापूर्वक फेच हो गए!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ अभी कोई नया आर्डर उपलब्ध नहीं है।'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isFetchingOrders = false);
    }
  }

  // 🛰️ सिंगल क्लिक पर जीपीएस लोकेशन फेच करके क्लाउड पर भेजने का कोर फंक्शन
  Future<void> _sendLiveGpsToCloud() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      var gpsPayload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': 'Live Transit Route',
        'updatedAt': DateTime.now().toIso8601String(),
        'driverName': ViziagDatabase.tempoDriverProfile['driverName'],
        'vehicleNumber': ViziagDatabase.tempoDriverProfile['vehicleNumber'],
      };

      await http.put(
        Uri.parse('${ViziagDatabase.firebaseRestUrl}/tempo_location.json'),
        body: json.encode(gpsPayload),
      );

      setState(() {
        ViziagDatabase.tempoDriverProfile['latitude'] = position.latitude;
        ViziagDatabase.tempoDriverProfile['longitude'] = position.longitude;
      });
      
      debugPrint("🛰️ Auto GPS Synced: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("Auto GPS Error: $e");
    }
  }

  // 🔄 ऑटोमैटिक बैकग्राउंड जीपीएस लूप शुरू/बंद करना (हर 15 सेकंड में)
  void _toggleAutoGpsSync() {
    if (_isAutoGpsRunning) {
      _gpsTimer?.cancel();
      setState(() => _isAutoGpsRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🛑 ऑटो जीपीएस लाइव ट्रैकिंग बंद कर दी गई है।'), backgroundColor: Colors.red),
      );
    } else {
      // तुरंत एक बार लोकेशन भेजें
      _sendLiveGpsToCloud();

      // हर 15 सेकंड का टाइमर चालू करें
      _gpsTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _sendLiveGpsToCloud();
      });

      setState(() => _isAutoGpsRunning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚀 ऑटो जीपीएस लाइव ट्रैकिंग शुरू! अब हर 15 सेकंड में लोकेशन अपडेट होगी।'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var orders = ViziagDatabase.fetchedCustomerOrders;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          const Text('🚚 टेम्पो ड्राइवर डैशबोर्ड & ऑटो लाइव जीपीएस', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('बटन दबाएं; ऐप बैकग्राउंड में हर 15 सेकंड में आपकी लाइव लोकेशन खरीदार को भेजती रहेगी।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),

          // 🛰️ बड़ा वाला ऑटो जीपीएस लाइव सिंक बटन (Big Toggle Button)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAutoGpsRunning ? Colors.red.shade700 : Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _toggleAutoGpsSync,
              icon: Icon(_isAutoGpsRunning ? Icons.stop_circle : Icons.gps_fixed, size: 28),
              label: Text(
                _isAutoGpsRunning ? '🛑 Stop Auto GPS Live Sync' : '🛰️ Start Auto GPS Live Sync (15s)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // स्टेटस इंडिकेटर बॉक्स
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isAutoGpsRunning ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isAutoGpsRunning ? Colors.green : Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 12, color: _isAutoGpsRunning ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _isAutoGpsRunning ? 'Status: Live Sync Active (हर 15s में अपडेट हो रहा है)' : 'Status: GPS Sync Paused',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isAutoGpsRunning ? Colors.green.shade800 : Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 📥 Fetch Orders Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
              onPressed: _isFetchingOrders ? null : _fetchCustomerOrdersFromFirebase,
              icon: const Icon(Icons.download_done),
              label: Text(_isFetchingOrders ? 'Fetching Orders...' : '📥 Fetch All Customer Orders from Firebase 🚀', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 15),

          const Text('📦 फेच किए गए ग्राहकों के ऑर्डर्स (Active Orders List):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          orders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('कोई आर्डर फेच नहीं हुआ है। ऊपर दिए गए बटन पर क्लिक करें।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('👤 ${order['customerName'] ?? 'ग्राहक'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('📞 ${order['customerPhone'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('📍 पता: ${order['customerAddress'] ?? 'उपलब्ध नहीं'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 6),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Text('🛒 कुल राशि: ₹${order['grandTotal'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ==========================================
// 🥬 2. MANDI DIRECTORY VIEW
// ==========================================
class MandiDirectoryView extends StatelessWidget {
  const MandiDirectoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mandis = [
      {'name': 'अज़ाबाद सब्जी मंडी (Main Hub)', 'timing': '04:00 AM - 11:00 AM', 'contact': '9876543210'},
      {'name': 'ओखला होलसेल मंडी', 'timing': '03:00 AM - 10:00 AM', 'contact': '9811122233'},
      {'name': 'गाजीपुर फ्रूट एंड वेजिटेबल मंडी', 'timing': '02:00 AM - 12:00 PM', 'contact': '9955443322'},
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('🌾 अधिकृत मंडी डायरेक्टरी (Mandis List)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('यहाँ से आप विभिन्न मंडियों के संपर्क और खुलने के समय देख सकते हैं।', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        ...mandis.map((mandi) => Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.store, color: Colors.white)),
            title: Text(mandi['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('समय: ${mandi['timing']}\nसंपर्क: ${mandi['contact']}', style: const TextStyle(fontSize: 11)),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        )),
      ],
    );
  }
}

// ==========================================
// 👤 3. DRIVER PROFILE VIEW
// ==========================================
class DriverProfileView extends StatelessWidget {
  const DriverProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    var profile = ViziagDatabase.tempoDriverProfile;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(profile['driverName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text('वाहन नंबर: ${profile['vehicleNumber']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 25),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.green),
              title: const Text('व्हीकल स्टेटस'),
              subtitle: const Text('Verified & Active for Live Tracking'),
              trailing: Chip(
                label: const Text('Online', style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.green.shade700,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('लॉग आउट सफल रहा')),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('लॉग आउट (Logout)'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
