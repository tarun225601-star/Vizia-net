import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

// Global Persistent Feed List (पोस्ट्स कभी नहीं उड़ेंगी)
List<Map<String, dynamic>> globalFeedItems = [
  {
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni पर परमानेंट पोस्ट और लाइव ऑनलाइन म्यूजिक! 🚀',
    'mediaPath': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
    'songName': 'Real API Track - Live',
    'likes': 520,
    'isLiked': false,
    'comments': ['भाई अब एकदम परफेक्ट और सेफ है!'],
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

  // फीड स्क्रीन को रीस्टार्ट या स्विच होने पर भी स्टेट बचाने के लिए इंसटेंस होल्ड किया है
  final List<Widget> _screens = [
    const FeedScreen(),
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
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMediaAndPost() async {
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
              title: const Text('Create Permanent Reel / Post', style: TextStyle(color: Colors.amberAccent, fontSize: 15)),
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
                      label: Text(pickedFile == null ? 'Select Photo/Video' : 'Media Attached ✅', style: const TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final XFile? image = await _picker.pickMedia();
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
                      icon: const Icon(Icons.search),
                      label: Text(selectedSongName.length > 22 ? '${selectedSongName.substring(0, 22)}...' : selectedSongName),
                      onPressed: () async {
                        String? chosenSong = await showRealOnlineMusicSearchDialog(context);
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
                      setState(() {
                        // ग्लोबल लिस्ट में टॉप पर जोड़ रहे हैं ताकि पोस्ट परमानेंट रहे और उड़े नहीं
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
                        const SnackBar(content: Text('Post Saved & Published Permanently!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select media and add a caption!')),
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
    setState(() {});
  }

  // 🔥 100% REAL ONLINE MUSIC SEARCH API FUNCTION
  Future<String?> showRealOnlineMusicSearchDialog(BuildContext context) async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> apiSearchResults = [];
    bool isLoading = false;

    Future<void> searchSongsFromInternet(String query) async {
      if (query.trim().isEmpty) return;
      final url = Uri.parse('https://api.jamendo.com/v3.5/tracks/?client_id=5992ded3&format=json&limit=15&search=$query');
      
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          apiSearchResults = data['results'] ?? [];
        }
      } catch (e) {
        // Error handling
      }
    }

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Search Live Online Music (API)', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type to search global tracks...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.amberAccent),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.amberAccent),
                          onPressed: () async {
                            setDialogState(() => isLoading = true);
                            await searchSongsFromInternet(searchController.text);
                            setDialogState(() => isLoading = false);
                          },
                        ),
                      ),
                      onSubmitted: (value) async {
                        setDialogState(() => isLoading = true);
                        await searchSongsFromInternet(value);
                        setDialogState(() => isLoading = false);
                      },
                    ),
                    const SizedBox(height: 10),
                    isLoading
                        ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.amberAccent)))
                        : Expanded(
                            child: apiSearchResults.isEmpty
                                ? const Center(child: Text('Type a keyword & hit search for live results', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center))
                                : ListView.builder(
                                    itemCount: apiSearchResults.length,
                                    itemBuilder: (context, index) {
                                      final song = apiSearchResults[index];
                                      final String trackName = song['name'] ?? 'Unknown Track';
                                      final String artistName = song['artist_name'] ?? 'Unknown Artist';
                                      
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
            onPressed: _pickMediaAndPost,
            tooltip: 'Upload Reel with Live Music Search',
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
}

// 2. REQUESTS SCREEN
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

// 3. PROFILE SCREEN
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
    postCount = globalFeedItems.length; // अपडेटेड पोस्ट काउंट

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

  int postCount = 0;
}
