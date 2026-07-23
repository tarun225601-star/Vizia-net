import 'package:flutter/material.dart';

void main() {
  runApp(const MargtasniApp());
}

class MargtasniApp extends StatelessWidget {
  const MargtasniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margtasni Global Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amberAccent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// GLOBAL STATE & DATA STORAGE
// -----------------------------------------------------------------------------
double globalUserWalletBalance = 500.0;
double globalCreatorEarnings = 1250.0;
bool isUserLoggedIn = true;
String loggedInMobile = '9971968060';

// Global Feed List with All Features (Like, Comment, Share, Follow, Gifts)
List<Map<String, dynamic>> globalFeedItems = [
  {
    'id': 'post_1',
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni का फाइनल और 100% एरर-फ्री प्रोडक्शन बिल्ड लाइव है! 🚀',
    'songName': 'Radhe Radhe - Live Track',
    'likes': 240,
    'isLiked': false,
    'isFollowing': true,
    'giftsReceived': 5,
    'comments': [
      'भाई अब बिल्ड बिल्कुल मक्खन की तरह पास होगी!',
    ],
  },
  {
    'id': 'post_2',
    'username': 'Elight Deep Cleaning',
    'handle': '@elight_services',
    'caption': 'Faridabad में प्रीमियम वाटर टैंक और कार डिटेलिंग सेवाएं चालू हैं! ✨',
    'songName': 'Desi Beats - Upbeat',
    'likes': 512,
    'isLiked': true,
    'isFollowing': false,
    'giftsReceived': 12,
    'comments': [
      'शानदार परफॉर्मेंस!',
    ],
  },
];

// Song Library for Selection
List<Map<String, String>> globalSongLibrary = [
  {'title': 'Radhe Radhe - Live Track', 'artist': 'Vizia Audio'},
  {'title': 'Desi Beats - Upbeat', 'artist': 'Faridabad Club'},
  {'title': 'Evening Chill - Lofi', 'artist': 'Studio Vizia'},
  {'title': 'Acoustic Guitar - Relaxing', 'artist': 'Unplugged'},
];

// -----------------------------------------------------------------------------
// HOME SCREEN
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedScreen(),
    const CreatePostScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FEED SCREEN
// -----------------------------------------------------------------------------
class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? activePlayingSong;

  void _toggleAudio(String songName) {
    setState(() {
      if (activePlayingSong == songName) {
        activePlayingSong = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio Paused')));
      } else {
        activePlayingSong = songName;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing: $songName 🎵')));
      }
    });
  }

  void _openCommentsDialog(int postIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController commentController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final commentsList = globalFeedItems[postIndex]['comments'] as List;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    const Divider(color: Colors.grey),
                    Expanded(
                      child: ListView.builder(
                        itemCount: commentsList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.amberAccent, child: Icon(Icons.person, color: Colors.black, size: 16)),
                            title: Text(commentsList[index], style: const TextStyle(color: Colors.white, fontSize: 14)),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              filled: true,
                              fillColor: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.amberAccent),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              setState(() {
                                commentsList.add(commentController.text.trim());
                              });
                              setModalState(() {
                                commentController.clear();
                              });
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

  void _sendGiftDialog(int postIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Send Creator Gift (₹50)', style: TextStyle(color: Colors.amberAccent)),
          content: Text('Send a ₹50 tip from your wallet to ${globalFeedItems[postIndex]['username']}?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
              onPressed: () {
                if (globalUserWalletBalance >= 50) {
                  setState(() {
                    globalUserWalletBalance -= 50;
                    globalCreatorEarnings += 50;
                    globalFeedItems[postIndex]['giftsReceived'] += 1;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎁 Gift sent successfully!')));
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient wallet balance!')));
                }
              },
              child: const Text('Send ₹50'),
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
        title: const Text('Margtasni Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: globalFeedItems.length,
        itemBuilder: (context, index) {
          final item = globalFeedItems[index];
          final String songName = item['songName'];
          final bool isPlaying = activePlayingSong == songName;

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.amberAccent,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            Text(item['handle'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item['isFollowing'] ? Colors.grey[800] : Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            item['isFollowing'] = !item['isFollowing'];
                          });
                        },
                        child: Text(item['isFollowing'] ? 'Following' : 'Follow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['caption'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_filled, size: 64, color: Colors.amberAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.amberAccent,
                            size: 32,
                          ),
                          onPressed: () => _toggleAudio(songName),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Background Track', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(songName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              item['isLiked'] ? Icons.favorite : Icons.favorite_border,
                              color: item['isLiked'] ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                item['isLiked'] = !item['isLiked'];
                                item['likes'] += item['isLiked'] ? 1 : -1;
                              });
                            },
                          ),
                          Text('${item['likes']}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.comment_outlined, color: Colors.blueAccent),
                            onPressed: () => _openCommentsDialog(index),
                          ),
                          Text('${(item['comments'] as List).length}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent),
                            onPressed: () => _sendGiftDialog(index),
                          ),
                          Text('${item['giftsReceived']}', style: const TextStyle(color: Colors.amberAccent)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.greenAccent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied!')));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CREATE POST SCREEN
// -----------------------------------------------------------------------------
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  Map<String, String> selectedSong = globalSongLibrary[0];
  bool isVideoPost = true;

  void _openAudioPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Background Song', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const Divider(color: Colors.grey),
              Expanded(
                child: ListView.builder(
                  itemCount: globalSongLibrary.length,
                  itemBuilder: (context, index) {
                    final song = globalSongLibrary[index];
                    return ListTile(
                      title: Text(song['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(song['artist']!, style: const TextStyle(color: Colors.grey)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() {
                            selectedSong = song;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Use'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _publishPost() {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a caption!')));
      return;
    }

    setState(() {
      globalFeedItems.insert(0, {
        'id': 'post_${DateTime.now().millisecondsSinceEpoch}',
        'username': 'Tarun Business',
        'handle': '@tarun_vizia',
        'caption': _captionController.text.trim(),
        'songName': selectedSong['title']!,
        'likes': 1,
        'isLiked': false,
        'isFollowing': true,
        'giftsReceived': 0,
        'comments': ['Nice post!'],
      });
      _captionController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published successfully to Feed! 🚀')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Reel / Post', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 40, color: Colors.amberAccent),
                    SizedBox(height: 8),
                    Text('Media Ready', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write caption...',
                filled: true,
                fillColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Background Music', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _openAudioPickerModal,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amberAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.amberAccent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(selectedSong['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amberAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                onPressed: _publishPost,
                child: const Text('Publish Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WALLET SCREEN
// -----------------------------------------------------------------------------
class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('₹$globalUserWalletBalance', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const SizedBox(height: 16),
                  Text('Creator Earnings: ₹$globalCreatorEarnings', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROFILE SCREEN
// -----------------------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Colors.amberAccent, child: Icon(Icons.person, size: 50, color: Colors.black)),
            const SizedBox(height: 16),
            const Text('Tarun Business', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Mobile: $loggedInMobile', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
