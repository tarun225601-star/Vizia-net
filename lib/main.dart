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
      title: 'LKG & UKG Kids Learning App',
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
          BottomNavigationBarItem(icon: Icon(Icons.child_care), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Helper'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Dashboard'),
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

  // 100% Focused on LKG & UKG Kindergarten Syllabus
  final List<Map<String, dynamic>> allCourses = [
    {
      'title': 'UKG Complete Kindergarten Course',
      'category': 'UKG Kids Learning Wing',
      'lessons': '24 Verified Chapters',
      'rating': '5.0',
      'image': 'https://images.unsplash.com/photo-1596464019192-396c56fa6ff2?w=800',
      'chapterList': [
        {'name': 'Alphabet with Animals', 'duration': '8:07 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'A to Z Animal Alphabet | ABC SONG', 'duration': '2:51 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'Animals Teach Numbers | Learn 1-10', 'duration': '2:13 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'Learn to count | numbers With Spelling', 'duration': '2:29 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'Learn Numbers with Animals', 'duration': '3:08 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Underwater Numbers Song', 'duration': '3:10 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'Learn Vegetables | Vegetable Names', 'duration': '4:08 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'Row Row your boat | rhymes for kids', 'duration': '2:22 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'Learn ENGLISH Alphabets EASILY', 'duration': '4:52 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Learn Fruits | Fruits Names', 'duration': '3:56 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'Learn Alphabet | lkg class | ukg class', 'duration': '8:08 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'Learn 123 | lkg class | ukg class', 'duration': '4:11 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'learn 123 numbers ukg class lkg class', 'duration': '4:32 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Learn Numbers 1 to 10 | LKG Numbers', 'duration': '13:56 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'lkg class 1 ukg class 2 syllabus', 'duration': '5:45 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'ukg class 2 lkg class 1 syllabus shapes', 'duration': '3:55 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'Learn Colors for Kids', 'duration': '3:19 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Learn Shapes for Kids', 'duration': '2:18 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'The Alphabet lkg class ukg class', 'duration': '3:01 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'Parts of the Body for Kids', 'duration': '2:04 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': '123 song | lkg class | ukg class', 'duration': '1:58 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Alphabet rhymes | ukg class | lkg class', 'duration': '2:57 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'Twinkle Twinkle Little Star | ukg class', 'duration': '3:01 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'lkg class 1 ukg class 2 abc syllabus', 'duration': '3:46 mins', 'videoId': '2Vv-BfVoq4g'},
      ]
    },
    {
      'title': 'LKG Complete Kindergarten Course',
      'category': 'LKG Kids Special',
      'lessons': '14 Verified Chapters',
      'rating': '5.0',
      'image': 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=800',
      'chapterList': [
        {'name': 'LKG English Complete Course', 'duration': '10:47 mins', 'videoId': 'EzVU-kDqkho'},
        {'name': 'LKG Class Math Complete', 'duration': '11:10 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'LKG Class Hindi Complete', 'duration': '8:24 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'LKG / UKG EVS: My Self & Family', 'duration': '10:29 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Domestic and Wild Animals Name', 'duration': '10:51 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'Learn Birds name & Aquatic animals name', 'duration': '10:10 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'Part 05 - LKG EVS course | colors name', 'duration': '10:19 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'LKG EVS | transport name for kids', 'duration': '8:10 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Part 9 - LKG / UKG EVS | lines and strokes', 'duration': '8:02 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'Part 10 - LKG / UKG EVS | opposite words', 'duration': '8:02 mins', 'videoId': '5qap5aO4i9A'},
        {'name': 'Part 11 - LKG / UKG EVS | Community Helpers', 'duration': '9:01 mins', 'videoId': 'kJQP7kiw5Fk'},
        {'name': 'Part 11 - LKG / UKG EVS | national symbols', 'duration': '8:21 mins', 'videoId': 'jfKfPfyJRdk'},
        {'name': 'Part 13 - LKG / UKG EVS | indoor & outdoor games', 'duration': '3:08 mins', 'videoId': '2Vv-BfVoq4g'},
        {'name': 'Class LKG / UKG EVS | parts of computer', 'duration': '1:09 mins', 'videoId': '5qap5aO4i9A'},
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
                    Text('Hello, Tarun 👋', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Exclusive LKG & UKG Learning Platform', style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(Icons.verified, color: Colors.amberAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _filterCourses,
              decoration: InputDecoration(
                hintText: 'Search UKG or LKG Courses...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
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
                const Text('Kindergarten Classes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${displayedCourses.length} Programs', style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
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
                            title: Text(course['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
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
                  : const Center(child: Text('No courses found.', style: TextStyle(color: Colors.white54))),
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
    currentVideoId = chapters.isNotEmpty ? chapters[0]['videoId'] : 'jfKfPfyJRdk';
    currentVideoTitle = chapters.isNotEmpty ? chapters[0]['name'] : 'Introduction';
  }

  Future<void> _launchYouTubeVideo(String videoId) async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List chapters = widget.courseData['chapterList'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseData['title'], style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _launchYouTubeVideo(currentVideoId),
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
                        fontSize: 13,
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
              'Playing: $currentVideoTitle',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text('Course Chapters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.4),
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  title: Text(chapter['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text(chapter['duration'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.amberAccent),
                  onTap: () {
                    setState(() {
                      currentVideoId = chapter['videoId'];
                      currentVideoTitle = chapter['name'];
                    });
                    _launchYouTubeVideo(currentVideoId);
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
      appBar: AppBar(title: const Text('Kids AI Learning Assistant'), backgroundColor: const Color(0xFF1E1E1E)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 64, color: Colors.amberAccent),
                    SizedBox(height: 12),
                    Text('Ask questions regarding LKG/UKG curriculum & early childhood education!', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ask about rhymes, alphabets, numbers...',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Founder Dashboard'), backgroundColor: const Color(0xFF1E1E1E)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 40, backgroundColor: Colors.deepPurple, child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
          SizedBox(height: 12),
          Center(child: Text('Tarun (EdTech Founder)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
          SizedBox(height: 4),
          Center(child: Text('LKG & UKG Kids Special Platform', style: TextStyle(fontSize: 12, color: Colors.amberAccent))),
          SizedBox(height: 24),
          ListTile(leading: Icon(Icons.groups, color: Colors.white54), title: Text('Active Kids Enrolled'), trailing: Text('32,400', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
          ListTile(leading: Icon(Icons.currency_rupee, color: Colors.greenAccent), title: Text('Monthly Platform Revenue'), trailing: Text('₹5,20,000', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
          ListTile(leading: Icon(Icons.workspace_premium, color: Colors.amberAccent), title: Text('Manage LKG/UKG Syllabus Database'), trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54)),
        ],
      ),
    );
  }
}
