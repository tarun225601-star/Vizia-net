import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

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

  HttpServer? _workerServer;
  final int workerPort = 8080;

  @override
  void dispose() {
    _stopWorkerServer();
    super.dispose();
  }

  // --- WORKER NODE BACKGROUND SERVER ---
  Future<void> _startWorkerServer() async {
    try {
      if (_workerServer != null) return;
      _workerServer = await HttpServer.bind(InternetAddress.anyIPv4, workerPort);
      _workerServer!.listen((HttpRequest request) async {
        if (request.uri.path == '/request_chunk') {
          final movieName = request.uri.queryParameters['movie'] ?? 'Media';
          request.response.headers.contentType = ContentType.binary;
          request.response.statusCode = HttpStatus.ok;

          for (int i = 1; i <= 10; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            request.response.add(utf8.encode('Data Chunk $i for $movieName\n'));
          }
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });
    } catch (e) {
      debugPrint('Server error: $e');
    }
  }

  Future<void> _stopWorkerServer() async {
    await _workerServer?.close(force: true);
    _workerServer = null;
  }

  void toggleWorkerMode(bool value) async {
    setState(() {
      isWorkerMode = value;
    });

    if (value) {
      await _startWorkerServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker Node Active: Ready to serve peers')),
        );
      }
    } else {
      await _stopWorkerServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker Node Stopped')),
        );
      }
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
            'title': '$query - HD Local Peer', 
            'genre': 'P2P Mesh', 
            'size': '1.5 GB',
            'peerUrl': 'http://127.0.0.1:$workerPort/request_chunk?movie=$query',
            'image': 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=150'
          },
        ];
      });
    });
  }

  // --- NATIVE DOWNLOAD (Directly checks isWorkerMode) ---
  Future<void> startPeerDownload(String movieName, String peerUrl) async {
    if (activeDownloadingMovie != null) return;

    // Fixed check: Ensures download proceeds smoothly when worker mode is active
    if (!isWorkerMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Turn on Worker Mode first!')),
      );
      return;
    }

    setState(() {
      activeDownloadingMovie = movieName;
      downloadProgress = 0.0;
      downloadStatusText = "Connecting to Worker...";
    });

    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(peerUrl));
      final response = await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          downloadStatusText = "Downloading from Worker...";
        });

        final bytes = await consolidateHttpClientResponseBytes(response);

        Directory directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
        } else {
          directory = Directory.current;
        }

        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final file = File('${directory.path}/$movieName.mp4');
        await file.writeAsBytes(bytes);

        setState(() {
          downloadProgress = 1.0;
          downloadStatusText = "Saved in Downloads!";
          walletBalance -= 10;
        });

        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              activeDownloadingMovie = null;
              downloadProgress = 0.0;
            });
          }
        });
      } else {
        setState(() {
          activeDownloadingMovie = null;
          downloadStatusText = "Worker Busy";
        });
      }
    } catch (e) {
      setState(() {
        activeDownloadingMovie = null;
        downloadStatusText = "Worker Offline";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download Error: $e')),
      );
    }
  }

  Future<List<int>> consolidateHttpClientResponseBytes(HttpClientResponse response) {
    final completer = Completer<List<int>>();
    final contents = <int>[];
    response.listen(
      (contents.addAll),
      onDone: () => completer.complete(contents),
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
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
                    isWorkerMode ? 'Worker Node: ACTIVE (Port $workerPort)' : 'Worker Node: OFF',
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
                            final peerUrl = item['peerUrl']!;
                            final isDownloading = activeDownloadingMovie == title;

                            return Card(
                              color: Colors.white10,
                              child: ListTile(
                                title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text(isDownloading ? downloadStatusText : '${item['genre']} | ${item['size']}', style: const TextStyle(fontSize: 11)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                  onPressed: activeDownloadingMovie != null ? null : () => startPeerDownload(title, peerUrl),
                                  child: Text(isDownloading ? 'Downloading...' : 'Download', style: const TextStyle(fontSize: 11)),
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
