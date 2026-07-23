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
      home: const MargtasniHomeScreen(),
    );
  }
}

// Global Wallet & Earnings State
double globalUserWalletBalance = 250.0;
double globalCreatorEarnings = 0.0;

// Global Persistent Feed List (Supports local files & network URLs)
List<Map<String, dynamic>> globalFeedItems = [
  {
    'username': 'Tarun Business',
    'handle': '@tarun_vizia',
    'caption': 'Margtasni फीड पर गैलरी से डायरेक्ट पोस्ट अपलोड सिस्टम! 🚀🔥',
    'mediaPath': 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
    'songName': 'Radhe Radhe - Live Track',
    'isLocalFile': false,
  },
];

// Global Persistent Reels List
List<Map<String, dynamic>> globalReelItems = [
  {
    'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1185-large.mp4',
    'username': '@tarun_vizia',
    'caption': 'Margtasni रील्स पर अब भेजो क्राउन और गुलाब! 👑🌹',
    'songName': 'Nature Breeze Track',
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

// 1. HOME FEED SCREEN WITH CREATE POST BUTTON
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  void _openCreatePostModal() {
    final TextEditingController captionController = TextEditingController();
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    const Text('Create New Post 📸', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
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
                    const SizedBox(height: 15),
                    selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setModalState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pick Image from Gallery'),
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
                        if (selectedImage != null && captionController.text.isNotEmpty) {
                          setState(() {
                            globalFeedItems.insert(0, {
                              'username': 'Tarun',
                              'handle': '@tarun_vizia',
                              'caption': captionController.text,
                              'mediaPath': selectedImage!.path,
                              'songName': 'Original Audio - Tarun',
                              'isLocalFile': true,
                            });
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post Published Successfully! 🎉'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add a caption and pick an image!'), backgroundColor: Colors.redAccent),
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
        title: const Text('Margtasni Feed', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amberAccent)),
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
          return FeedItemWidget(postData: globalFeedItems[index]);
        },
      ),
    );
  }
}

class FeedItemWidget extends StatelessWidget {
  final Map<String, dynamic> postData;
  const FeedItemWidget({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    bool isLocal = postData['isLocalFile'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.person, color: Colors.white)),
            title: Text(postData['username'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
            subtitle: Text(postData['handle'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Text(postData['caption'], style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(height: 6),
          isLocal
              ? Image.file(File(postData['mediaPath']), height: 240, width: double.infinity, fit: BoxFit.cover)
              : Image.network(postData['mediaPath'], height: 240, width: double.infinity, fit: BoxFit.cover),
        ],
      ),
    );
  }
}

// 2. REELS SCREEN WITH GALLERY UPLOAD & GIFTING
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  void _openCreateReelModal() {
    final TextEditingController captionController = TextEditingController();
    File? selectedVideo;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                              'songName': 'Custom Audio Track',
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

  void _openGiftingBottomSheet(BuildContext context) {
    final List<Map<String, dynamic>> giftList = [
      {'name': 'Rose 🌹', 'price': 10.0, 'icon': '🌹'},
      {'name': 'Star ⭐', 'price': 25.0, 'icon': '⭐'},
      {'name': 'Crown 👑', 'price': 50.0, 'icon': '👑'},
      {'name': 'Diamond 💎', 'price': 100.0, 'icon': '💎'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Send Special Gift 🎁', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Wallet: ₹${globalUserWalletBalance.toStringAsFixed(1)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: giftList.length,
                  itemBuilder: (context, index) {
                    final gift = giftList[index];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        double price = gift['price'];
                        if (globalUserWalletBalance >= price) {
                          globalUserWalletBalance -= price;
                          double creatorShare = price / 2;
                          globalCreatorEarnings += creatorShare;

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sent ${gift['name']}! Creator got ₹$creatorShare, Company got ₹$creatorShare 🚀'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Low Wallet Balance! Recharge from Wallet tab.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(gift['icon'], style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gift['name'].toString().split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('₹${gift['price'].toInt()}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.favorite, color: Colors.white, size: 32),
              const Text("12.4K", style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _openGiftingBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.card_giftcard, color: Colors.black, size: 28),
                ),
              ),
              const Text("Gift", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
              Text(widget.reelData['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.reelData['caption'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

// 3. WALLET & RECHARGE SCREEN
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
            const Text('Quick Recharge (For Sending Gifts)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

// 4. PROFILE SCREEN
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Margtasni ID'), backgroundColor: const Color(0xFF1E1E1E)),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(radius: 45, backgroundColor: Colors.deepPurple, child: Icon(Icons.person, size: 55, color: Colors.white)),
            SizedBox(height: 12),
            Text('Tarun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 4),
            Text('@tarun_vizia', style: TextStyle(fontSize: 13, color: Colors.amberAccent)),
          ],
        ),
      ),
    );
  }
}
