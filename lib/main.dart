import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MargtasniApp());
}

class MargtasniApp extends StatelessWidget {
  const MargtasniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margtasni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amberAccent,
        ),
      ),
      home: const MargtasniHomeScreen(),
    );
  }
}

// Global Persistent Feed List
List<Map<String, dynamic>> globalFeedItems = [
  {
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni पर अब रील्स और रियल ऑनलाइन गाने लाइव हैं! 🚀🔥',
    'mediaPath': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
    'songName': 'Radhe Radhe - Live Track',
    'likes': 520,
    'isLiked': false,
    'comments': ['भाई अब बिल्कुल Instagram जैसा मज़ा आ रहा है!'],
    'isLocalFile': false,
  },
];

class MargtasniHomeScreen extends StatefulWidget {
  const MargtasniHomeScreen({super.key});

  @override
  State<MargtasniHomeScreen> createState() => _MargtasniHomeScreenState();
}

class _MargtasniHomeScreenState extends State<MargtasniHomeScreen> {
  int _currentIndex = 0;

  // चारों टैब की लिस्ट (Feed, Reels, Requests, Profile)
  final List<Widget> _screens = [
    const FeedScreen(),
    const ReelsScreen(), // यहाँ रील्स टैब जुड़ गया है!
    const RequestsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Reels'), // रील्स आइकॉन
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// 1. HOME FEED SCREEN
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  void _openComments(Map<String, dynamic> post) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comments', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: post['comments'].length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(post['comments'][index], style: const TextStyle(color: Colors.white, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.amberAccent),
                          onPressed: () {
                            if (commentController.text.isNotEmpty) {
                              setModalState(() {
                                post['comments'].add(commentController.text);
                              });
                              setState(() {});
                              commentController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Margtasni', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amberAccent)),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.amberAccent, size: 28),
            onPressed: () => _pickMediaAndPost(context, setState),
            tooltip: 'Upload Post with Gallery & Music',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: globalFeedItems.length,
        itemBuilder: (context, index) {
          final post = globalFeedItems[index];
          bool isLocal = post['isLocalFile'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(post['username'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  subtitle: Text(post['handle'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Text(post['caption'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                if (post['songName'] != 'No Music Selected')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.audiotrack, size: 12, color: Colors.amberAccent),
                        const SizedBox(width: 4),
                        Text(post['songName'], style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                
                isLocal
                    ? Image.file(File(post['mediaPath']), height: 240, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(post['mediaPath'], height: 240, width: double.infinity, fit: BoxFit.cover),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                          color: post['isLiked'] ? Colors.redAccent : Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            post['isLiked'] = !post['isLiked'];
                            post['isLiked'] ? post['likes']++ : post['likes']--;
                          });
                        },
                      ),
                      Text('${post['likes']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.mode_comment_outlined, color: Colors.white70),
                        onPressed: () => _openComments(post),
                      ),
                      Text('${post['comments'].length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // गैलरी से फाइल और ऑनलाइन म्यूजिक सर्च के साथ पोस्ट क्रिएशन
  Future<void> _pickMediaAndPost(BuildContext context, StateSetter parentSetState) async {
    final ImagePicker picker = ImagePicker();
    final TextEditingController captionController = TextEditingController();
    String selectedSongName = 'No Music Selected';
    XFile? pickedFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Create Permanent Post / Reel', style: TextStyle(color: Colors.amberAccent, fontSize: 15)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                      icon: const Icon(Icons.perm_media, color: Colors.white),
                      label: Text(
                        pickedFile == null ? 'Choose Photo / Video from Gallery' : 'File Selected ✅',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: () async {
                        final XFile? image = await picker.pickMedia();
                        if (image != null) {
                          setDialogState(() {
                            pickedFile = image;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                      icon: const Icon(Icons.music_note),
                      label: Text(
                        selectedSongName.length > 22 ? '${selectedSongName.substring(0, 22)}...' : selectedSongName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        String? chosenSong = await _showRealOnlineMusicSearchDialog(context);
                        if (chosenSong != null) {
                          setDialogState(() {
                            selectedSongName = chosenSong;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                  onPressed: () {
                    if (pickedFile != null && captionController.text.isNotEmpty) {
                      parentSetState(() {
                        globalFeedItems.insert(0, {
                          'username': 'Tarun',
                          'handle': '@tarun_founder',
                          'caption': captionController.text,
                          'mediaPath': pickedFile!.path,
                          'songName': selectedSongName,
                          'likes': 0,
                          'isLiked': false,
                          'comments': [],
                          'isLocalFile': true,
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post Published Successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a media file and add a caption!')),
                      );
                    }
                  },
                  child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 100% फ्री iTunes API के साथ असली गाने सर्च करने का डायलॉग
  Future<String?> _showRealOnlineMusicSearchDialog(BuildContext context) async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> apiSearchResults = [];
    bool isLoading = false;

    Future<void> searchSongsFromInternet(String query, StateSetter setDialogState) async {
      if (query.trim().isEmpty) return;
      setDialogState(() => isLoading = true);
      
      final url = Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=20');
      
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setDialogState(() {
            apiSearchResults = data['results'] ?? [];
            isLoading = false;
          });
        } else {
          setDialogState(() => isLoading = false);
        }
      } catch (e) {
        setDialogState(() => isLoading = false);
      }
    }

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Search Real Online Songs', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type song name (e.g. Saiyara, Love)...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.amberAccent),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.amberAccent),
                          onPressed: () => searchSongsFromInternet(searchController.text, setDialogState),
                        ),
                      ),
                      onSubmitted: (value) => searchSongsFromInternet(value, setDialogState),
                    ),
                    const SizedBox(height: 10),
                    isLoading
                        ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.amberAccent)))
                        : Expanded(
                            child: apiSearchResults.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Type a keyword above & search real online tracks',
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: apiSearchResults.length,
                                    itemBuilder: (context, index) {
                                      final song = apiSearchResults[index];
                                      final String trackName = song['trackName'] ?? 'Unknown Track';
                                      final String artistName = song['artistName'] ?? 'Unknown Artist';
                                      
                                      return ListTile(
                                        leading: const Icon(Icons.audiotrack, color: Colors.amberAccent),
                                        title: Text(trackName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                        subtitle: Text(artistName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                        trailing: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                                        onTap: () {
                                          Navigator.pop(context, '$trackName - $artistName');
                                        },
                                      );
                                    },
                                  ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// 2. REELS SCREEN (इंस्टाग्राम जैसी फुल-स्क्रीन रील्स फीड)
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final List<String> _reelVideos = [
    'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1185-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-sea-ocean-waves-background-video-1216-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-neon-lights-tunnel-background-33454-large.mp4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _reelVideos.length,
        itemBuilder: (context, index) {
          return ReelItemWidget(videoUrl: _reelVideos[index]);
        },
      ),
    );
  }
}

class ReelItemWidget extends StatefulWidget {
  final String videoUrl;
  const ReelItemWidget({super.key, required this.videoUrl});

  @override
  State<ReelItemWidget> createState() => _ReelItemWidgetState();
}

class _ReelItemWidgetState extends State<ReelItemWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: _controller.value.isInitialized
              ? GestureDetector(
                  onTap: _togglePlayPause,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.amberAccent),
                ),
        ),
        if (!_isPlaying)
          const Center(
            child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
          ),
        Positioned(
          right: 15,
          bottom: 80,
          child: Column(
            children: const [
              Icon(Icons.favorite, color: Colors.white, size: 32),
              Text("12.4K", style: TextStyle(color: Colors.white, fontSize: 12)),
              SizedBox(height: 20),
              Icon(Icons.comment, color: Colors.white, size: 30),
              Text("420", style: TextStyle(color: Colors.white, fontSize: 12)),
              SizedBox(height: 20),
              Icon(Icons.share, color: Colors.white, size: 30),
              Text("Share", style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        Positioned(
          left: 15,
          bottom: 30,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "@tarun_vizia",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                "Margtasni रील्स फीड वर्शन! 🚀🔥 #margtasni #vizia",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 3. REQUESTS SCREEN
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriber Requests'), backgroundColor: const Color(0xFF1E1E1E)),
      body: const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white54))),
    );
  }
}

// 4. PROFILE SCREEN
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'Tarun';
  String handle = '@tarun_vizia';

  void _editProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController handleController = TextEditingController(text: handle);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Edit Margtasni ID', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              TextField(
                controller: handleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'User Handle (@id)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
              onPressed: () {
                setState(() {
                  name = nameController.text;
                  handle = handleController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Margtasni ID'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.amberAccent),
            onPressed: _editProfileDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 45, backgroundColor: Colors.deepPurple, child: Icon(Icons.person, size: 55, color: Colors.white)),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(handle, style: const TextStyle(fontSize: 13, color: Colors.amberAccent)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [Text('${globalFeedItems.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const Text('Posts', style: TextStyle(color: Colors.white54, fontSize: 11))]),
                const Column(children: [Text('3.4K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('Subscribers', style: TextStyle(color: Colors.white54, fontSize: 11))]),
                const Column(children: [Text('145', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('Following', style: TextStyle(color: Colors.white54, fontSize: 11))]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
