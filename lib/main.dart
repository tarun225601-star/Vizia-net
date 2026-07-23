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
// GLOBAL APPLICATION STATE & DATA MODELS
// -----------------------------------------------------------------------------
double globalUserWalletBalance = 250.0;
double globalCreatorEarnings = 0.0;
bool isUserLoggedIn = true;
String loggedInMobile = '9971968060';

// Global Feed List containing posts, reels, audio tracks, comments, and interactions
List<Map<String, dynamic>> globalFeedItems = [
  {
    'id': 'post_1',
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni का फुल-फ्लेक्ड 1200 लाइन वाला मास्टरपीस कोड लाइव है! 🚀',
    'mediaPath': 'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1186-large.mp4',
    'songName': 'Radhe Radhe - Live Track',
    'likes': 152,
    'isLiked': false,
    'isFollowing': false,
    'comments': [
      'भाई एकदम मक्खन चल रहा है सिस्टम!',
      'सॉन्ग और रील्स क्रिएशन दोनों तगड़े हैं।',
    ],
    'isVideo': true,
  },
  {
    'id': 'post_2',
    'username': 'Elight Deep Cleaning',
    'handle': '@elight_services',
    'caption': 'Faridabad में प्रीमियम वाटर टैंक और कार डिटेलिंग सेवाएं लाइव हैं! ✨',
    'mediaPath': 'https://assets.mixkit.co/videos/preview/mixkit-hand-holding-a-smartphone-touching-the-screen-42999-large.mp4',
    'songName': 'Desi Beats - Upbeat',
    'likes': 342,
    'isLiked': true,
    'isFollowing': true,
    'comments': [
      'शानदार सर्विस भाई!',
      'क्वालिटी एकदम बेहतरीन है।',
    ],
    'isVideo': true,
  },
];

// Available Background Songs Library for Selection & Search
List<Map<String, String>> globalSongLibrary = [
  {'title': 'Radhe Radhe - Live Track', 'artist': 'Vizia Audio', 'duration': '3:45'},
  {'title': 'Desi Beats - Upbeat', 'artist': 'Faridabad Club', 'duration': '2:30'},
  {'title': 'Evening Chill - Lofi', 'artist': 'Studio Vizia', 'duration': '3:10'},
  {'title': 'Acoustic Guitar - Relaxing', 'artist': 'Unplugged', 'duration': '4:00'},
  {'title': 'CyberGuard Electronic', 'artist': 'Tech Beats', 'duration': '2:55'},
];

