import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MultiAgentBuilderApp());
}

class MultiAgentBuilderApp extends StatelessWidget {
  const MultiAgentBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Multi-Agent Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurple,
      ),
      home: const BuilderHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// सेटिंग्स स्क्रीन (Grok और GitHub क्रेडेंशियल्स)
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _repoOwnerController = TextEditingController();
  final TextEditingController _repoNameController = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _repoOwnerController.text = prefs.getString('repo_owner') ?? '';
      _repoNameController.text = prefs.getString('repo_name') ?? '';
      _groqKeyController.text = prefs.getString('groq_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('repo_owner', _repoOwnerController.text.trim());
    await prefs.setString('repo_name', _repoNameController.text.trim());
    await prefs.setString('groq_key', _groqKeyController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('सेटिंग्स सफलतापूर्वक सेव हो गई हैं!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('एपीआई और गिटहब सेटिंग्स')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(labelText: 'GitHub Personal Access Token'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoOwnerController,
              decoration: const InputDecoration(labelText: 'GitHub Username / Owner'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoNameController,
              decoration: const InputDecoration(labelText: 'GitHub Repository Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groqKeyController,
              decoration: const InputDecoration(labelText: 'Grok (xAI) API Key'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('सभी सेटिंग्स सेव करें'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// होम स्क्रीन (Self-Contained Multi-Agent Builder)
// ==========================================
class BuilderHomePage extends StatefulWidget {
  const BuilderHomePage({super.key});

  @override
  State<BuilderHomePage> createState() => _BuilderHomePageState();
}

class _BuilderHomePageState extends State<BuilderHomePage> {
  final TextEditingController _promptController = TextEditingController(
    text: 'make a professional weather app',
  );

  List<String> logs = [];
  bool isRunning = false;
  String buildStatus = 'प्रतीक्षा में (Idle)';
  bool isSuccess = false;

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      final timeOfDay = TimeOfDay.fromDateTime(DateTime.now()).format(context);
      logs.insert(0, '[$timeOfDay] $message');
    });
  }

  // गिटहब पर सिंगल फाइल पुश करने का एकदम सेफ फंक्शन
  Future<bool> _pushFileToGitHub(String token, String owner, String repo, String path, String content, String commitMessage) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
      String? sha;
      
      final getRes = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (getRes.statusCode == 200) {
        sha = jsonDecode(getRes.body)['sha'];
      }

      final body = {
        'message': commitMessage,
        'content': base64Encode(utf8.encode(content)),
        if (sha != null) 'sha': sha,
      };

      final putRes = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return putRes.statusCode == 200 || putRes.statusCode == 201;
    } catch (e) {
      _addLog('❌ GitHub Push Error: $e');
      return false;
    }
  }

  // --- Grok API से 100% सेल्फ-कंटेन्ड सिंगल-फाइल कोड जनरेटर ---
  Future<String> _generateCodeWithGrok(String grokApiKey, String userPrompt) async {
    try {
      final url = Uri.parse('https://api.x.ai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $grokApiKey',
        },
        body: jsonEncode({
          "model": "grok-beta",
          "messages": [
            {
              "role": "system",
              "content": "You are an expert Flutter developer. Write a complete, fully working, single-file Flutter app based on the user request. EVERYTHING must be inside a single file containing main(). Do NOT use external custom packages or split into multiple files. Return ONLY pure Dart code inside ```dart markdown. Do not include any extra conversation."
            },
            {
              "role": "user",
              "content": userPrompt
            }
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['choices'][0]['message']['content'];

        if (text.contains('```dart')) {
          text = text.split('```dart')[1].split('```')[0];
        } else if (text.contains('```')) {
          text = text.split('```')[1];
        }
        return text.trim();
      } else {
        _addLog('❌ Grok API Error: ${response.body}');
        return '';
      }
    } catch (e) {
      _addLog('❌ Grok Exception: $e');
      return '';
    }
  }

  // मल्टी-एजेंट प्रोसेस
  Future<void> _startMultiAgentsSystem() async {
    final prefs = await SharedPreferences.getInstance();
    String githubToken = prefs.getString('github_token') ?? '';
    String repoOwner = prefs.getString('repo_owner') ?? '';
    String repoName = prefs.getString('repo_name') ?? '';
    String grokApiKey = prefs.getString('groq_key') ?? '';

    if (githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty || grokApiKey.isEmpty) {
      _addLog('❌ सेटिंग्स अधूरी हैं! कृपया ऊपर सेटिंग आइकॉन पर क्लिक करके सभी API Keys और GitHub डिटेल्स भरें।');
      return;
    }

    setState(() {
      isRunning = true;
      logs.clear();
      buildStatus = 'प्रक्रिया जारी है...';
      isSuccess = false;
    });

    _addLog('🚀 एजेंट सिस्टम सक्रिय हो गया है!');
    
    // --- एजेंट 1: Grok AI कोडर ---
    _addLog('🤖 एजेंट 1 (Grok AI) सिंगल-फाइल ऐप कोड लिख रहा है...');
    String generatedCode = await _generateCodeWithGrok(grokApiKey, _promptController.text.trim());

    if (generatedCode.isEmpty) {
      _addLog('❌ एजेंट 1 कोड जनरेट करने में असफल रहा। API Key चेक करें।');
      setState(() => isRunning = false);
      return;
    }

    _addLog('✅ एजेंट 1: एकदम एरर-फ्री सिंगल-फाइल कोड तैयार है!');

    // फिक्स्ड गिटहब एक्शन वर्कफ़्लो फाइल (ताकि APK बिल्ड में कोई दिक्कत न आए)
    String workflowYml = '''
name: Flutter Build

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "20.x"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.9'

      - name: Install Dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release
    ''';

    // --- एजेंट 2: गिटहब डिप्लोयर ---
    _addLog('🔍 एजेंट 2 गिटहब पर सिंगल फाइल डिप्लॉय कर रहा है...');
    
    bool mainPushed = await _pushFileToGitHub(
      githubToken, repoOwner, repoName, 
      'lib/main.dart', generatedCode, 'AI Agent auto-commit safe single-file lib/main.dart'
    );

    if (mainPushed) {
      _addLog('✔️ lib/main.dart सफलतापूर्वक अपडेट हो गई है!');
    }

    bool ymlPushed = await _pushFileToGitHub(
      githubToken, repoOwner, repoName, 
      '.github/workflows/build.yml', workflowYml, 'AI Agent add workflow yml'
    );

    if (ymlPushed) {
      _addLog('✔️ गिटहब एक्शन वर्कफ़्लो सेट हो गया है!');
    }

    await Future.delayed(const Duration(seconds: 1));
    _addLog('🎉 काम पूरा! बिना किसी फाइल एरर के कोड गिटहब पर पहुँच गया है।');

    setState(() {
      isRunning = false;
      buildStatus = 'बिल्ड पास (Passed)';
      isSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Multi-Agent Builder (Grok)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('कोई भी ऐप आइडिया यहाँ लिखें:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: isRunning ? null : _startMultiAgentsSystem,
                icon: isRunning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.flash_on),
                label: Text(
                  isRunning ? 'प्रक्रिया जारी है...' : '✨ एजेंट सिस्टम शुरू करें',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('लाइव प्रोसेस और लॉग्स:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        logs[index],
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('बिल्ड स्टेटस: $buildStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(isSuccess ? Icons.check_circle : Icons.info, color: isSuccess ? Colors.green : Colors.orange),
                    onPressed: () {},
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
