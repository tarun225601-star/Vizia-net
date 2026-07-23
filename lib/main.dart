import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

// Global Persistent Feed List with Audio Tracks
List<Map<String, dynamic>> globalFeedItems = [
  {
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni फीड पर गाने सर्च करके चलाने वाला फीचर लाइव हो गया है! 🚀',
    'mediaPath': 'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1186-large.mp4',
    'songName': 'Radhe Radhe - Live Track',
    'songUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'likes': 152,
    'isLiked': false,
    'isFollowing': false,
    'comments': ['भाई एकदम धांसू फीचर है!', 'मस्त चल रहा है!'],
    'isVideo': true,
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? activePlayingUrl;
  bool isPlaying = false;

  // उपलब्ध गानों की लिस्ट (जिन्हें यूजर सर्च या सेलेक्ट कर सकता है)
  final List<Map<String, String>> availableSongs = [
    {
      'title': 'Radhe Radhe - Live Track',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'title': 'Desi Beats - Upbeat',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
    {
      'title': 'Evening Chill - Lofi',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    },
  ];

  void togglePlay(String url) async {
    if (activePlayingUrl == url && isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        activePlayingUrl = url;
        isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // गाना सर्च करने और बदलने वाला डायलॉग बॉक्स ओपन करने का फंक्शन
  void _openSongSearchDialog(int postIndex) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredSongs = availableSongs
                .where((song) => song['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
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
                            title: Text(song['title']!, style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              setState(() {
                                globalFeedItems[postIndex]['songName'] = song['title'];
                                globalFeedItems[postIndex]['songUrl'] = song['url'];
                              });
                              // नया गाना चुनते ही तुरंत बजाना शुरू करें
                              togglePlay(song['url']!);
                              Navigator.pop(context);
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
          final bool isThisSongPlaying = activePlayingUrl == item['songUrl'] && isPlaying;

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
                  // गाना दिखाने, प्ले/पॉज करने और सर्च करने की पट्टी (Music Bar)
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
                            togglePlay(item['songUrl']);
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
                          const Icon(Icons.favorite, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('${item['likes']}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.comment, color: Colors.blueAccent),
                          SizedBox(width: 4),
                          Text('Comments', style: const TextStyle(color: Colors.white)),
                        ],
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
  const WalletScreen({Key? key}) : key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Center(
        child: Text(
          'Wallet Balance: ₹$globalUserWalletBalance',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amberAccent,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Text('Tarun Business', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Mobile: $loggedInMobile', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
