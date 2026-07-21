import 'package:flutter/material.dart';

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

  void startDownload() {
    setState(() {
      isDownloading = true;
      progressValue = 0.0;
      if (walletBalance >= 4) {
        walletBalance -= 4;
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() { progressValue = 0.3; });
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() { progressValue = 0.7; });
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        progressValue = 1.0;
        isDownloading = false;
      });
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
              onSubmitted: (value) => startDownload(),
            ),
            const SizedBox(height: 30),
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
                      isDownloading ? 'Downloading & Streaming... ${(progressValue * 100).toInt()}%' : 'Ready for Instant High-Speed Stream',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('Worker Mode (Wi-Fi Bridge Node)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Turn device into active node to earn commissions'),
                value: isWorkerMode,
                activeColor: Colors.blueAccent,
                onChanged: (bool value) {
                  setState(() {
                    isWorkerMode = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
