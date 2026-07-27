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
      title: 'Fully Auto AI Agent Builder',
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
// सेटिंग्स स्क्रीन
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
              decoration: const InputDecoration(labelText: 'Groq Cloud API Key'),
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
// होम स्क्रीन (Fully Automated Agent Builder)
// ==========================================
class BuilderHomePage extends StatefulWidget {
  const BuilderHomePage({super.key});

  @override
  State<BuilderHomePage> createState() => _BuilderHomePageState();
}

class _BuilderHomePageState extends State<BuilderHomePage> {
  final TextEditingController _promptController = TextEditingController(
    text: 'make a professional notes and tasks app',
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

  // गिटहब पर फाइल पुश करने का स्मार्ट फंक्शन (अगर फाइल है तो अपडेट, नहीं है तो नई बनेगी)
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
      _addLog('❌ GitHub Push Error ($path): $e');
      return false;
    }
  }

  // --- Groq Cloud API से ऐप कोड जनरेटर ---
  Future<String> _generateCodeWithGroq(String grokApiKey, String userPrompt) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $grokApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are an expert Flutter developer. Write a complete, fully working, single-file Flutter app based on the user request. EVERYTHING must be inside a single file containing main(). Do NOT use external custom packages (only standard material and http if needed). Return ONLY pure Dart code inside ```dart markdown. Do not include any extra conversation."
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
        _addLog('❌ Groq API Error: ${response.body}');
        return '';
      }
    } catch (e) {
      _addLog('❌ Groq Exception: $e');
      return '';
    }
  }

  // --- पूरी तरह ऑटोमैटिक मल्टी-एजेंट प्रोसेस ---
  Future<void> _startFullyAutomatedSystem() async {
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
      buildStatus = 'ऑटो-एजेंट काम कर रहा है...';
      isSuccess = false;
    });

    _addLog('🚀 Fully Automated AI Agent शुरू हो गया है!');

    // --- स्टेप 1: ऑटोमैटिक GitHub Workflow Setup (अगर नहीं है तो खुद बनाएगा) ---
    _addLog('⚙️ एजेंट 1: गिटहब एक्शंस (Workflow) चेक और सेटअप कर रहा है...');
    
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

      - name: Create Android Structure if missing
        run: |
          if [ ! -d "android" ]; then
            flutter create . --org com.example --project-name ai_generated_app --platforms android
          fi

      - name: Install Dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release
''';

    bool workflowSuccess = await _pushFileToGitHub(
      githubToken, repoOwner, repoName, '.github/workflows/build.yml', workflowYml, 'Auto Agent: setup build workflow'
    );

    if (!workflowSuccess) {
      _addLog('❌ गिटहब पर Workflow सेटअप करने में असफल (टोकन या रिपॉजिटरी नाम चेक करें)।');
      setState(() => isRunning = false);
      return;
    }
    _addLog('✔️ गिटहब एक्शंस ऑटो-कॉन्फिगर हो गया!');

    // --- स्टेप 2: Groq 70B से नया ऐप कोड लिखवाना ---
    _addLog('🤖 एजेंट 2: Groq 70B से यूजर के आइडिया पर ऐप कोड लिखवा रहा है...');
    String generatedCode = await _generateCodeWithGroq(grokApiKey, _promptController.text.trim());

    if (generatedCode.isEmpty) {
      _addLog('❌ कोड जनरेशन असफल रहा।');
      setState(() => isRunning = false);
      return;
    }
    _addLog('✔️ lib/main.dart कोड तैयार!');

    // --- स्टेप 3: pubspec.yaml तैयार करना ---
    String pubspecYaml = '''
name: ai_generated_app
description: A new Flutter project generated by Fully Auto AI Agent Builder.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';
    _addLog('✔️ pubspec.yaml कॉन्फिग तैयार!');

    // --- स्टेप 4: गिटहब पर कोड अपलोड करना ---
    _addLog('🔍 एजेंट 3: गिटहब पर कोड और पबस्पेक पुश कर रहा है...');

    bool f1 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'lib/main.dart', generatedCode, 'Auto Agent: update main.dart');
    bool f2 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'pubspec.yaml', pubspecYaml, 'Auto Agent: update pubspec.yaml');

    if (f1 && f2) {
      _addLog('🎉 शानदार! सारा काम ऑटोमैटिक हो गया। गिटहब Actions में APK बनना शुरू हो गया है!');
      setState(() {
        isRunning = false;
        buildStatus = 'बिल्ड सफलतापूर्वक ट्रिगर हो गई!';
        isSuccess = true;
      });
    } else {
      _addLog('⚠️ फाइल अपलोड करने में दिक्कत आई।');
      setState(() {
        isRunning = false;
        buildStatus = 'बिल्ड फेल';
        isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fully Auto AI Builder'),
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
                  const Text('नया ऐप आइडिया यहाँ लिखें:', style: TextStyle(color: Colors.grey)),
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
                onPressed: isRunning ? null : _startFullyAutomatedSystem,
                icon: isRunning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  isRunning ? 'ऑटो-बिल्ड जारी है...' : '🚀 ऑटो-एजेंट चलाकर ऐप बनाएँ',
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
