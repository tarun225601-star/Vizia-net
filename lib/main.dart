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
      title: 'CBSE Complete Education (1-12)',
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
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'All Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Tutor'),
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

  // Complete UKG, LKG & CBSE Class 1 to 12 Full Syllabus Data
  final List<Map<String, dynamic>> allCourses = [
    {
      'title': 'CBSE Class 12th Board Complete Syllabus',
      'category': 'Senior Secondary (Science & Commerce)',
      'lessons': '8 Comprehensive Chapters',
      'rating': '5.0',
      'image': 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800',
      'chapterList': [
        {'name': 'Physics: Electric Charges & Fields', 'duration': '30 mins', 'videoId': 'V77Zk3cI_oY'},
        {'name': 'Physics: Current Electricity', 'duration': '28 mins', 'videoId': 'CgqJvR6C8tM'},
        {'name': 'Maths: Relations and Functions', 'duration': '35 mins', 'videoId': 'L_LUpnjgPso'},
        {'name': 'Maths: Matrices and Determinants', 'duration': '30 mins', 'videoId': 'jC4v5AS4RIM'},
        {'name': 'Chemistry: Solutions & Electrochemistry', 'duration': '25 mins', 'videoId': '2ClgHw6cTqQ'},
        {'name': 'Chemistry: Chemical Kinetics', 'duration': '22 mins', 'videoId': 'pTB0EiLXUC8'},
        {'name': 'English: Flamingo - The Last Lesson', 'duration': '20 mins', 'videoId': 'V77Zk3cI_oY'},
        {'name': 'Accountancy: Partnership Accounts', 'duration': '40 mins', 'videoId': 'CgqJvR6C8tM'},
      ]
    },
    {
      'title': 'CBSE Class 10th Board Complete Syllabus',
      'category': 'Secondary Wing (All Core Subjects)',
      'lessons': '8 Comprehensive Chapters',
      'rating': '4.9',
      'image': 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=800',
      'chapterList': [
        {'name': 'Science: Chemical Reactions & Equations', 'duration': '25 mins', 'videoId': '2ClgHw6cTqQ'},
        {'name': 'Science: Acids, Bases and Salts', 'duration': '22 mins', 'videoId': 'pTB0EiLXUC8'},
        {'name': 'Maths: Real Numbers & Polynomials', 'duration': '30 mins', 'videoId': 'V77Zk3cI_oY'},
        {'name': 'Maths: Quadratic Equations', 'duration': '28 mins', 'videoId': 'CgqJvR6C8tM'},
        {'name': 'Social Science: Nationalism in India', 'duration': '25 mins', 'videoId': 'L_LUpnjgPso'},
        {'name': 'Social Science: Resources and Development', 'duration': '20 mins', 'videoId': 'jC4v5AS4RIM'},
        {'name': 'English: First Flight - A Letter to God', 'duration': '18 mins', 'videoId': '2ClgHw6cTqQ'},
        {'name': 'Hindi: Sparsh - Kabhie Ke Dohe', 'duration': '20 mins', 'videoId': 'pTB0EiLXUC8'},
      ]
    },
    {
      'title': 'CBSE Middle School (Classes 6th, 7th & 8th)',
      'category': 'Middle Wing (NCERT Foundation)',
      'lessons': '6 Comprehensive Chapters',
      'rating': '4.8',
      'image': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=800',
      'chapterList': [
        {'name': 'Class 8 Science: Crop Production & Management', 'duration': '20 mins', 'videoId': 'L_LUpnjgPso'},
        {'name': 'Class 8 Maths: Rational Numbers', 'duration': '22 mins', 'videoId': 'jC4v5AS4RIM'},
        {'name': 'Class 7 Science: Nutrition in Plants', 'duration': '18 mins', 'videoId': '2ClgHw6cTqQ'},
        {'name': 'Class 7 Maths: Integers & Fractions', 'duration': '20 mins', 'videoId': 'pTB0EiLXUC8'},
        {'name': 'Class 6 Science: Components of Food', 'duration': '15 mins', 'videoId': 'V77Zk3cI_oY'},
        {'name': 'Class 6 Maths: Knowing Our Numbers', 'duration': '18 mins', 'videoId': 'CgqJvR6C8tM'},
      ]
    },
    {
      'title': 'CBSE Primary School (Classes 1st to 5th)',
      'category': 'Primary Wing (NCERT Basics)',
      'lessons': '6 Comprehensive Chapters',
      'rating': '4.9',
      'image': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800',
      'chapterList': [
        {'name': 'Class 5 Maths: Math-Magic Full Guide', 'duration': '18 mins', 'videoId': 'pTB0EiLXUC8'},
        {'name': 'Class 4 EVS: Going to School', 'duration': '15 mins', 'videoId': 'V77Zk3cI_oY'},
        {'name': 'Class 3 English: Marigold Book Solutions', 'duration': '15 mins', 'videoId': 'CgqJvR6C8tM'},
        {'name': 'Class 2 Hindi: Rimjhim Chapter Reading', 'duration': '12 mins', 'videoId': 'L_LUpnjgPso'},
        {'name': 'Class 1 English: Raindrops & Phonics', 'duration': '12 mins', 'videoId': 'jC4v5AS4RIM'},
        {'name': 'Basic General Knowledge & Science for Kids', 'duration': '15 mins', 'videoId': '2ClgHw6cTqQ'},
      ]
    },
    {
      'title': 'UKG & LKG Complete Fun Learning Pack',
      'category': 'Kindergarten / Nursery Special',
      'lessons': '6 Comprehensive Chapters',
      'rating': '5.0',
      'image': 'https://images.unsplash.com/photo-1596464019192-396c56fa6ff2?w=800',
      'chapterList': [
        {'name': 'Hindi Varnamala (क से ज्ञ तक सीखें)', 'duration': '15 mins', 'videoId': 'V77Zk3cI_oY'},
        {'name': 'English Alphabets (A for Apple Song)', 'duration': '12 mins', 'videoId': 'CgqJvR6C8tM'},
        {'name': 'Maths Counting (1 to 100 Numbers)', 'duration': '15 mins', 'videoId': 'L_LUpnjgPso'},
        {'name': 'Popular Kids Rhymes (Twinkle Twinkle)', 'duration': '10 mins', 'videoId': 'jC4v5AS4RIM'},
        {'name': 'Colors, Fruits and Vegetables Name', 'duration': '12 mins', 'videoId': '2ClgHw6cTqQ'},
        {'name': 'Good Habits and Manners for Toddlers', 'duration': '10 mins', 'videoId': 'pTB0EiLXUC8'},
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
                    Text('UKG, LKG to Class 12th Complete Syllabus', style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
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
                hintText: 'Search UKG, Class 10, Class 12, Physics...',
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
                const Text('All Classes & Board Packs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${displayedCourses.length} Categories', style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
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
                  : const Center(child: Text('No classes found.', style: TextStyle(color: Colors.white54))),
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
    currentVideoId = chapters.isNotEmpty ? chapters[0]['videoId'] : 'V77Zk3cI_oY';
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
            child: Text('All Chapters & Lessons', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
      appBar: AppBar(title: const Text('CBSE AI Study Tutor'), backgroundColor: const Color(0xFF1E1E1E)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 64, color: Colors.amberAccent),
                    SizedBox(height: 12),
                    Text('Ask any question related to UKG, LKG or CBSE Class 1-12 Syllabus!', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ask homework or syllabus question...',
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
          Center(child: Text('UKG to Class 12th Complete CBSE Platform', style: TextStyle(fontSize: 12, color: Colors.amberAccent))),
          SizedBox(height: 24),
          ListTile(leading: Icon(Icons.groups, color: Colors.white54), title: Text('Total Enrolled Students'), trailing: Text('24,600', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
          ListTile(leading: Icon(Icons.currency_rupee, color: Colors.greenAccent), title: Text('Monthly Platform Revenue'), trailing: Text('₹4,80,000', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
          ListTile(leading: Icon(Icons.workspace_premium, color: Colors.amberAccent), title: Text('Manage Full Syllabus Database'), trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54)),
        ],
      ),
    );
  }
}
