import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      home: const AuthCheckScreen(),
    );
  }
}

// Global State
double globalUserWalletBalance = 250.0;
double globalCreatorEarnings = 0.0;
bool isUserLoggedIn = false;
String loggedInMobile = '';

// Global Persistent Feed List (With Auto-Playing Media & Song)
List<Map<String, dynamic>> globalFeedItems = [
  {
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni फीड पर ऑटो-प्ले म्यूजिक और वीडियो लाइव! 🚀🔥',
    'mediaPath': 'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1185-large.mp4',
    'songName': 'Radhe Radhe - Live Track',
    'likes': 152,
    'isLiked': false,
    'isFollowing': false,
    'comments': ['भाई गजब ऑटो-प्ले हो रहा है!', 'मस्त मज़ा आ गया!'],
    'isVideo': true,
  },
];

// Global Persistent Reels List
List<Map<String, dynamic>> globalReelItems = [
  {
    'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1185-large.mp4',
    'username': '@tarun_vizia',
    'caption': 'Margtasni रील्स पर ऑटो-प्ले और गिफ्टिंग! 👑🌹',
    'songName': 'Nature Breeze - Original Audio',
    'likes': 1240,
    'isLiked': false,
    'isFollowing': false,
    'isLocalFile': false,
  },
];

// 1. AUTH CHECK & MOBILE LOGIN SCREEN
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  Widget build(BuildContext context) {
    if (!isUserLoggedIn) {
      return const MobileLoginScreen();
    } else {
      return const MargtasniHomeScreen();
    }
  }
}

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, size: 70, color: Colors.amberAccent),
                const SizedBox(height: 10),
                const Text(
                  'Margtasni Login',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Enter your mobile number to continue',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixText: '+91 ',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 15),
                if (otpSent) ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP (Type 1234)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                       onPressed: () {
  setState(() {
    isUserLoggedIn = true;
  });
},

}

// 2. MAIN HOME CONTAINER
class MargtasniHomeScreen extends StatefulWidget {
  const MargtasniHomeScreen({super.key});

  @override
  State<MargtasniHomeScreen> createState() => _MargtasniHomeScreenState();
}

class _MargtasniHomeScreenState extends State<MargtasniHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const ReelsScreen(),
    const WalletScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// 3. FEED SCREEN WITH AUTO-PLAY MEDIA
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  void _openCreatePostModal() {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController songController = TextEditingController(text: 'Original Audio');
    File? selectedMedia;
    bool isVideoFile = false;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Auto-Play Post 🎥', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    TextField(
                      controller: captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Write a caption...',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: songController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Background Song Name 🎵',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                            ),
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setModalState(() {
                                  selectedMedia = File(image.path);
                                  isVideoFile = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo),
                            label: const Text('Pick Image'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                            ),
                            onPressed: () async {
                              final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                              if (video != null) {
                                setModalState(() {
                                  selectedMedia = File(video.path);
                                  isVideoFile = true;
                                });
                              }
                            },
                            icon: const Icon(Icons.videocam),
                            label: const Text('Pick Video/Song'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (selectedMedia != null)
                      Text('Selected: ${selectedMedia!.path.split('/').last}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (selectedMedia != null && captionController.text.isNotEmpty) {
                          setState(() {
                            globalFeedItems.insert(0, {
                              'username': 'Tarun',
                              'handle': '@tarun_vizia',
                              'caption': captionController.text,
                              'mediaPath': selectedMedia!.path,
                              'songName': songController.text.isEmpty ? 'Original Audio' : songController.text,
                              'likes': 0,
                              'isLiked': false,
                              'isFollowing': false,
                              'comments': <String>[],
                              'isVideo': isVideoFile,
                            });
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Auto-Play Post Published! 🎉'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add caption and select media!'), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                      child: const Text('Share Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        title: const Text('Margtasni Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.amberAccent, size: 28),
            onPressed: _openCreatePostModal,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: globalFeedItems.length,
        itemBuilder: (context, index) {
          return FeedItemWidget(
            postData: globalFeedItems[index],
            onUpdate: () => setState(() {}),
          );
        },
      ),
    );
  }
}

