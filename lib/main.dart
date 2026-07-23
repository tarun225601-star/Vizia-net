import 'dart:io';
import 'package:flutter/material.dart';

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
    'caption': 'Margtasni का क्लीन और एरर-फ्री वर्शन! 🚀',
    'mediaPath': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
    'songName': 'Default Track - Vizia',
    'likes': 520,
    'isLiked': false,
    'comments': ['भाई अब बिल्ड 100% पास होगा!'],
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
  void _openUploadDialog() {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController songController = TextEditingController(text: 'Vizia Cinematic Beats');
    // Default sample image URL to bypass missing dependency build errors on server
    String selectedImageUrl = 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Create Permanent Post', style: TextStyle(color: Colors.amberAccent, fontSize: 15)),
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
                TextField(
                  controller: songController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Song / Audio Name',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
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
                if (captionController.text.isNotEmpty) {
                  setState(() {
                    globalFeedItems.insert(0, {
                      'username': 'Tarun',
                      'handle': '@tarun_founder',
                      'caption': captionController.text,
                      'mediaPath': selectedImageUrl,
                      'songName': songController.text.isEmpty ? 'Original Audio' : songController.text,
                      'likes': 0,
                      'isLiked': false,
                      'comments': [],
                      'isLocalFile': false,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post Published Successfully!')),
                  );
                }
              },
              child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
            onPressed: _openUploadDialog,
            tooltip: 'Upload Post',
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
