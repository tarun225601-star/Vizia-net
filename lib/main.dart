import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia AI Agent Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// होम स्क्रीन (UI & Autonomous Agent Logic)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _logs = [];
  bool _isProcessing = false;
  final ScrollController _scrollController = ScrollController();

  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}] $message");
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==========================================
  // AUTONOMOUS SELF-HEALING AGENT (FULL ENGINE)
  // ==========================================
  Future<void> _runSafeAiAgent() async {
    final promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      _addLog("❌ Error: Please enter a prompt for the AI Agent.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    _addLog("🚀 Starting Autonomous AI Agent (Self-Healing Mode)...");

    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_key') ?? '';
    final githubToken = prefs.getString('github_token') ?? '';
    final repoOwner = prefs.getString('repo_owner') ?? '';
    final repoName = prefs.getString('repo_name') ?? '';

    if (groqKey.isEmpty || githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty) {
      _addLog("🚨 Error: Please configure your API credentials in Settings first!");
      setState(() => _isProcessing = false);
      return;
    }

    String currentContextPrompt = promptText;
    int maxSelfHealingRetries = 3;
    bool overallSuccess = false;

    for (int attempt = 1; attempt <= maxSelfHealingRetries; attempt++) {
      _addLog("\n🤖 प्रयास (Attempt $attempt/$maxSelfHealingRetries): AI से कम्युनिकेट कर रहे हैं...");

      try {
        // 1. Groq API Call (Llama 3.3)
        final groqUrl = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final groqResponse = await http.post(
          groqUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $groqKey',
          },
                      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": "You are an expert Flutter developer. You must return a strict JSON array containing ONLY two files: 'lib/main.dart' with all UI/logic, and a valid 'pubspec.yaml' with proper SDK constraints. Do NOT create any .github folders or workflows. Output ONLY valid JSON array format with keys 'path' and 'content', with no extra text."},
          {"role": "user", "content": currentContextPrompt}
        ],
        "temperature": 0.2
      }),


        );

        if (groqResponse.statusCode != 200) {
          throw Exception("Groq API Error: ${groqResponse.body}");
        }

        final groqData = jsonDecode(groqResponse.body);
        String rawContent = groqData['choices'][0]['message']['content'];
        
        // Clean JSON formatting
        rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
        
        List<dynamic> filesList = jsonDecode(rawContent);
        _addLog("📦 AI ने सफलतापूर्वक ${filesList.length} फाइल(्स) जनरेट की हैं।");

        bool allFilesPushedSuccessfully = true;

        // 2. Process & Push each file to GitHub
        for (var fileItem in filesList) {
          String rawPath = fileItem['path']?.toString() ?? '';
          String code = fileItem['code']?.toString() ?? '';

          // --- Self-Healing Path & Safety Logic ---
          String path = rawPath.trim();
          if (path.isEmpty || path == '/' || path == '\\') {
            path = 'lib/generated_app.dart';
            _addLog("⚠️ AI Self-Healing: पाथ गायब था, ऑटोमैटिक सेट किया गया -> $path");
          }

          // Clean up path structure
          path = path.replaceAll(' ', '_');
          while (path.startsWith('/') || path.startsWith('\\')) {
            path = path.substring(1);
          }

          _addLog("📤 GitHub पर पुश कर रहे हैं: $path ...");

          // 3. GitHub API: Get existing file SHA if present
          final fileUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$path');
          
          String? fileSha;
          final getFileRes = await http.get(
            fileUrl,
            headers: {
              'Authorization': 'Bearer $githubToken',
              'Accept': 'application/vnd.github+json',
            },
          );

          if (getFileRes.statusCode == 200) {
            final fileData = jsonDecode(getFileRes.body);
            fileSha = fileData['sha'];
          }

          // 4. GitHub API: Put/Commit file
          final Map<String, dynamic> bodyData = {
            "message": "Autonomous Agent Self-Healing Commit for $path",
            "content": base64Encode(utf8.encode(code)),
          };
          if (fileSha != null) {
            bodyData["sha"] = fileSha;
          }

          final putRes = await http.put(
            fileUrl,
            headers: {
              'Authorization': 'Bearer $githubToken',
              'Accept': 'application/vnd.github+json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(bodyData),
          );

          if (putRes.statusCode != 200 && putRes.statusCode != 201) {
            allFilesPushedSuccessfully = false;
            throw Exception("GitHub API Failed for $path: ${putRes.body}");
          } else {
            _addLog("✅ सफलतापूर्वक डिप्लॉय हुआ: $path");
          }
        }

        if (allFilesPushedSuccessfully) {
          overallSuccess = true;
          _addLog("\n🎉 शानदार! AI एजेंट ने बिना किसी बाहरी रुकावट के पूरा काम अपने आप ठीक करके फिनिश कर दिया।");
          break;
        }

      } catch (e) {
        // --- Autonomous Error Self-Correction ---
        String caughtError = e.toString();
        _addLog("⚠️ एजेंट को रास्ते में एरर मिला: $caughtError");
        
        if (attempt < maxSelfHealingRetries) {
          _addLog("🔄 AI खुद अपनी गलती का विश्लेषण कर रहा है और अगली कोशिश कर रहा है...");
          currentContextPrompt = "$promptText \n\n[SYSTEM ERROR FEEDBACK FROM PREVIOUS ATTEMPT]: $caughtError. \nकृपया इस एरर को समझें, अपनी गलती (चाहे पाथ में हो या फॉर्मेट में) को खुद ठीक करें, और एकदम शुद्ध JSON रिस्पॉन्स दें।";
          await Future.delayed(const Duration(seconds: 2));
        } else {
          _addLog("❌ माफ करना भाई, 3 बार ऑटो-करेक्शन की कोशिश के बाद भी यह ठीक नहीं हो पाया।");
        }
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia AI Agent Studio'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt Input Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _promptController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'असिस्टेंट को कमांड दें (जैसे: please make simple calculator app)...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Run Agent Button (Corrected Syntax)
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _runSafeAiAgent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isProcessing ? 'AI Agent Working...' : 'Build App with AI Agent Safely',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Logs Section Title
            const Text(
              'Live Execution Logs & Agent Activity:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Logs Console Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.greenAccent),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// सेटिंग्स स्क्रीन (Credentials Manager)
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _groqController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _repoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groqController.text = prefs.getString('groq_key') ?? '';
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _ownerController.text = prefs.getString('repo_owner') ?? '';
      _repoController.text = prefs.getString('repo_name') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', _groqController.text.trim());
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('repo_owner', _ownerController.text.trim());
    await prefs.setString('repo_name', _repoController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Credentials Settings'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _groqController,
              decoration: const InputDecoration(labelText: 'Groq API Key', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(labelText: 'GitHub Personal Access Token', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'GitHub Username / Owner', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repoController,
              decoration: const InputDecoration(labelText: 'Repository Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save Settings', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
