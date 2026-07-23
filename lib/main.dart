import 'package:flutter/material.dart';

void main() {
  runApp(const MargtasniApp());
}

class MargtasniApp extends StatelessWidget {
  const MargtasniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margtasni',
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

// Global State
double globalUserWalletBalance = 250.0;
double globalCreatorEarnings = 0.0;
bool isUserLoggedIn = true;
String loggedInMobile = '9971968060';

// Global Feed List with Working Audio State
List<Map<String, dynamic>> globalFeedItems = [
  {
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni का दोपहर वाला वही सुपरफास्ट ऑडियो और पोस्ट सिस्टम लाइव है! 🚀',
    'songName': 'Radhe Radhe - Live Track',
    'likes': 152,
    'isLiked': false,
    'comments': ['भाई दोपहर वाला सिस्टम एकदम सही था!', 'गाना मक्खन चल रहा है!'],
  },
  {
    'username': 'Elight Deep Cleaning',
    'handle': '@elight_services',
    'caption': 'Faridabad में प्रीमियम वाटर टैंक और कार डिटेलिंग सेवाएं लाइव हैं! ✨',
    'songName': 'Desi Beats - Upbeat',
    'likes': 342,
    'isLiked': false,
    'comments': ['शानदार रिस्पॉन्स भाई!'],
  },
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FeedScreen(),
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
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
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

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? activePlayingSong;

  final List<String> availableSongs = [
    'Radhe Radhe - Live Track',
    'Desi Beats - Upbeat',
    'Evening Chill - Lofi',
    'Acoustic Guitar - Relaxing',
  ];

  void _openSongSearchDialog(int postIndex) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredSongs = availableSongs
                .where((song) => song.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('गाना सर्च करें और चुनें', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
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
                            title: Text(song, style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              setState(() {
                                globalFeedItems[postIndex]['songName'] = song;
                                activePlayingSong = song;
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Now Playing: $song')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Margtasni Feed'),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: globalFeedItems.length,
        itemBuilder: (context, index) {
          final item = globalFeedItems[index];
          final bool isThisSongPlaying = activePlayingSong == item['songName'];

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.all(8.0),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          Text(item['handle'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['caption'], style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    color: Colors.black54,
                    child: const Center(
                      child: Text('Media Player Active', style: TextStyle(color: Colors.amberAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Background Music Bar with Play/Pause & Search
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
                              const Text('Background Music', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                          tooltip: 'गाना सर्च करें',
                          onPressed: () {
                            _openSongSearchDialog(index);
                          },
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
                            icon: const Icon(Icons.comment, color: Colors.blueAccent),
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
                            const SnackBar(content: Text('Post link shared successfully!')),
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

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Wallet Balance: ₹$globalUserWalletBalance',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
            const SizedBox(height: 20),
            Text(
              'Earnings: ₹$globalCreatorEarnings',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
}
