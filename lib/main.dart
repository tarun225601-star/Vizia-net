import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const ViziaNetworkApp());
}

class ViziaNetworkApp extends StatelessWidget {
  const ViziaNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia Net Hub',
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
  int walletBalance = 190;
  bool isWorkerMode = false;
  
  bool isSearching = false;
  List<Map<String, String>> searchResults = [];
  
  String? activeDownloadingMovie;
  double downloadProgress = 0.0;
  String downloadStatusText = "";

  void toggleWorkerMode(bool value) {
    setState(() {
      isWorkerMode = value;
    });

    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker Node Active: Ready to share data')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker Node Stopped')),
      );
    }
  }

  void performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    Timer(const Duration(milliseconds: 300), () {
      setState(() {
        isSearching = false;
        searchResults = [
          {
            'title': '$query - HD Peer Mesh', 
            'genre': 'P2P Decentralized', 
            'size': '1.5 GB',
            'image': 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=150'
          },
        ];
      });
    });
  }

  // --- SAFE DIRECT P2P SIMULATION (No Socket/Manifest Needed) ---
  void startPeerDownload(String movieName) {
    if (activeDownloadingMovie != null) return;

    if (!isWorkerMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Turn on Worker Mode first!')),
      );
      return;
    }

    setState(() {
      activeDownloadingMovie = movieName;
      downloadStatusText = "Connecting to Peer Mesh...";
    });

    // Simulating secure peer-to-peer data synchronization stream
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          downloadStatusText = "Saved Successfully!";
          walletBalance -= 10;
        });

        Timer(const Duration(seconds: 15), () {
          if (mounted) {
            setState(() {
              activeDownloadingMovie = null;
            });
          }
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search media...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: performSearch,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isWorkerMode ? Colors.green.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isWorkerMode ? Colors.greenAccent : Colors.blueAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isWorkerMode ? 'Worker Node: ACTIVE (Mesh Ready)' : 'Worker Node: OFF',
                    style: TextStyle(fontSize: 12, color: isWorkerMode ? Colors.greenAccent : Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                  Icon(isWorkerMode ? Icons.cell_tower : Icons.wifi_off, color: isWorkerMode ? Colors.greenAccent : Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : searchResults.isNotEmpty
                      ? ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final item = searchResults[index];
                            final title = item['title']!;
                            final isDownloading = activeDownloadingMovie == title;

                            return Card(
                              color: Colors.white10,
                              child: ListTile(
                                title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text(isDownloading ? downloadStatusText : '${item['genre']} | ${item['size']}', style: const TextStyle(fontSize: 11)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                  onPressed: activeDownloadingMovie != null ? null : () => startPeerDownload(title),
                                  child: Text(isDownloading ? 'Syncing...' : 'Download', style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(child: Text('Search to view P2P media nodes', style: TextStyle(color: Colors.white54))),
            ),
            Card(
              color: Colors.white10,
              child: SwitchListTile(
                dense: true,
                title: const Text('Worker Mode Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                value: isWorkerMode,
                activeColor: Colors.greenAccent,
                onChanged: toggleWorkerMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
