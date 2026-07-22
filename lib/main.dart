import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const ViziaTubeApp());
}

class ViziaTubeApp extends StatelessWidget {
  const ViziaTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia Tube',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.redAccent,
      ),
      home: const YouTubeHomeScreen(),
    );
  }
}

class YouTubeHomeScreen extends StatefulWidget {
  const YouTubeHomeScreen({super.key});

  @override
  State<YouTubeHomeScreen> createState() => _YouTubeHomeScreenState();
}

class _YouTubeHomeScreenState extends State<YouTubeHomeScreen> {
  int _selectedIndex = 0;
  int walletBalance = 190;
  bool isWorkerMode = false;
  
  List<Map<String, String>> videoFeed = [
    {
      'title': 'Mela Movie - HD Local Peer Remastered',
      'channel': 'Vizia P2P Network',
      'views': '125K views • 2 days ago',
      'size': '1.5 GB',
      'thumbnail': 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500',
    },
    {
      'title': 'Action Blast Blockbuster 2026',
      'channel': 'Mesh Media Hub',
      'views': '450K views • 1 week ago',
      'size': '2.1 GB',
      'thumbnail': 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=500',
    },
  ];

  final List<Map<String, String>> downloadedLibrary = [];

  String? activeDownloadingTitle;

  void toggleWorkerMode(bool value) {
    setState(() {
      isWorkerMode = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'Worker Node: ACTIVE (P2P Mesh Ready)' : 'Worker Node: OFF')),
    );
  }

  void downloadVideo(Map<String, String> video) {
    final title = video['title']!;
    
    if (downloadedLibrary.any((v) => v['title'] == title)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already downloaded in your Offline Library!')),
      );
      return;
    }

    if (!isWorkerMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Turn on Worker Mode first!')),
      );
      return;
    }

    setState(() {
      activeDownloadingTitle = title;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          downloadedLibrary.add(video);
          walletBalance -= 10;
          activeDownloadingTitle = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded "$title" to Offline Library')),
        );
      }
    });
  }

  void playVideoPlayer(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_circle_filled, size: 64, color: Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('Playing smoothly from your local App Vault', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 4),
            Text('ViziaTube', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₹$walletBalance',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
            ),
          )
        ],
      ),
      body: _selectedIndex == 0 ? buildHomeFeed() : buildLibraryScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Library'),
        ],
      ),
    );
  }

  Widget buildHomeFeed() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isWorkerMode ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isWorkerMode ? Colors.greenAccent : Colors.redAccent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isWorkerMode ? 'Worker Node: ACTIVE (Mesh Ready)' : 'Worker Node: OFF',
                style: TextStyle(fontSize: 11, color: isWorkerMode ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: isWorkerMode,
                  activeColor: Colors.greenAccent,
                  onChanged: toggleWorkerMode,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: videoFeed.length,
            itemBuilder: (context, index) {
              final video = videoFeed[index];
              final title = video['title']!;
              final isDownloading = activeDownloadingTitle == title;
              final isDownloaded = downloadedLibrary.any((v) => v['title'] == title);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 190,
                      width: double.infinity,
                      color: Colors.white10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(video['thumbnail']!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              color: Colors.black87,
                              child: Text(video['size']!, style: const TextStyle(fontSize: 10, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.person, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('${video['channel']} • ${video['views']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isDownloaded ? Icons.check_circle : (isDownloading ? Icons.hourglass_top : Icons.download),
                              color: isDownloaded ? Colors.greenAccent : Colors.white,
                            ),
                            onPressed: (isDownloaded || isDownloading) ? null : () => downloadVideo(video),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildLibraryScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Downloads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Available offline in your local app vault', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 16),
          Expanded(
            child: downloadedLibrary.isNotEmpty
                ? ListView.builder(
                    itemCount: downloadedLibrary.length,
                    itemBuilder: (context, index) {
                      final item = downloadedLibrary[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 120,
                              height: 70,
                              color: Colors.white10,
                              child: Image.network(item['thumbnail']!, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  const Text('Downloaded • Ready to watch', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 32),
                              onPressed: () => playVideoPlayer(item['title']!),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined, size: 64, color: Colors.white24),
                        SizedBox(height: 10),
                        Text('No downloaded videos yet\nVideos you download will appear here like YouTube.', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
