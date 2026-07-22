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
  bool isWorkerMode = true;
  
  bool isSearching = false;
  List<Map<String, String>> searchResults = [];
  
  // Track which specific movie is downloading and its progress (0.0 to 1.0)
  String? activeDownloadingMovie;
  double downloadProgress = 0.0;
  Timer? _bgDownloadTimer;

  @override
  void dispose() {
    _bgDownloadTimer?.cancel();
    super.dispose();
  }

  void toggleWorkerMode(bool value) {
    setState(() {
      isWorkerMode = value;
    });
  }

  void performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    Timer(const Duration(milliseconds: 400), () {
      setState(() {
        isSearching = false;
        searchResults = [
          {'title': '$query - Director\'s Cut HD', 'genre': 'Sci-Fi / Action', 'size': '1.8 GB'},
          {'title': '$query (Remastered 4K Ultra)', 'genre': 'Blockbuster', 'size': '3.2 GB'},
          {'title': '$query - Behind The Scenes', 'genre': 'Documentary', 'size': '750 MB'},
          {'title': '$query (Extended Edition)', 'genre': 'Drama / Thriller', 'size': '2.4 GB'},
        ];
      });
    });
  }

  void startMovieDownload(String movieName) {
    if (activeDownloadingMovie != null) return; // Only one download at a time

    setState(() {
      activeDownloadingMovie = movieName;
      downloadProgress = 0.0;
    });

    _bgDownloadTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      setState(() {
        downloadProgress += 0.15;
        if (downloadProgress >= 1.0) {
          downloadProgress = 1.0;
          walletBalance += 5; // Reward added
          timer.cancel();
          // Keep completed state briefly or reset
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                activeDownloadingMovie = null;
                downloadProgress = 0.0;
              });
            }
          });
        }
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
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search movie or media (e.g. Avatar)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => performSearch(value),
            ),
            const SizedBox(height: 10),

            // Node Status Card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Active Bridge Node (Relaying)\nActive Peers: 6', style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  Icon(Icons.hub, color: Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Results List with YouTube-style inline download loaders
            Expanded(
              child: isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : searchResults.isNotEmpty
                      ? ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final item = searchResults[index];
                            final movieTitle = item['title']!;
                            final isThisDownloading = activeDownloadingMovie == movieTitle;
                            final isCompleted = isThisDownloading && downloadProgress >= 1.0;

                            return Card(
                              color: Colors.white10,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.movie_creation, color: Colors.blueAccent),
                                title: Text(movieTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text('Genre: ${item['genre']} | ${item['size']}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                trailing: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCompleted ? Colors.green : Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    ),
                                    onPressed: activeDownloadingMovie != null 
                                        ? null 
                                        : () => startMovieDownload(movieTitle),
                                    child: isThisDownloading
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  value: isCompleted ? null : downloadProgress,
                                                  strokeWidth: 2,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isCompleted ? 'Done' : '${(downloadProgress * 100).toInt()}%',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            ],
                                          )
                                        : const Text('Download', style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.movie_filter, size: 48, color: Colors.white24),
                              SizedBox(height: 8),
                              Text(
                                'Type any name in search above and press enter\nto list media files.',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),

            const SizedBox(height: 10),

            // Worker Mode Toggle Card at Bottom
            Card(
              color: Colors.white10,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: SwitchListTile(
                dense: true,
                title: const Text('Worker Mode (Wi-Fi Bridge)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: const Text('Turn device into active node to earn', style: TextStyle(fontSize: 9, color: Colors.white54)),
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
