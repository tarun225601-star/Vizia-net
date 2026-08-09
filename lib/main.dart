import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MasterBoxApp());

class MasterBoxApp extends StatelessWidget {
  const MasterBoxApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        primaryColor: Colors.cyanAccent,
      ),
      home: const MasterHomePage(),
    );
  }
}

// ================= 1. सेटिंग्स स्क्रीन =================
class MasterSettingsScreen extends StatefulWidget {
  const MasterSettingsScreen({Key? key}) : super(key: key);
  @override
  State<MasterSettingsScreen> createState() => _MasterSettingsScreenState();
}

class _MasterSettingsScreenState extends State<MasterSettingsScreen> {
  final _groq = TextEditingController();
  final _token = TextEditingController();
  final _user = TextEditingController();
  final _repo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _groq.text = p.getString('groq_key') ?? '';
      _token.text = p.getString('github_token') ?? '';
      _user.text = p.getString('github_username') ?? '';
      _repo.text = p.getString('github_repo_name') ?? '';
    });
  }

  _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('groq_key', _groq.text.trim());
    await p.setString('github_token', _token.text.trim());
    await p.setString('github_username', _user.text.trim());
    await p.setString('github_repo_name', _repo.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ एजेंट क्रेडेंशियल्स सुरक्षित सेव हो गए!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('एजेंट सेटिंग्स (Groq & GitHub)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          TextField(controller: _groq, decoration: const InputDecoration(labelText: 'Groq API Key'), obscureText: true),
          const SizedBox(height: 12),
          TextField(controller: _user, decoration: const InputDecoration(labelText: 'GitHub Username')),
          const SizedBox(height: 12),
          TextField(controller: _repo, decoration: const InputDecoration(labelText: 'GitHub Repository Name')),
          const SizedBox(height: 12),
          TextField(controller: _token, decoration: const InputDecoration(labelText: 'GitHub Personal Access Token (PAT)'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: _save,
            child: const Text('सेटिंग्स सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ]),
      ),
    );
  }
}

// ================= 2. ऑटोनोमस होम स्क्रीन और AI एजेंट =================
class MasterHomePage extends StatefulWidget {
  const MasterHomePage({Key? key}) : super(key: key);
  @override
  State<MasterHomePage> createState() => _MasterHomePageState();
}

class _MasterHomePageState extends State<MasterHomePage> {
  final _prompt = TextEditingController(text: 'Build a camera app that takes photos and asks for camera permission');
  String status = 'ऑटोनोमस एजेंट तैयार है...';
  bool loading = false;
  String actionsUrl = '';

  Future<void> _runAutonomousAgent() async {
    final p = await SharedPreferences.getInstance();
    final groqKey = p.getString('groq_key') ?? '';
    final token = p.getString('github_token') ?? '';
    final user = p.getString('github_username') ?? '';
    final repo = p.getString('github_repo_name') ?? '';

    if (groqKey.isEmpty || token.isEmpty || user.isEmpty || repo.isEmpty) {
      setState(() => status = '❌ एरर: कृपया पहले सेटिंग्स में जाकर क्रेडेंशियल्स भरें!');
      return;
    }

    setState(() {
      loading = true;
      status = '🧠 एजेंट: प्रॉम्ट का विश्लेषण कर रहा है कि कितनी फाइलों और परमिशनों की जरूरत है...';
      actionsUrl = '';
    });

    int attempts = 0;
    bool success = false;
    List files = [];

    // 3-अटैम्प्ट सेल्फ-हीलिंग लूप
    while (attempts < 3 && !success) {
      try {
        attempts++;
        setState(() => status = '⚙️ एजेंट चरण $attempts/3: कोड और कॉन्फ़िगरेशन फाइलें तैयार हो रही हैं...');

        final res = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $groqKey'},
          body: jsonEncode({
            "model": "llama-3.3-70b-versatile",
            "messages": [
              {
                "role": "system",
                "content": """You are an elite Autonomous AI Agent & Senior Mobile Architect like Replit Agent.
Analyze the user request carefully and generate ALL required files to make a fully functioning Flutter app.

CRITICAL RULES:
1. Output ONLY a valid JSON object in this format:
{"files": [{"fileName": "relative/path/file.ext", "fileCode": "full content"}]}

2. REQUIRED FILES IN EVERY PROJECT:
   - 'lib/main.dart'
   - 'pubspec.yaml'
   - '.github/workflows/flutter.yml'

3. PERMISSIONS & NATIVE MANIFEST HANDLING:
   If the app requires ANY permissions (Camera, Location, Storage, Microphone, Bluetooth, Audio, Contacts, etc.):
   - You MUST include 'android/app/src/main/AndroidManifest.xml' containing all necessary <uses-permission> tags.
   - You MUST add required dependencies (e.g., permission_handler, camera, geolocator, etc.) in 'pubspec.yaml'.
   - Implement complete runtime permission check logic in 'lib/main.dart'.

4. GITHUB WORKFLOW YAML:
   '.github/workflows/flutter.yml' MUST use valid multi-line YAML formatting:
   name: Build APK
   on: [push]
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.x'
         - run: flutter pub get
         - run: flutter build apk --release
         - uses: actions/upload-artifact@v3
           with:
             name: release-apk
             path: build/app/outputs/flutter-apk/app-release.apk

5. No markdown wrappers (no ```json), no explanations. Return ONLY valid raw JSON."""
              },
              {"role": "user", "content": _prompt.text}
            ]
          }),
        );

        if (res.statusCode != 200) throw Exception('Groq API Connection Failed (${res.statusCode})');

        String rawContent = jsonDecode(res.body)['choices'][0]['message']['content'];

        // JSON सफाई और स्ट्रिपिंग
        rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
        int startIndex = rawContent.indexOf('{');
        int endIndex = rawContent.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          rawContent = rawContent.substring(startIndex, endIndex + 1);
        }

        var decodedData = jsonDecode(rawContent);
        if (decodedData['files'] == null || (decodedData['files'] as List).isEmpty) {
          throw Exception('Invalid response structure from AI');
        }

        files = decodedData['files'];
        success = true; // JSON और फाइल्स वैलिड हैं
      } catch (e) {
        if (attempts >= 3) {
          setState(() {
            status = '❌ एजेंट फेल: 3 बार ऑटो-करेक्शन के बाद भी सही कोड नहीं बन पाया ($e)';
            loading = false;
          });
          return;
        }
        setState(() => status = '⚠️ सिंटैक्स/स्ट्रक्चर एरर पकड़ा गया! एजेंट खुद ऑटो-करेक्ट कर रहा है (कोशिश $attempts/3)...');
      }
    }

    // गिटहब डिप्लॉयमेंट (सभी फाइलों को सही पाथ पर पुश करना)
    if (success) {
      try {
        setState(() => status = '☁️ एजेंट कुल ${files.length} फाइलों को गिटहब में डिप्लॉय कर रहा है...');

        for (var file in files) {
          String fileName = file['fileName'];
          String fileCode = file['fileCode'];
          final fileUrl = Uri.parse('[https://api.github.com/repos/$user/$repo/contents/$fileName](https://api.github.com/repos/$user/$repo/contents/$fileName)');

          // SHA चेक ताकि फाइल अपडेट/ओवरराइट बिना किसी एरर के हो सके
          String? sha;
          final checkRes = await http.get(fileUrl, headers: {'Authorization': 'Bearer $token'});
          if (checkRes.statusCode == 200) {
            sha = jsonDecode(checkRes.body)['sha'];
          }

          Map<String, dynamic> bodyData = {
            'message': 'Autonomous Deployment: $fileName',
            'content': base64Encode(utf8.encode(fileCode)),
          };
          if (sha != null) bodyData['sha'] = sha;

          final putRes = await http.put(
            fileUrl,
            headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          );

          if (putRes.statusCode != 200 && putRes.statusCode != 201) {
            throw Exception('GitHub Push Failed for $fileName: ${putRes.body}');
          }
        }

        setState(() {
          actionsUrl = '[https://github.com/$user/$repo/actions](https://github.com/$user/$repo/actions)';
          status = '✅ एजेंट का काम पूरा हुआ! ${files.length} फाइलें डिप्लॉय हो गईं। GitHub Actions पर बिल्ड चालू है।';
          loading = false;
        });
      } catch (gitError) {
        setState(() {
          status = '❌ डिप्लॉयमेंट एरर: $gitError';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replit Agent - Autonomous Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterSettingsScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('एजेंट के लिए अपना प्रॉम्ट लिखें:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _prompt,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'उदा. एक ऐसा ऐप बनाओ जो ब्लूटूथ डिवाइस स्कैन करे और परमिशन भी मांगे...',
                filled: true,
                fillColor: Color(0xFF1E293B),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              onPressed: loading ? null : _runAutonomousAgent,
              child: Text(loading ? 'एजेंट काम कर रहा है...' : '🚀 ऑटोनोमस एजेंट चालू करें', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Text(status, style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace')),
            if (actionsUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.cyanAccent)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📦 APK डाउनलोड करने का लिंक:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(actionsUrl, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
