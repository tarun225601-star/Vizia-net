import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Multi-Agent Builder',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// सेटिंग्स स्क्रीन (Settings Screen)
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
      const SnackBar(content: Text('सेटिंग्स सफलतापूर्वक सेव हो गईं!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('एजेंट सेटिंग्स')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(labelText: 'GitHub Token'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoOwnerController,
              decoration: const InputDecoration(labelText: 'Repo Owner (Username)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoNameController,
              decoration: const InputDecoration(labelText: 'Repo Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groqKeyController,
              decoration: const InputDecoration(labelText: 'Groq API Key'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('सेटिंग्स सेव करें'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// होम स्क्रीन (Home Screen & Multi-Agent Loop)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _logs = [];
  bool _isLoading = false;
  
  String _buildStatus = 'प्रतीक्षा में (Idle)';
  bool _isArtifactAvailable = false;
  String? _artifactDownloadUrl;

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, '[${TimeOfDay.now().format(context)}] $message');
    });
  }

  Future<void> _startProcess() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _addLog("⚠️ कृपया पहले कोई प्रॉम्ट दर्ज करें!");
      return;
    }

    setState(() {
      _isLoading = true;
      _buildStatus = 'टू-एजेंट प्रक्रिया चालू है... ⏳';
      _isArtifactAvailable = false;
      _artifactDownloadUrl = null;
    });

    final prefs = await SharedPreferences.getInstance();
    String githubToken = prefs.getString('github_token') ?? '';
    String repoOwner = prefs.getString('repo_owner') ?? '';
    String repoName = prefs.getString('repo_name') ?? '';
    String groqKey = prefs.getString('groq_key') ?? '';

    if (githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty || groqKey.isEmpty) {
      _addLog("❌ सेटिंग्स अधूरी हैं! कृपया ऊपर सेटिंग आइकॉन से क्रेडेंशियल भरें।");
      setState(() {
        _isLoading = false;
        _buildStatus = 'फेल (Failed) ❌';
      });
      return;
    }

    // मल्टी-एजेंट लूप चलाना
    bool success = await startMultiAgentLoop(
      prompt: prompt,
      path: 'lib/generated_app.dart',
      repoOwner: repoOwner,
      repoName: repoName,
      githubToken: githubToken,
      groqKey: groqKey,
      logCallback: _addLog,
    );

    if (success) {
      setState(() {
        _buildStatus = 'बिल्ड पास (Passed) ✅';
      });
      await _checkGitHubArtifacts(repoOwner, repoName, githubToken);
    } else {
      setState(() {
        _buildStatus = 'बिल्ड फेल (Failed) ❌';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkGitHubArtifacts(String owner, String repo, String token) async {
    try {
      _addLog("🔍 गिटहब एक्शन्स स्टेटस और आर्टिफ़ैक्ट्स की जाँच की जा रही है...");
      await Future.delayed(const Duration(seconds: 3));
      
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/actions/artifacts');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final artifacts = data['artifacts'] as List?;
        if (artifacts != null && artifacts.isNotEmpty) {
          final latestArtifact = artifacts[0];
          setState(() {
            _isArtifactAvailable = true;
            _artifactDownloadUrl = latestArtifact['archive_download_url'];
          });
          _addLog("📦 सफलता! APK आर्टिफ़ैक्ट डाउनलोड के लिए तैयार है।");
        } else {
          _addLog("ℹ️ अभी कोई आर्टिफ़ैक्ट नहीं मिला (या एक्शन प्रोसेस में है)।");
        }
      }
    } catch (e) {
      _addLog("⚠️ आर्टिफ़ैक्ट चेक करने में त्रुटि: $e");
    }
  }

  void _downloadApk() {
    if (_artifactDownloadUrl != null) {
      _addLog("⬇️ डाउनलोड लिंक: $_artifactDownloadUrl");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('आर्टिफ़ैक्ट डाउनलोड लिंक कंसोल में लॉग कर दिया गया है!')),
      );
    } else {
      _addLog("⚠️ अभी कोई डाउनलोड करने योग्य APK आर्टिफ़ैक्ट उपलब्ध नहीं है।");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Multi-Agent Builder'),
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
          children: [
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'आप क्या ऐप बनाना या बदलना चाहते हैं?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startProcess,
              icon: const Icon(Icons.play_arrow),
              label: const Text('टू-एजेंट सिस्टम शुरू करें'),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Text('लाइव प्रोसेस और लॉग्स:'),
            const SizedBox(height: 6),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: _isLoading && _logs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // बिल्ड स्टेटस और आर्टिफ़ैक्ट्स सेक्शन
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'बिल्ड स्टेटस: $_buildStatus',
                        style: TextStyle(
                          color: _buildStatus.contains('पास') || _buildStatus.contains('Passed') 
                              ? Colors.greenAccent 
                              : (_buildStatus.contains('फेल') || _buildStatus.contains('Failed') ? Colors.redAccent : Colors.orangeAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isArtifactAvailable ? 'आर्टिफ़ैक्ट्स: APK उपलब्ध ✅' : 'आर्टिफ़ैक्ट्स: उपलब्ध नहीं ⏳',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: (_isArtifactAvailable && !_isLoading) ? _downloadApk : null,
                    icon: const Icon(Icons.download_rounded),
                    color: _isArtifactAvailable ? Colors.blueAccent : Colors.grey,
                    iconSize: 28,
                    tooltip: 'APK / आर्टिफ़ैक्ट डाउनलोड करें',
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

// ==========================================
// मल्टी-एजेंट लूप (Agent 1: Coder + Agent 2: Reviewer)
// ==========================================
Future<bool> startMultiAgentLoop({
  required String prompt,
  required String path,
  required String repoOwner,
  required String repoName,
  required String githubToken,
  required String groqKey,
  required Function(String) logCallback,
}) async {
  String currentPrompt = prompt;
  bool isBuildSuccessful = false;
  int maxRetries = 3;
  int attempt = 0;

  while (!isBuildSuccessful && attempt < maxRetries) {
    attempt++;
    logCallback("🤖 [Attempt $attempt] एजेंट 1 (Coder) कोड लिख रहा है...");

    String rawCode = await callGroqApiAgent(
      systemPrompt: "You are an expert Flutter Coder Agent. Write clean, complete, and executable Dart code based on user requests. Return ONLY valid code inside markdown code blocks (```dart ... ```).",
      userPrompt: currentPrompt,
      apiKey: groqKey,
      logCallback: logCallback,
    );

    if (rawCode.isEmpty) {
      logCallback("❌ Coder Agent से कोड नहीं मिल पाया।");
      break;
    }

    logCallback("🧐 एजेंट 2 (Reviewer & Debugger) कोड की समीक्षा कर रहा है...");

    String reviewedCode = await callGroqApiAgent(
      systemPrompt: "You are an expert Flutter Reviewer and Debugger Agent. Review the provided Flutter code, fix any syntax errors, missing imports, or logical bugs, and return ONLY the fully corrected, clean Dart code inside standard markdown code blocks (```dart ... ```).",
      userPrompt: "Here is the code written by the Coder Agent:\n$rawCode\n\nOriginal Request: $prompt\nPlease review, fix any bugs, and return the final clean code.",
      apiKey: groqKey,
      logCallback: logCallback,
    );

    String finalCodeToPush = reviewedCode.isNotEmpty ? reviewedCode : rawCode;

    logCallback("📦 फाइनल कोड गिटहब पर पुश किया जा रहा है...");
    var githubResult = await pushCodeToGitHub(
      code: finalCodeToPush,
      path: path,
      repoOwner: repoOwner,
      repoName: repoName,
      githubToken: githubToken,
    );

    if (githubResult['success'] == true) {
      isBuildSuccessful = true;
      logCallback("🎉 शानदार! टू-एजेंट्स ने मिलकर सफलतापूर्वक कोड डिप्लॉय कर दिया।");
      break;
    } else {
      String capturedError = githubResult['error'] ?? 'Unknown build error';
      logCallback("⚠️ गिटहब बिल्ड एरर मिला: $capturedError");

      currentPrompt = """
$prompt

[SYSTEM BUILD ERROR FEEDBACK]:
$capturedError

पिछला कोड इस एरर की वजह से फेल हो गया है। कृपया इस एरर को ठीक करके नया और सही कोड दें।
""";
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  return isBuildSuccessful;
}

// ==========================================
// जेनेरिक Groq API कॉलिंग फंक्शन (Role-based)
// ==========================================
Future<String> callGroqApiAgent({
  required String systemPrompt,
  required String userPrompt,
  required String apiKey,
  required Function(String) logCallback,
}) async {
  try {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.2,
        "max_tokens": 4096
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String content = data['choices'][0]['message']['content'];
      
      if (content.contains('```dart')) {
        final parts = content.split('```dart');
        if (parts.length > 1) {
          content = parts[1].split('```')[0];
        }
      } else if (content.contains('```')) {
        final parts = content.split('```');
        if (parts.length > 1) {
          content = parts[1].split('```')[0];
        }
      }

      return content.trim();
    } else {
      logCallback("❌ Groq API Error: ${response.body}");
      return '';
    }
  } catch (e) {
    logCallback("❌ API Exception: $e");
    return '';
  }
}

// ==========================================
// GitHub Push Function
// ==========================================
Future<Map<String, dynamic>> pushCodeToGitHub({
  required String code,
  required String path,
  required String repoOwner,
  required String repoName,
  required String githubToken,
}) async {
  try {
    final apiUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$path');
    
    String? sha;
    final getResponse = await http.get(
      apiUrl,
      headers: {
        'Authorization': 'token $githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Flutter-AI-Agent',
      },
    );

    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      sha = data['sha'];
    }

    final bodyData = {
      'message': 'AI Multi-Agent auto-update generated app code',
      'content': base64Encode(utf8.encode(code)),
      if (sha != null) 'sha': sha,
    };

    final putResponse = await http.put(
      apiUrl,
      headers: {
        'Authorization': 'token $githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Flutter-AI-Agent',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyData),
    );

    if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
      return {'success': true};
    } else {
      return {'success': false, 'error': putResponse.body};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
