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

// ==================== होम स्क्रीन ====================
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
      _logs.add("[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}]$message");
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // सुरक्षित एआई एजेंट फंक्शन (फुल पाथ क्लीनिंग फिक्स के साथ)
  Future<void> _runSafeAiAgent() async {
    final promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      _addLog("❌ Error: Please enter an app prompt first!");
      return;
    }

    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    _addLog("🚀 Starting Autonomous AI Agent...");

    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_key') ?? '';
    final githubToken = prefs.getString('github_token') ?? '';
    final repoOwner = prefs.getString('repo_owner') ?? '';
    final repoName = prefs.getString('repo_name') ?? '';

    if (groqKey.isEmpty || githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty) {
      _addLog("🚨 Error: Please configure all API keys in Settings first!");
      setState(() => _isProcessing = false);
      return;
    }

    _addLog("🔑 Credentials loaded for repository: $repoOwner/$repoName");

    try {
      _addLog("🤖 Asking Groq AI (Llama 3.3) to design the requested app...");
      
      final groqUrl = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final groqResponse = await http.post(
        groqUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an autonomous senior Flutter developer. The user wants to build a new app feature based on their prompt. CRITICAL RULE: NEVER modify or rewrite "lib/main.dart". Instead, create new files with unique names (e.g., "lib/counter_app.dart") or a separate folder structure. Return ONLY a valid JSON list of objects with "path" and "code" keys. No markdown like ```json, raw JSON only.'
            },
            {'role': 'user', 'content': promptText}
          ],
          'temperature': 0.2,
        }),
      );

      if (groqResponse.statusCode != 200) {
        throw Exception("Groq API Failed (${groqResponse.statusCode}): ${groqResponse.body}");
      }

      final groqData = jsonDecode(groqResponse.body);
      String rawContent = groqData['choices'][0]['message']['content'];
      rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();

      List<dynamic> filesList = jsonDecode(rawContent);
      _addLog("📦 AI generated ${filesList.length} files successfully!");

      for (var fileItem in filesList) {
        String path = fileItem['path'].toString().trim();
        path = path.replaceAll(' ', '_'); 
        String code = fileItem['code'];

        // सुरक्षा चेक: मास्टर फाइल को ओवरराइट होने से बचाना
        if (path.contains('lib/main.dart') || path == 'main.dart') {
          _addLog("🛡️ Safety Block: Ignored attempt to overwrite master main.dart file!");
          continue;
        }

        _addLog("📤 Pushing to GitHub: $path ...");

        // 100% सेफ पाथ फॉर्मेटिंग ताकि FormatException कभी न आए
        final cleanPath = path.startsWith('/') ? path.substring(1) : path;
        final fileUrl = Uri.parse('[https://api.github.com/repos/$repoOwner/$repoName/contents/$cleanPath](https://api.github.com/repos/$repoOwner/$repoName/contents/$cleanPath)');

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

        String base64EncodedCode = base64Encode(utf8.encode(code));
        final Map<String, dynamic> bodyData = {
          'message': 'AI Agent: created/updated separate module $cleanPath',
          'content': base64EncodedCode,
          'branch': 'main',
        };

        if (fileSha != null) {
          bodyData['sha'] = fileSha;
        }

        final putFileRes = await http.put(
          fileUrl,
          headers: {
            'Authorization': 'Bearer $githubToken',
            'Accept': 'application/vnd.github+json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(bodyData),
        );

        if (putFileRes.statusCode != 200 && putFileRes.statusCode != 201) {
          throw Exception("GitHub Push Failed for $cleanPath: ${putFileRes.body}");
        }
        _addLog("✅ Successfully pushed: $cleanPath");
      }

      _addLog("🎉 All files pushed successfully without touching master main.dart!");

    } catch (e) {
      _addLog("⚠️ Error: ${e.toString()}");
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26),
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
          children: [
            // बड़ा सा प्रॉम्प्ट इनपुट बॉक्स
            TextField(
              controller: _promptController,
              maxLines: 6,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your app prompt here (Agent will build it in a separate file safely)...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // बड़ा सा शानदार एजेंट रन बटन
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _runSafeAiAgent,
                icon: _isProcessing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                    : const Icon(Icons.auto_awesome, size: 24, color: Colors.amberAccent),
                label: Text(
                  _isProcessing ? 'AI Agent Working...' : 'Build App with AI Agent Safely',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Live Execution Logs & Agent Activity:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amberAccent),
              ),
            ),
            const SizedBox(height: 8),

            // नीचे बड़ा टर्मिनल कंसोल बॉक्स
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
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

// ==================== सेटिंग्स स्क्रीन ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _groqKeyController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _repoOwnerController = TextEditingController();
  final TextEditingController _repoNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groqKeyController.text = prefs.getString('groq_key') ?? '';
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _repoOwnerController.text = prefs.getString('repo_owner') ?? 'tarun225601-star';
      _repoNameController.text = prefs.getString('repo_name') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', _groqKeyController.text.trim());
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('repo_owner', _repoOwnerController.text.trim());
    await prefs.setString('repo_name', _repoNameController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API & GitHub Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _groqKeyController,
              decoration: const InputDecoration(labelText: 'Groq API Key', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(labelText: 'GitHub Personal Access Token', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoOwnerController,
              decoration: const InputDecoration(labelText: 'Repository Owner (Username)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoNameController,
              decoration: const InputDecoration(labelText: 'Repository Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)),
              child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
