import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const ViziaNetworkApp());

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
  void initState() {
    super.initState();
    _requestStoragePermissions();
  }

  @override
  void dispose() {
    _stopWorkerServer();
    super.dispose();
  }

  Future<void> _requestStoragePermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  // --- WORKER NODE BACKGROUND SERVER ---
  Future<void> _startWorkerServer() async {
    try {
      _workerServer = await HttpServer.bind(InternetAddress.anyIPv4, workerPort);
      _workerServer!.listen((HttpRequest request) async {
        if (request.uri.path == '/request_chunk') {
          final movieName = request.uri.queryParameters['movie'] ?? 'Media';
          request.response.headers.contentType = ContentType.binary;
          request.response.statusCode = HttpStatus.ok;

          for (int i = 1; i <= 15; i++) {
            await Future.delayed(const Duration(milliseconds: 150));
            request.response.add(utf8.encode('P2P Data Block $i for $movieName\n'));
          }
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });
    } catch (e) {
      debugPrint('Worker Server Error: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker Mode Activated: Ready to relay via local network')),
      );
    } else {
      await _stopWorkerServer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker Mode Deactivated')),
      );
    }
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
          {
            'title': '$query - Local Mesh HD', 
            'genre': 'Direct P2P Stream', 
            'size': '2.4 GB',
            'peerUrl': 'http://127.0.0.1:$workerPort/request_chunk?movie=$query',
            'image': 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=150'
          },
          {
            'title': '$query (Remastered 4K)', 
            'genre': 'Cluster Node 02', 
            'size': '4.1 GB',
            'peerUrl': 'http://127.0.0.1:$workerPort/request_chunk?movie=$query',
            'image': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=150'
          },
        ];
      });
    });
  }

  // --- STRICT LOCAL PEER DOWNLOAD & PERMANENT STORAGE ---
  Future<void> startPeerDownload(String movieName, String peerUrl) async {
    if (activeDownloadingMovie != null) return;

    setState(() {
      activeDownloadingMovie = movieName;
      downloadProgress = 0.0;
      downloadStatusText = "Connecting to Worker Node...";
    });

    try {
      final uri = Uri.parse(peerUrl);
      final streamedResponse = await http.get(uri).timeout(const Duration(seconds: 4));

      if (streamedResponse.statusCode == 200) {
        setState(() {
          downloadStatusText = "Receiving from Worker...";
        });

        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final filePath = '${directory?.path}/$movieName.mp4';
        final file = File(filePath);
        
        // Write bytes directly
        await file.writeAsBytes(streamedResponse.bodyBytes);

        setState(() {
          downloadProgress = 1.0;
          downloadStatusText = "Saved Permanently in Downloads!";
          walletBalance -= 10; 
        });

        Future.delayed(const Duration(seconds: 2), () {
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
          downloadStatusText = "Worker Node Offline";
        });
      }
    } catch (e) {
      setState(() {
        activeDownloadingMovie = null;
        downloadStatusText = "No Worker Found on Wi-Fi";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Turn on Worker Mode first! ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Net Hub (P2P Final)'),
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
                hintText: 'Search media index...',
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
                    isWorkerMode 
                        ? 'Worker Mode: ACTIVE (Port $workerPort)\nReady to serve local peer requests.' 
                        : 'Worker Mode: OFF\nEnable worker mode below to bridge files.', 
                    style: TextStyle(fontSize: 11, color: isWorkerMode ? Colors.greenAccent : Colors.blueAccent, fontWeight: FontWeight.bold)
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
                            final movieTitle = item['title']!;
                            final posterUrl = item['image']!;
                            final peerUrl = item['peerUrl']!;
                            final isThisDownloading = activeDownloadingMovie == movieTitle;
                            final isCompleted = isThisDownloading && downloadProgress >= 1.0;

                            return Card(
                              color: Colors.white10,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    posterUrl,
                                    width: 45,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie, size: 40, color: Colors.blueAccent),
                                  ),
                                ),
                                title: Text(movieTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text(
                                  isThisDownloading ? downloadStatusText : '${item['genre']} | ${item['size']}', 
                                  style: TextStyle(fontSize: 10, color: isThisDownloading ? Colors.greenAccent : Colors.white54)
                                ),
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
                                        : () => startPeerDownload(movieTitle, peerUrl),
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
                              Icon(Icons.hub, size: 48, color: Colors.white24),
                              SizedBox(height: 8),
                              Text(
                                'Search media above.\nFiles will download via local worker node to device storage.',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),

            const SizedBox(height: 10),

            Card(
              color: Colors.white10,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: SwitchListTile(
                dense: true,
                title: const Text('Worker Mode (Local P2P Node)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: const Text('Keep active to relay media chunks & earn', style: TextStyle(fontSize: 9, color: Colors.white54)),
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
