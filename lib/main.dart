   import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SkillSetuApp());
}

class SkillSetuApp extends StatelessWidget {
  const SkillSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSetu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amberAccent,
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AIChatScreen(),
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Mentor'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> allCourses = [
    {
      'title': 'AI Video Editing Mastery',
      'category': 'Video & Editing',
      'lessons': '3 Lessons • 1 Hour',
      'rating': '4.8',
      'image': 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=800',
      'chapterList': [
        {'name': 'Introduction to AI Tools', 'duration': '10 mins', 'videoId': 'pTB0EiLXUC8'},
        {'name': 'Auto-Caption & Cuts', 'duration': '15 mins', 'videoId': 'GLoMzqmdXw0'},
        {'name': 'Cinematic Color Grading', 'duration': '20 mins', 'videoId': '15p_qEwzPpk'},
      ]
    },
    {
      'title': 'Prompt Engineering & ChatGPT',
      'category': 'Artificial Intelligence',
      'lessons': '3 Lessons • 1 Hour',
      'rating': '4.9',
      'image': 'https://images.unsplash.com/photo-1677442136019-21780efad99a?w=800',
      'chapterList': [
        {'name': 'What is Prompt Engineering?', 'duration': '08 mins', 'videoId': '2ClgHw6cTqQ'},
        {'name': 'Advanced Role-playing Prompts', 'duration': '12 mins', 'videoId': 'bSbV7ic9ACA'},
        {'name': 'Building AI Workflows', 'duration': '25 mins', 'videoId': 'pTB0EiLXUC8'},
      ]
    },
  ];

  List<Map<String, dynamic>> displayedCourses = [];

  @override
  void initState() {
    super.initState();
    displayedCourses = List.from(allCourses);
  }

  void _filterCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedCourses = List.from(allCourses);
      } else {
        displayedCourses = allCourses
            .where((course) =>
                course['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
                course['category'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, Learner 👋', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('What skill do you want to master today?', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none, color: Colors.amberAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _filterCourses,
              decoration: InputDecoration(
                hintText: 'Search skills, AI, marketing...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _filterCourses('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top AI & Micro-Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${displayedCourses.length} Courses', style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: displayedCourses.isNotEmpty
                  ? ListView.builder(
                      itemCount: displayedCourses.length,
                      itemBuilder: (context, index) {
                        final course = displayedCourses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                course['image'],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey),
                              ),
                            ),
                            title: Text(course['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(course['category'], style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(course['lessons'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CourseDetailScreen(courseData: course),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('No courses found matching your search.', style: TextStyle(color: Colors.white54))),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;
  const CourseDetailScreen({super.key, required this.courseData});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  String currentVideoId = '';
  String currentVideoTitle = '';

  @override
  void initState() {
    super.initState();
    final chapters = widget.courseData['chapterList'] as List;
    currentVideoId = chapters.isNotEmpty ? chapters[0]['videoId'] : 'pTB0EiLXUC8';
    currentVideoTitle = chapters.isNotEmpty ? chapters[0]['name'] : 'Introduction';
  }

  void _playYouTubeVideo(String videoId) async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    // बिना LaunchMode के सीधा और सेफ तरीका जो कभी फेल नहीं होगा
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List chapters = widget.courseData['chapterList'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseData['title'], style: const TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _playYouTubeVideo(currentVideoId),
            child: Container(
              height: 210,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/$currentVideoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.4)),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      'Tap to Play: $currentVideoTitle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Now Playing: $currentVideoTitle',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text('Course Lessons', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.4),
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(chapter['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text(chapter['duration'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.amberAccent),
                  onTap: () {
                    setState(() {
                      currentVideoId = chapter['videoId'];
                      currentVideoTitle = chapter['name'];
                    });
                    _playYouTubeVideo(currentVideoId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Learning Assistant'), backgroundColor: const Color(0xFF1E1E1E)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 64, color: Colors.amberAccent),
                    SizedBox(height: 12),
                    Text('Ask your AI Mentor anything about your courses!', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.amberAccent), onPressed: () {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

بس 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), backgroundColor: const Color(0xFF1E1E1E)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 40, backgroundColor: Colors.deepPurple, child: Icon(Icons.person, size: 40, color: Colors.white)),
          SizedBox(height: 12),
          Center(child: Text('Tarun Learner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
          SizedBox(height: 4),
          Center(child: Text('Free Tier Member', style: TextStyle(fontSize: 12, color: Colors.amberAccent))),
          SizedBox(height: 24),
          ListTile(leading: Icon(Icons.book, color: Colors.white54), title: Text('Enrolled Courses'), trailing: Text('0', style: TextStyle(color: Colors.white54))),
          ListTile(leading: Icon(Icons.workspace_premium, color: Colors.amberAccent), title: Text('Upgrade to Pro'), trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54)),
        ],
      ),
    );
  }
}
