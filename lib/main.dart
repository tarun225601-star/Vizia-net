import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tinnpdgnzteoltrysjax.supabase.co',
    anonKey: 'sb_publishable_x_TWreV14I3daOmV4Un4LA_dkLd0euy',
  );
  runApp(const MargtasniApp());
}

class MargtasniApp extends StatelessWidget {
  const MargtasniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Margtasni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const FeedScreen(),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  // Supabase से पोस्ट फेच करने का फंक्शन
  Future<void> fetchPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select()
          .order('id', ascending: false);

      setState(() {
        posts = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('डेटा लोड करने में एरर: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Margtasni Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPostScreen()),
              );
              if (result == true) {
                fetchPosts(); // पोस्ट डलने के बाद फीड रिफ्रेश होगी
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(
                  child: Text(
                    'अभी तक कोई पोस्ट नहीं है!\nऊपर (+) बटन दबाकर नई पोस्ट डालें।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // यूजर इन्फो
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.pinkAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(post['username'] ?? 'User',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(post['handle'] ?? '@handle',
                                style: const TextStyle(color: Colors.grey)),
                          ),
                          // मीडिया / इमेज
                          if (post['mediaPath'] != null && post['mediaPath'].toString().isNotEmpty)
                            Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.black,
                              child: Image.network(
                                post['mediaPath'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                            ),
                          // गाना / ऑडियो इन्फो
                          if (post['songName'] != null && post['songName'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.music_note, size: 18, color: Colors.pinkAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Original Audio - ${post['songName']}',
                                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          // कैप्शन
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              post['caption'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// नया पोस्ट और गाना जोड़ने वाली स्क्रीन
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _usernameController = TextEditingController();
  final _handleController = TextEditingController();
  final _captionController = TextEditingController();
  final _mediaController = TextEditingController();
  final _songController = TextEditingController();
  bool isUploading = false;

  Future<void> submitPost() async {
    if (_usernameController.text.isEmpty || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया यूजरनेम और कैप्शन भरें!')),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // Supabase में डेटा सेव करना
      await Supabase.instance.client.from('posts').insert({
        'username': _usernameController.text,
        'handle': _handleController.text.isEmpty ? '@user' : _handleController.text,
        'caption': _captionController.text,
        'mediaPath': _mediaController.text,
        'songName': _songController.text,
      });

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('पोस्ट सेव करने में एरर: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post & Music')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Your Name (जैसे: Tarun)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _handleController,
              decoration: const InputDecoration(labelText: 'Handle (जैसे: @tarun)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption (कुछ लिखें...)'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mediaController,
              decoration: const InputDecoration(labelText: 'Media/Image Link (URL)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _songController,
              decoration: const InputDecoration(
                labelText: 'Background Song Name (गाने का नाम)',
                prefixIcon: Icon(Icons.music_note),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: isUploading ? null : submitPost,
              child: isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
