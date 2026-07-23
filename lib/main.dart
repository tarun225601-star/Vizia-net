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

// Global Feed List with All Interactive Features (Like, Comment, Share, Follow, Audio, Gifts)
List<Map<String, dynamic>> globalFeedItems = [
  {
    'id': 'post_1',
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni का फाइनल ऑल-इन-वन स्टूडियो वर्जन लाइव है! 🚀',
    'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'songName': 'Radhe Radhe - Live Track',
    'songUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'likes': 240,
    'isLiked': false,
    'isFollowing': true,
    'giftsReceived': 5,
    'comments': [
      'भाई गिफ्ट और ऑडियो वाला सिस्टम एकदम तगड़ा है!',
      'मक्खन चल रहा है ऐप।',
    ],
  },
  {
    'id': 'post_2',
    'username': 'Elight Deep Cleaning',
    'handle': '@elight_services',
    'caption': 'Faridabad में प्रीमियम वाटर टैंक और कार डिटेलिंग सेवाएं चालू हैं! ✨',
    'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'songName': 'Desi Beats - Upbeat',
    'songUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'likes': 512,
    'isLiked': true,
    'isFollowing': false,
    'giftsReceived': 12,
    'comments': [
      'शानदार सर्विस और बेहतरीन फीचर्स!',
    ],
  },
];

// Available Song Library for Selection & Audio Preview
List<Map<String, String>> globalSongLibrary = [
  {
    'title': 'Radhe Radhe - Live Track',
    'artist': 'Vizia Audio',
    'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  },
  {
    'title': 'Desi Beats - Upbeat',
    'artist': 'Faridabad Club',
    'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  },
  {
    'title': 'Evening Chill - Lofi',
    'artist': 'Studio Vizia',
    'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  },
  {
    'title': 'Acoustic Guitar - Relaxing',
    'artist': 'Unplugged',
    'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
  },
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
// FEED SCREEN (Like, Comment, Share, Follow, Audio Playback, Send Gift)
// -----------------------------------------------------------------------------
class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final AudioPlayer _audioPlayer;
  String? activePlayingUrl;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Audio Player Toggle for Feed Posts
  void _toggleAudio(String url) async {
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio Playback Error: $e')),
      );
    }
  }

  // Comments Bottom Sheet
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

  // Send Gift / Money Dialog from Wallet to Creator
  void _sendGiftDialog(int postIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Send Creator Gift (₹50)', style: TextStyle(color: Colors.amberAccent)),
          content: Text('Do you want to send a ₹50 gift/tip from your wallet to ${globalFeedItems[postIndex]['username']}?', style: const TextStyle(color: Colors.white70)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎁 Gift sent successfully from your wallet!')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient wallet balance!')),
                  );
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
        title: const Text('Margtasni Global Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: globalFeedItems.length,
        itemBuilder: (context, index) {
          final item = globalFeedItems[index];
          final String songUrl = item['songUrl'];
          final bool isThisSongPlaying = activePlayingUrl == songUrl && isPlaying;

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Profile & Follow Button
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(item['isFollowing'] ? 'Following ${item['username']}' : 'Unfollowed')),
                          );
                        },
                        child: Text(item['isFollowing'] ? 'Following' : 'Follow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['caption'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 12),
                  // Video / Reel Player Simulator Box
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                    ),
                    child: const Stack(
                      children: [
                        Center(
                          child: Icon(Icons.play_circle_filled, size: 64, color: Colors.amberAccent),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Text('HD Reel / Video Stream Active', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Background Music Control Bar (Play/Pause Song)
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
                          onPressed: () => _toggleAudio(songUrl),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Attached Song Track', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(
                                item['songName'],
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Interaction Toolbar: Like, Comment, Gift, Share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Like Button & Counter
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
                      // Comment Button & Counter
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.comment_outlined, color: Colors.blueAccent),
                            onPressed: () => _openCommentsDialog(index),
                          ),
                          Text('${(item['comments'] as List).length}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      // Send Gift / Money Button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent),
                            onPressed: () => _sendGiftDialog(index),
                          ),
                          Text('${item['giftsReceived']}', style: const TextStyle(color: Colors.amberAccent)),
                        ],
                      ),
                      // Share Button
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.greenAccent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post link copied to clipboard!')),
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
// CREATE POST SCREEN WITH INSTAGRAM-STYLE AUDIO PREVIEW
// -----------------------------------------------------------------------------
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  late final AudioPlayer _previewPlayer;
  
  Map<String, String> selectedSong = globalSongLibrary[0];
  String? previewingSongUrl;
  bool isPreviewPlaying = false;
  bool isVideoPost = true;

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  // Song Preview Modal with Play/Pause button for each track
  void _openAudioPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Background Song (Preview)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const Text('Tap play button to listen before selecting', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: ListView.builder(
                      itemCount: globalSongLibrary.length,
                      itemBuilder: (context, index) {
                        final song = globalSongLibrary[index];
                        final bool isThisPlaying = previewingSongUrl == song['url'] && isPreviewPlaying;

                        return ListTile(
                          leading: IconButton(
                            icon: Icon(
                              isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.amberAccent,
                              size: 36,
                            ),
                            onPressed: () async {
                              if (isThisPlaying) {
                                await _previewPlayer.pause();
                                setModalState(() {
                                  isPreviewPlaying = false;
                                });
                              } else {
                                await _previewPlayer.stop();
                                await _previewPlayer.play(UrlSource(song['url']!));
                                setModalState(() {
                                  previewingSongUrl = song['url'];
                                  isPreviewPlaying = true;
                                });
                              }
                            },
                          ),
                          title: Text(song['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(song['artist']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                            onPressed: () {
                              _previewPlayer.stop();
                              setState(() {
                                selectedSong = song;
                                isPreviewPlaying = false;
                                previewingSongUrl = null;
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Selected Song: ${song['title']}')),
                              );
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
        'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        'songName': selectedSong['title']!,
        'songUrl': selectedSong['url']!,
        'likes': 1,
        'isLiked': false,
        'isFollowing': true,
        'giftsReceived': 0,
        'comments': ['Nice post!'],
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
                border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.amberAccent),
                  SizedBox(height: 8),
                  Text('Media Ready for Publishing', style: TextStyle(color: Colors.white70)),
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
            const Text('Attach Background Song (Instagram Style Preview)', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected Song', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(selectedSong['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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
// WALLET SCREEN (Balance, Earnings & Gift Management)
// -----------------------------------------------------------------------------
class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Margtasni Wallet & Gifts', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Available Wallet Balance', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                            const SnackBar(content: Text('Withdrawal request processed successfully!')),
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
            const Text('Wallet History & Gift Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                    title: Text('Gift Received from Post', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Today, 9:40 PM', style: TextStyle(color: Colors.grey)),
                    trailing: Text('+₹50.0', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
            const Text('Faridabad, India • Vizia Global Studio', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', '${globalFeedItems.length}'),
                _buildStatColumn('Followers', '1.4K'),
                _buildStatColumn('Following', '410'),
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
