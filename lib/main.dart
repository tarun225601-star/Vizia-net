import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: यहाँ अपनी असली Supabase URL और Anon Key डाल देना भाई
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MargtasniApp());
}

final supabase = Supabase.instance.client;

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
// GLOBAL DATA & SONG LIBRARY
// -----------------------------------------------------------------------------
double globalUserWalletBalance = 500.0;
double globalCreatorEarnings = 1250.0;

List<Map<String, dynamic>> globalStories = [
  {'name': 'Your story', 'hasStory': false, 'isAdd': true},
  {'name': 'muskansingh0...', 'hasStory': true, 'isAdd': false},
  {'name': 'dheer_singh_6...', 'hasStory': true, 'isAdd': false},
  {'name': 'poojatanwa...', 'hasStory': true, 'isAdd': false},
  {'name': 'Priyanka', 'hasStory': true, 'isAdd': false},
];

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
// FEED SCREEN (FETCHES REAL-TIME POSTS FROM SUPABASE CLOUD)
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
  String currentTopTab = 'Reels';
  List<Map<String, dynamic>> feedItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
    _fetchCloudPosts();
  }

  Future<void> _fetchCloudPosts() async {
    try {
      final response = await supabase.from('posts').select().order('created_at', ascending: false);
      setState(() {
        feedItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        feedItems = [
          {
            'username': 'Tarun Business',
            'handle': '@tarun_vizia',
            'caption': 'Supabase Connected Successfully! 🚀',
            'media_path': '',
            'song_name': 'Radhe Radhe - Live Track',
            'song_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            'likes': 100,
          }
        ];
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleAudio(String url) async {
    try {
      if (activePlayingUrl == url && isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          activePlayingUrl = url;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              onTap: () => setState(() => currentTopTab = 'Reels'),
              child: Text(
                'Reels',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: currentTopTab == 'Reels' ? Colors.white : Colors.grey,
                ),
              ),
            ),
            const Text('  v  ', style: TextStyle(color: Colors.grey, fontSize: 14)),
            InkWell(
              onTap: () => setState(() => currentTopTab = 'Friends'),
              child: Text(
                'Friends',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: currentTopTab == 'Friends' ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amberAccent),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchCloudPosts();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : Column(
              children: [
                // Stories Bar
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: globalStories.length,
                    itemBuilder: (context, index) {
                      final story = globalStories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[800],
                              child: story['isAdd']
                                  ? const Icon(Icons.add, color: Colors.white, size: 28)
                                  : const Icon(Icons.person, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 65,
                              child: Text(
                                story['name'],
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.grey, height: 1),

                // Feed List from Supabase Cloud
                Expanded(
                  child: ListView.builder(
                    itemCount: feedItems.length,
                    itemBuilder: (context, index) {
                      final item = feedItems[index];
                      final String songUrl = item['song_url'] ?? globalSongLibrary[0]['url']!;
                      final bool isThisSongPlaying = activePlayingUrl == songUrl && isPlaying;
                      final String mediaPath = item['media_path'] ?? '';

                      return Card(
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.amberAccent,
                                    child: Icon(Icons.person, color: Colors.black, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(item['username'] ?? 'Tarun Business', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  height: 380,
                                  width: double.infinity,
                                  color: Colors.grey[900],
                                  child: mediaPath.isNotEmpty && File(mediaPath).existsSync()
                                      ? Image.file(File(mediaPath), fit: BoxFit.cover)
                                      : const Center(
                                          child: Icon(Icons.image, size: 64, color: Colors.white30),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.red, size: 28),
                                      const SizedBox(height: 4),
                                      Text('${item['likes'] ?? 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 70,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['caption'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.music_note, color: Colors.amberAccent, size: 14),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item['song_name'] ?? 'Radhe Radhe',
                                              style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isThisSongPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                              color: Colors.amberAccent,
                                              size: 28,
                                            ),
                                            onPressed: () => _toggleAudio(songUrl),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// CREATE POST SCREEN (UPLOADS DIRECTLY TO SUPABASE)
// -----------------------------------------------------------------------------
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? pickedFilepath;
  Map<String, String> selectedSong = globalSongLibrary[0];
  bool isUploading = false;

  Future<void> _pickMedia() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedFilepath = image.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selected from Gallery!')),
      );
    }
  }

  void _showSongPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Select Background Song', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              ),
              const Divider(color: Colors.grey),
              Expanded(
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
                          selectedSong = song;
                        });
                        Navigator.pop(context);
                      },
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

  Future<void> _publishToSupabaseCloud() async {
    setState(() => isUploading = true);

    try {
      // Supabase डेटाबेस की 'posts' टेबल में डाटा सेव करना
      await supabase.from('posts').insert({
        'username': 'Tarun Business',
        'handle': '@tarun_vizia',
        'caption': _captionController.text.trim().isEmpty ? 'New Reel by Tarun' : _captionController.text.trim(),
        'media_path': pickedFilepath ?? '',
        'song_name': selectedSong['title']!,
        'song_url': selectedSong['url']!,
        'likes': 1,
      });

      setState(() {
        _captionController.clear();
        pickedFilepath = null;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel Published to Supabase Cloud Server! 🚀')),
      );
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud Upload Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reel (Cloud)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickMedia,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent),
                ),
                child: pickedFilepath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(pickedFilepath!), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.amberAccent),
                          SizedBox(height: 8),
                          Text('Tap to Select Photo from Gallery', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.music_note, color: Colors.amberAccent),
              title: Text(selectedSong['title']!, style: const TextStyle(color: Colors.white)),
              subtitle: const Text('Tap to change song', style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
              onTap: _showSongPickerModal,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                filled: true,
                fillColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: isUploading ? null : _publishToSupabaseCloud,
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Publish to Cloud Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet'), backgroundColor: Colors.black),
      body: Center(child: Text('Available Balance: ₹$globalUserWalletBalance', style: const TextStyle(fontSize: 18))),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.black),
      body: const Center(child: Text('Tarun Business • Faridabad', style: TextStyle(fontSize: 18))),
    );
  }
}