// -----------------------------------------------------------------------------
// HOME SCREEN WITH BOTTOM NAVIGATION
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FEED SCREEN (Posts, Reels, Audio Player, Likes, Comments, Shares, Follow)
// -----------------------------------------------------------------------------
class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? activePlayingSong;

  void _openSongSearchDialog(int postIndex) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredSongs = globalSongLibrary
                .where((song) => song['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('गाना सर्च करें और बदलें', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'गाना खोजें...',
                        prefixIcon: Icon(Icons.search, color: Colors.amberAccent),
                        filled: true,
                        fillColor: Colors.black,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note, color: Colors.amberAccent),
                            title: Text(song['title']!, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(song['artist']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            onTap: () {
                              setState(() {
                                globalFeedItems[postIndex]['songName'] = song['title'];
                                activePlayingSong = song['title'];
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Song attached & Playing: ${song['title']}')),
                              );
                            },
                          );
                        },
                      ),
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
                height: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comments & Discussions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    const Divider(color: Colors.grey),
                    Expanded(
                      child: ListView.builder(
                        itemCount: commentsList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.amberAccent, child: Icon(Icons.person, color: Colors.black, size: 16)),
                            title: Text(commentsList[index], style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: const Text('Just now', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                              hintText: 'Write a comment...',
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
                    const SizedBox(height: 10),
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
        title: const Text('Margtasni Global Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.amberAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications.')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: globalFeedItems.length,
        itemBuilder: (context, index) {
          final item = globalFeedItems[index];
          final bool isThisSongPlaying = activePlayingSong == item['songName'];

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Profile, Name, Follow Button
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                        onPressed: () {
                          setState(() {
                            item['isFollowing'] = !item['isFollowing'];
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(item['isFollowing'] ? 'Following ${item['username']}' : 'Unfollowed')),
                          );
                        },
                        child: Text(item['isFollowing'] ? 'Following' : 'Follow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Caption
                  Text(item['caption'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 12),
                  // Media Box / Reel Simulation
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.play_circle_filled, size: 64, color: Colors.amberAccent),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                            child: const Text('HD Reel / Video Player', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Background Music Control Bar
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
                            isThisSongPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.amberAccent,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isThisSongPlaying) {
                                activePlayingSong = null;
                              } else {
                                activePlayingSong = item['songName'];
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Background Audio Track', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(
                                item['songName'],
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.amberAccent),
                          tooltip: 'गाना बदलें',
                          onPressed: () {
                            _openSongSearchDialog(index);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Interaction Buttons: Like, Comment, Share
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
                            onPressed: () {
                              _openCommentsDialog(index);
                            },
                          ),
                          Text('${(item['comments'] as List).length}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.greenAccent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post & Reel link copied to clipboard successfully!')),
                          );
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
// CREATE POST / REEL SCREEN WITH SONG ATTACHMENT
// -----------------------------------------------------------------------------
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  String selectedSong = 'Radhe Radhe - Live Track';
  bool isVideoPost = true;

  void _selectSongModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: globalSongLibrary.length,
            itemBuilder: (context, index) {
              final song = globalSongLibrary[index];
              return ListTile(
                leading: const Icon(Icons.music_note, color: Colors.amberAccent),
                title: Text(song['title']!, style: const TextStyle(color: Colors.white)),
                subtitle: Text(song['artist']!, style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  setState(() {
                    selectedSong = song['title']!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _publishPost() {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a caption first!')),
      );
      return;
    }

    setState(() {
      globalFeedItems.insert(0, {
        'id': 'post_${DateTime.now().millisecondsSinceEpoch}',
        'username': 'Tarun Business',
        'handle': '@tarun_vizia',
        'caption': _captionController.text.trim(),
        'mediaPath': 'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1186-large.mp4',
        'songName': selectedSong,
        'likes': 1,
        'isLiked': false,
        'isFollowing': true,
        'comments': ['Nice post!'],
        'isVideo': isVideoPost,
      });
      _captionController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reel/Post published successfully to Feed! 🚀')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reel / Post', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Media Type', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Reel / Video'),
                  selected: isVideoPost,
                  selectedColor: Colors.amberAccent,
                  labelStyle: TextStyle(color: isVideoPost ? Colors.black : Colors.white),
                  onSelected: (val) => setState(() => isVideoPost = true),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Photo Post'),
                  selected: !isVideoPost,
                  selectedColor: Colors.amberAccent,
                  labelStyle: TextStyle(color: !isVideoPost ? Colors.black : Colors.white),
                  onSelected: (val) => setState(() => isVideoPost = false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurpleAccent),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.amberAccent),
                  SizedBox(height: 8),
                  Text('Tap to upload video or photo from device', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Write Caption', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What is on your mind, Tarun?',
                filled: true,
                fillColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Attach Background Song', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectSongModal,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.amberAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(selectedSong, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                ),
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
      appBar: AppBar(
        title: const Text('Margtasni Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.black]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₹$globalUserWalletBalance', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Creator Earnings: ₹$globalCreatorEarnings', style: const TextStyle(color: Colors.white70)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Withdrawal request initiated successfully!')),
                          );
                        },
                        child: const Text('Withdraw'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                    title: Text('Studio Payout Received', style: TextStyle(color: Colors.white)),
                    subtitle: Text('22 Jul 2026', style: TextStyle(color: Colors.grey)),
                    trailing: Text('+₹250.0', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
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
      appBar: AppBar(
        title: const Text('Creator Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amberAccent,
              child: Icon(Icons.person, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Text('Tarun Business', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Mobile: $loggedInMobile', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Faridabad, India • Vizia Global Studio & Elight Services', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', '${globalFeedItems.length}'),
                _buildStatColumn('Followers', '1.2K'),
                _buildStatColumn('Following', '340'),
              ],
            ),
            const Divider(height: 40, color: Colors.grey),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: globalFeedItems.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.grey[850],
                  child: const Center(
                    child: Icon(Icons.play_arrow, color: Colors.amberAccent),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
