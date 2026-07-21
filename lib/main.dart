import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const ViziaNetworkApp());

class ViziaNetworkApp extends StatelessWidget {
  const ViziaNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia Net',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.blueAccent,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int walletBalance = 100;
  bool isWorkerMode = false;
  double progressValue = 0.0;
  bool isDownloading = false;
  
  // Backend Node States
  String nodeStatus = "Node Offline";
  int activePeers = 0;
  Timer? _nodeTimer;

  @override
  void dispose() {
    _nodeTimer?.cancel();
    super.dispose();
  }

  // Back-end Logic: Toggle Node Connection & Bridge Service
  void toggleWorkerMode(bool value) {
    setState(() {
      isWorkerMode = value;
      if (isWorkerMode) {
        nodeStatus = "Connecting to Bridge Node...";
      } else {
        nodeStatus = "Node Offline";
        activePeers = 0;
        _nodeTimer?.cancel();
      }
    });

    if (value) {
      // Simulate backend handshake with decentralized network
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && isWorkerMode) {
          setState(() {
            nodeStatus = "Active Bridge Node (Relaying)";
            activePeers = 4; // Connected peers
          });
          // Start background earnings/node health ping simulation
          _startNodeHeartbeat();
        }
      });
    }
  }

  // Background Node Heartbeat & Commission Logic
  void _startNodeHeartbeat() {
    _nodeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!isWorkerMode) {
        timer.cancel();
        return;
      }
      setState(() {
        walletBalance += 1; // Earn ₹1 per stable node cycle sharing bandwidth
        activePeers = 4 + (DateTime.now().second % 3); // Fluctuating active peers
      });
    });
  }

  void startDownload(String query) {
    if (query.isEmpty) return;
    
    setState(() {
      isDownloading = true;
      progressValue = 0.0;
      if (walletBalance >= 4) {
        walletBalance -= 4; // Deduction per high-speed stream request
      }
    });

    // Simulated chunk-based stream download backend logic
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() { progressValue = 0.35; });
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() { progressValue = 0.75; });
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          progressValue = 1.0;
          isDownloading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Net Hub'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '₹$walletBalance',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Connected to Backend Stream
            TextField(
              decoration: InputDecoration(
                hintText: 'Search 4K / HD Content...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => startDownload(value),
            ),
            const SizedBox(height: 20),

            // Live Node Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWorkerMode ? Colors.blue.withOpacity(0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isWorkerMode ? Colors.blueAccent : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nodeStatus, style: TextStyle(fontWeight: FontWeight.bold, color: isWorkerMode ? Colors.blueAccent : Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Active Peers: $activePeers', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                  Icon(Icons.hub, color: isWorkerMode ? Colors.blueAccent : Colors.white54),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Circular Progress Indicator Section
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isDownloading ? 'Relaying & Streaming... ${(progressValue * 100).toInt()}%' : 'Ready for Instant High-Speed Stream',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Worker Mode Toggle Card with Backend Logic
            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('Worker Mode (Wi-Fi Bridge Node)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Turn device into active node to earn commissions'),
                value: isWorkerMode,
                activeColor: Colors.blueAccent,
                onChanged: toggleWorkerMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