class FeedItemWidget extends StatefulWidget {
  final Map<String, dynamic> postData;
  final VoidCallback onUpdate;
  const FeedItemWidget({super.key, required this.postData, required this.onUpdate});

  @override
  State<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends State<FeedItemWidget> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    bool isVideo = widget.postData['isVideo'] ?? false;
    if (isVideo) {
      String path = widget.postData['mediaPath'];
      if (path.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(path));
      } else {
        _videoController = VideoPlayerController.file(File(path));
      }
      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play(); // Automatically starts playing song/audio
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _openCommentsDialog(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List comments = widget.postData['comments'] ?? [];
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 350,
                child: Column(
                  children: [
                    const Text('Comments 💬', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  dense: true,
                                  leading: const CircleAvatar(radius: 14, backgroundColor: Colors.deepPurple, child: Icon(Icons.person, size: 14, color: Colors.white)),
                                  title: Text(comments[index], style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                              setDialogState(() {
                                comments.add(commentController.text);
                              });
                              widget.onUpdate();
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
    bool isVideo = widget.postData['isVideo'] ?? false;
    bool isLiked = widget.postData['isLiked'] ?? false;
    bool isFollowing = widget.postData['isFollowing'] ?? false;
    int likes = widget.postData['likes'] ?? 0;
    List comments = widget.postData['comments'] ?? [];
    String songName = widget.postData['songName'] ?? 'Original Audio';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white)),
            title: Text(widget.postData['username'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
            subtitle: Row(
              children: [
                const Icon(Icons.music_note, size: 12, color: Colors.amberAccent),
                const SizedBox(width: 4),
                Expanded(child: Text(songName, style: const TextStyle(color: Colors.amberAccent, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ],
            ),
            trailing: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isFollowing ? Colors.transparent : Colors.amberAccent,
                side: const BorderSide(color: Colors.amberAccent),
                minimumSize: const Size(70, 30),
              ),
              onPressed: () {
                setState(() {
                  widget.postData['isFollowing'] = !isFollowing;
                });
                widget.onUpdate();
              },
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(color: isFollowing ? Colors.amberAccent : Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Text(widget.postData['caption'], style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(height: 6),
          // Auto-Playing Media Box
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                if (!isLiked) {
                  widget.postData['isLiked'] = true;
                  widget.postData['likes'] = likes + 1;
                } else {
                  widget.postData['isLiked'] = false;
                  widget.postData['likes'] = likes - 1;
                }
              });
              widget.onUpdate();
            },
            child: isVideo && _videoController != null && _videoController!.value.isInitialized
                ? SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: VideoPlayer(_videoController!),
                  )
                : (widget.postData['mediaPath'].startsWith('http')
                    ? Image.network(widget.postData['mediaPath'], height: 280, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(File(widget.postData['mediaPath']), height: 280, width: double.infinity, fit: BoxFit.cover)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.white, size: 26),
                  onPressed: () {
                    setState(() {
                      if (!isLiked) {
                        widget.postData['isLiked'] = true;
                        widget.postData['likes'] = likes + 1;
                      } else {
                        widget.postData['isLiked'] = false;
                        widget.postData['likes'] = likes - 1;
                      }
                    });
                    widget.onUpdate();
                  },
                ),
                Text('$likes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 24),
                  onPressed: () => _openCommentsDialog(context),
                ),
                Text('${comments.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 24),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post link copied! 🔗'), backgroundColor: Colors.deepPurple),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. REELS SCREEN WITH AUTO-PLAY
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  void _openCreateReelModal() {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController songController = TextEditingController(text: 'Original Audio');
    File? selectedVideo;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upload New Reel 🎥', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    TextField(
                      controller: captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Reel caption...',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: songController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Background Song Name 🎵',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    selectedVideo != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.deepPurple.shade900, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.video_file, color: Colors.amberAccent, size: 30),
                                const SizedBox(width: 10),
                                Expanded(child: Text(selectedVideo!.path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () async {
                              final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                              if (video != null) {
                                setModalState(() {
                                  selectedVideo = File(video.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.video_library),
                            label: const Text('Pick Video from Gallery'),
                          ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (selectedVideo != null && captionController.text.isNotEmpty) {
                          setState(() {
                            globalReelItems.insert(0, {
                              'videoUrl': selectedVideo!.path,
                              'username': '@tarun_vizia',
                              'caption': captionController.text,
                              'songName': songController.text.isEmpty ? 'Original Audio' : songController.text,
                              'likes': 10,
                              'isLiked': false,
                              'isFollowing': false,
                              'isLocalFile': true,
                            });
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reel Uploaded Successfully! 🚀'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add a caption and select a video!'), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                      child: const Text('Publish Reel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Margtasni Reels', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.amberAccent, size: 28),
            onPressed: _openCreateReelModal,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: globalReelItems.length,
        itemBuilder: (context, index) {
          return ReelItemWidget(reelData: globalReelItems[index]);
        },
      ),
    );
  }
}

class ReelItemWidget extends StatefulWidget {
  final Map<String, dynamic> reelData;
  const ReelItemWidget({super.key, required this.reelData});

  @override
  State<ReelItemWidget> createState() => _ReelItemWidgetState();
}

class _ReelItemWidgetState extends State<ReelItemWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    bool isLocal = widget.reelData['isLocalFile'] ?? false;
    if (isLocal) {
      _controller = VideoPlayerController.file(File(widget.reelData['videoUrl']));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reelData['videoUrl']));
    }

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLiked = widget.reelData['isLiked'] ?? false;
    bool isFollowing = widget.reelData['isFollowing'] ?? false;
    int likes = widget.reelData['likes'] ?? 1240;
    String songName = widget.reelData['songName'] ?? 'Original Audio';

    return Stack(
      children: [
        SizedBox.expand(
          child: _controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
        ),
        Positioned(
          right: 15,
          bottom: 100,
          child: Column(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.white, size: 34),
                onPressed: () {
                  setState(() {
                    if (!isLiked) {
                      widget.reelData['isLiked'] = true;
                      widget.reelData['likes'] = likes + 1;
                    } else {
                      widget.reelData['isLiked'] = false;
                      widget.reelData['likes'] = likes - 1;
                    }
                  });
                },
              ),
              Text("$likes", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reel link copied! 🔗'), backgroundColor: Colors.deepPurple),
                  );
                },
              ),
              const Text("Share", style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        Positioned(
          left: 15,
          bottom: 30,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.reelData['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.reelData['isFollowing'] = !isFollowing;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amberAccent),
                        color: isFollowing ? Colors.transparent : Colors.amberAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(color: isFollowing ? Colors.amberAccent : Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.reelData['caption'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.amberAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(child: Text(songName, style: const TextStyle(color: Colors.amberAccent, fontSize: 12), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 5. WALLET SCREEN
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  void _rechargeWallet(double amount) {
    setState(() {
      globalUserWalletBalance += amount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully added ₹$amount to your Wallet! 🎉'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Margtasni Wallet & Monetization'), backgroundColor: const Color(0xFF1E1E1E)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('₹${globalUserWalletBalance.toStringAsFixed(1)}', style: const TextStyle(color: Colors.amberAccent, fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.account_balance_wallet, color: Colors.amberAccent, size: 45),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quick Recharge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                  onPressed: () => _rechargeWallet(50),
                  child: const Text('+ ₹50'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                  onPressed: () => _rechargeWallet(100),
                  child: const Text('+ ₹100'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                  onPressed: () => _rechargeWallet(500),
                  child: const Text('+ ₹500'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            const Text('Creator & Company 50-50 Split Dashboard', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Creator Earnings (50%):', style: TextStyle(color: Colors.white70)),
                      Text('₹${globalCreatorEarnings.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Company Revenue Share (50%):', style: TextStyle(color: Colors.white70)),
                      Text('₹${globalCreatorEarnings.toStringAsFixed(1)}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
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

// 6. PROFILE SCREEN
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Margtasni ID'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                isUserLoggedIn = false;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Colors.deepPurple, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 10),
            const Text('Tarun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('@tarun_vizia | +91 $loggedInMobile', style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', '${globalFeedItems.length}'),
                _buildStatColumn('Followers', '1.2K'),
                _buildStatColumn('Following', '340'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}
