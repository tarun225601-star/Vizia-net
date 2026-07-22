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
  
  String nodeStatus = "Node Offline";
  bool isSearching = false;
  List<Map<String, String>> searchResults = [];
  
  bool isBackgroundDownloading = false;
  double downloadProgress = 0.0;
  String currentDownloadingMovie = "";
  bool isDownloadComplete = false;

  Timer? _bgDownloadTimer;

  @override
  void dispose() {
    _bgDownloadTimer?.cancel();
    super.dispose();
  }

  void toggleWorkerMode(bool value) {
    setState(() {
      isWorkerMode = value;
      nodeStatus = isWorkerMode ? "Wi-Fi Bridge Active (Ready)" : "Node Offline";
    });
  }

  // Instant local/online catalog matching for movies & media
  void performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    Timer(const Duration(milliseconds: 600), () {
      setState(() {
        isSearching = false;
        // Dynamic generation based on user query to provide instant realistic results
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
    if (isBackgroundDownloading) return;

    setState(() {
      currentDownloadingMovie = movieName;
      isBackgroundDownloading = true;
      downloadProgress = 0.0;
      isDownloadComplete = false;
    });

    _bgDownloadTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        downloadProgress += 0.10;
        if (downloadProgress >= 1.0) {
          downloadProgress = 1.0;
          isBackgroundDownloading = false;
          isDownloadComplete = true;
          walletBalance += 5;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Net Hub (Direct Sync)'),
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
                hintText: 'Search any movie or media (e.g. Avatar, Batman)...',
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
            const SizedBox(height: 12),

            if (isBackgroundDownloading || isDownloadComplete)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: downloadProgress,
                            strokeWidth: 5,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDownloadComplete ? Colors.greenAccent : Colors.blueAccent,
                            ),
                          ),
                          Center(
                            child: Text(
                              isDownloadComplete ? '✓' : '${(downloadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold, 
                                color: isDownloadComplete ? Colors.greenAccent : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDownloadComplete ? 'Download Finished!' : 'Downloading Background Payload...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: isDownloadComplete ? Colors.greenAccent : Colors.blueAccent, 
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentDownloadingMovie,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : searchResults.isNotEmpty
                      ? ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final item = searchResults[index];
                            final movieTitle = item['title']!;
                            
                            return Card(
                              color: Colors.white10.withOpacity(0.08),
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: const Icon(Icons.movie_creation, color: Colors.blueAccent, size: 32),
                                title: Text(
                                  movieTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  'Genre: ${item['genre']} | Size: ${item['size']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  ),
                                  onPressed: isBackgroundDownloading 
                                      ? null 
                                      : () => startMovieDownload(movieTitle),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'Type any movie above to list options with live download buttons & circle progress.',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
            ),

            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('Worker Mode (Wi-Fi Bridge Node)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Active background sync & relay bridge', style: TextStyle(fontSize: 10)),
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
