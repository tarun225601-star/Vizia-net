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
  int walletBalance = 170;
  bool isWorkerMode = true;
  
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> allVideos = [
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
    {
      'title': 'Comedy Nights Special Live',
      'channel': 'Vizia Creator Studio',
      'views': '89K views • 5 hours ago',
      'size': '950 MB',
      'thumbnail': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
    },
  ];

  List<Map<String, dynamic>> displayedVideos = [];
  final List<Map<String, dynamic>> downloadedLibrary = [];
  final Map<String, double> downloadProgressMap = {};

  @override
  void initState() {
    super.initState();
    displayedVideos = List.from(allVideos);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedVideos = List.from(allVideos);
      } else {
        displayedVideos = allVideos
            .where((v) => v['title'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void toggleWorkerMode(bool value) {
    setState(() {
      isWorkerMode = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'Worker Node: ACTIVE (Mesh Ready)' : 'Worker Node: OFF')),
    );
  }

  void startDownload(Map<String, dynamic> video) {
    final title = video['title'] as String;

    if (downloadedLibrary.any((v) => v['title'] == title)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already downloaded in your Offline Library!')),
      );
      return;
    }

    if (!isWorkerMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Turn on Worker Node first!')),
      );
      return;
    }

    setState(() {
      downloadProgressMap[title] = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        double currentProgress = downloadProgressMap[title] ?? 0.0;
        if (currentProgress < 1.0) {
          currentProgress += 0.2;
          downloadProgressMap[title] = currentProgress;
        } else {
          timer.cancel();
          downloadProgressMap.remove(title);
          downloadedLibrary.add(video);
          walletBalance -= 10;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully downloaded "$title" to Offline Library!')),
          );
        }
      });
    });
  }

  void openMoviePlayer(Map<String, dynamic> video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviePlayerScreen(
          videoTitle: video['title'] as String,
          thumbnail: video['thumbnail'] as String,
        ),
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
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: searchController,
            onChanged: filterSearch,
            decoration: InputDecoration(
              hintText: 'Search movies, shows...',
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        const SizedBox(height: 8),
        Expanded(
          child: displayedVideos.isNotEmpty
              ? ListView.builder(
                  itemCount: displayedVideos.length,
                  itemBuilder: (context, index) {
                    final video = displayedVideos[index];
                    final title = video['title'] as String;
                    final isDownloaded = downloadedLibrary.any((v) => v['title'] == title);
                    final bool isDownloading = downloadProgressMap.containsKey(title);
                    final double progress = downloadProgressMap[title] ?? 0.0;

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
                                Image.network(video['thumbnail'] as String, fit: BoxFit.cover),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: Colors.black87,
                                    child: Text(video['size'] as String, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  ),
                                ),
                                if (isDownloading)
                                  Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(value: progress, color: Colors.redAccent),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Downloading... ${(progress * 100).toInt()}%',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      ),
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
                                isDownloaded
                                    ? IconButton(
                                        icon: const Icon(Icons.play_circle_filled, color: Colors.greenAccent, size: 32),
                                        onPressed: () => openMoviePlayer(video),
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          isDownloading ? Icons.hourglass_top : Icons.download,
                                          color: Colors.white,
                                        ),
                                        onPressed: isDownloading ? null : () => startDownload(video),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text('No videos found matching your search.', style: TextStyle(color: Colors.white54)),
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
                              child: Image.network(item['thumbnail'] as String, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  const Text('Downloaded • Ready to watch', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 36),
                              onPressed: () => openMoviePlayer(item),
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

class MoviePlayerScreen extends StatelessWidget {
  final String videoTitle;
  final String thumbnail;

  const MoviePlayerScreen({super.key, required this.videoTitle, required this.thumbnail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(videoTitle, style: const TextStyle(fontSize: 14)),
      ),
      body: Column(
        children: [
          Container(
            height: 230,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(thumbnail, fit: BoxFit.cover),
                Container(color: Colors.black45),
                const Center(
                  child: Icon(Icons.play_circle_filled, size: 72, color: Colors.redAccent),
                ),
                const Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Icon(Icons.hd, color: Colors.greenAccent),
                      SizedBox(width: 6),
                      Text('OFFLINE VAULT STREAM', style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                LinearProgressIndicator(value: 0.35, color: Colors.redAccent, backgroundColor: Colors.white24),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('01:15', style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text('02:30:00', style: TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.replay_10, size: 32, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.pause_circle_filled, size: 54, color: Colors.redAccent), onPressed: () {}),
                IconButton(icon: const Icon(Icons.forward_10, size: 32, color: Colors.white), onPressed: () {}),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Now playing "$videoTitle" securely from your local device storage.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
