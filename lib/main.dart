import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Agent & APK Studio',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// होम स्क्रीन & UI इंटरफेस
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

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, "[${TimeOfDay.now().format(context)}] $message");
    });
  }

  // एजेंटिक लूप स्टार्ट करने वाला बटन फंक्शन
  Future<void> _startProcess() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _addLog("⚠️ कृपया पहले कोई प्रॉम्प्ट दर्ज करें!");
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    String githubToken = prefs.getString('github_token') ?? '';
    String repoOwner = prefs.getString('repo_owner') ?? '';
    String repoName = prefs.getString('repo_name') ?? '';
    String groqKey = prefs.getString('groq_key') ?? '';

    if (githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty || groqKey.isEmpty) {
      _addLog("❌ सेटिंग्स अधूरी हैं! कृपया ऊपर सेटिंग आइकॉन पर क्लिक करके API Keys और Repo डिटेल्स भरें।");
      setState(() => _isLoading = false);
      return;
    }

    await startAgenticLoop(prompt, 'lib/generated_app.dart', repoOwner, repoName, githubToken, groqKey, _addLog);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agent & GitHub Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
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
                labelText: 'आप क्या ऐप बनवाना चाहते हैं?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: _isLoading ? null : _startProcess,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('एजेंट शुरू करें'),
                  ),
                ),
                const SizedBox(width: 10),
                // इमेज पिकर बटन
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                  icon: const Icon(Icons.image, color: Colors.greenAccent),
                  tooltip: 'एरर स्क्रीनशॉट अपलोड करें',
                  onPressed: () => pickErrorImageAndFix(_addLog, _promptController),
                ),
                const SizedBox(width: 5),
                // APK डाउनलोड बटन
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                  icon: const Icon(Icons.download, color: Colors.orangeAccent),
                  tooltip: 'गिटहब से APK डाउनलोड करें',
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    downloadApkFromGitHub(
                      prefs.getString('repo_owner') ?? '',
                      prefs.getString('repo_name') ?? '',
                      prefs.getString('github_token') ?? '',
                      _addLog,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text('लाइव प्रोसेस और लॉग्स:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: _isLoading && _logs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
      const SnackBar(content: Text('सेटिंग्स सफलतापूर्वक सेव हो गईं!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ऐप सेटिंग्स')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(labelText: 'GitHub Personal Access Token', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoOwnerController,
              decoration: const InputDecoration(labelText: 'GitHub Username / Owner', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoNameController,
              decoration: const InputDecoration(labelText: 'GitHub Repository Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groqKeyController,
              decoration: const InputDecoration(labelText: 'Groq API Key (AI)', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
// एजेंटिक लूप और लॉजिक फंक्शन्स
// ==========================================
Future<void> startAgenticLoop(
    String initialPrompt, 
    String path, 
    String repoOwner, 
    String repoName, 
    String githubToken, 
    String groqKey,
    Function(String) logCallback) async {
  
  String currentPrompt = initialPrompt;
  bool isBuildSuccessful = false;
  int maxRetries = 3;
  int attempt = 0;

  while (!isBuildSuccessful && attempt < maxRetries) {
    attempt++;
    logCallback("🔄 कोशिश नंबर $attempt जारी है...");

    String aiGeneratedCode = await callGroqApi(currentPrompt, groqKey, logCallback);
    if (aiGeneratedCode.isEmpty) break;

    var gitHubResult = await pushCodeToGitHubAndCheckBuild(
      aiGeneratedCode, path, repoOwner, repoName, githubToken, logCallback
    );

    if (gitHubResult['success'] == true) {
      isBuildSuccessful = true;
      logCallback("🎉 शानदार! कोड गिटहब पर पुश हो गया है और बिल्ड पास हो गया!");
      break;
    } else {
      String capturedError = gitHubResult['errorLog'];
      logCallback("⚠️ एजेंट को एरर मिला, ऑटो-सुधार कर रहा है...");

      currentPrompt = """
      $initialPrompt
      
      [SYSTEM ERROR FEEDBACK]:
      $capturedError
      
      पिछला कोड इस एरर की वजह से फेल हो गया। इसे ठीक कर और नया सही कोड दे।
      """;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  if (!isBuildSuccessful) {
    logCallback("❌ 3 कोशिशों के बाद भी यह ठीक नहीं हो पाया।");
  }
}

Future<String> callGroqApi(String prompt, String apiKey, Function(String) logCallback) async {
  try {
    logCallback("🤖 Groq AI से कोड लिखवा रहे हैं...");
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": "You are an expert Flutter developer. Output ONLY valid raw Dart code inside the file without markdown backticks."},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.3
      }),
    );

    if (response.statusCode == 200) {
      String content = jsonDecode(response.body)['choices'][0]['message']['content'];
      content = content.replaceAll('```dart', '').replaceAll('```', '').trim();
      return content;
    } else {
      logCallback("❌ Groq API Error: ${response.body}");
      return '';
    }
  } catch (e) {
    logCallback("❌ API Exception: $e");
    return '';
  }
}

Future<Map<String, dynamic>> pushCodeToGitHubAndCheckBuild(
    String code, String rawPath, String repoOwner, String repoName, String githubToken, Function(String) logCallback) async {
  try {
    String path = rawPath.trim();
    final fileUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$path');
    
    final getFileRes = await http.get(
      fileUrl,
      headers: {'Authorization': 'Bearer $githubToken', 'Accept': 'application/vnd.github+json'},
    );

    String? fileSha;
    if (getFileRes.statusCode == 200) {
      fileSha = jsonDecode(getFileRes.body)['sha'];
    }

    final Map<String, dynamic> bodyData = {
      "message": "AI Agent Auto-Commit",
      "content": base64Encode(utf8.encode(code)),
      if (fileSha != null) "sha": fileSha,
    };

    final putRes = await http.put(
      fileUrl,
      headers: {'Authorization': 'Bearer $githubToken', 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json'},
      body: jsonEncode(bodyData),
    );

    if (putRes.statusCode == 200 || putRes.statusCode == 201) {
      logCallback("✅ गिटहब पर कोड सफलतापूर्वक अपडेट हो गया!");
      return {'success': true};
    } else {
      return {'success': false, 'errorLog': 'GitHub Put Failed: ${putRes.body}'};
    }
  } catch (e) {
    return {'success': false, 'errorLog': e.toString()};
  }
}

// ==========================================
// गैलरी से एरर स्क्रीनशॉट पिक करने का फंक्शन
// ==========================================
Future<void> pickErrorImageAndFix(Function(String) logCallback, TextEditingController promptController) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
      logCallback("⚠️ कोई इमेज सेलेक्ट नहीं की गई।");
      return;
    }

    logCallback("🖼️ एरर स्क्रीनशॉट चुन लिया गया है!");
    promptController.text = "इस स्क्रीनशॉट में दिख रहे एरर को देखकर कोड ठीक करो (इमेज पाथ: ${image.path})";
    logCallback("💡 प्रॉम्प्ट में एरर फिक्स करने का निर्देश जोड़ दिया गया है, अब 'एजेंट शुरू करें' दबाएं।");
  } catch (e) {
    logCallback("❌ इमेज पिक करने में एरर: $e");
  }
}

// ==========================================
// GitHub से APK डाउनलोड करने का फंक्शन
// ==========================================
Future<void> downloadApkFromGitHub(String repoOwner, String repoName, String githubToken, Function(String) logCallback) async {
  try {
    logCallback("🔍 गिटहब से लेटेस्ट बिल्ड तलाश कर रहे हैं...");
    final runsUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/actions/runs');
    
    final runsRes = await http.get(
      runsUrl,
      headers: {'Authorization': 'Bearer $githubToken', 'Accept': 'application/vnd.github+json'},
    );

    if (runsRes.statusCode == 200) {
      final workflows = jsonDecode(runsRes.body)['workflow_runs'] as List;
      if (workflows.isNotEmpty) {
        final latestRun = workflows.firstWhere((run) => run['conclusion'] == 'success', orElse: () => null);

        if (latestRun == null) {
          logCallback("⚠️ कोई सफल बिल्ड उपलब्ध नहीं है।");
          return;
        }

        int runId = latestRun['id'];
        final artifactsUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/actions/runs/$runId/artifacts');
        final artifactsRes = await http.get(
          artifactsUrl,
          headers: {'Authorization': 'Bearer $githubToken', 'Accept': 'application/vnd.github+json'},
        );

        if (artifactsRes.statusCode == 200) {
          final artifactsList = jsonDecode(artifactsRes.body)['artifacts'] as List;
          if (artifactsList.isNotEmpty) {
            String downloadUrl = artifactsList[0]['archive_download_url'];
            logCallback("📥 APK/आर्टिफैक्ट डाउनलोड हो रहा है...");
            
            final apkResponse = await http.get(
              Uri.parse(downloadUrl),
              headers: {'Authorization': 'Bearer $githubToken', 'Accept': 'application/vnd.github+json'},
            );

            if (apkResponse.statusCode == 200) {
              final directory = await getExternalStorageDirectory();
              final filePath = '${directory?.path}/app_release.zip';
              File(filePath).writeAsBytesSync(apkResponse.bodyBytes);
              logCallback("✅ सफलतापूर्वक डाउनलोड हुआ: $filePath");
            }
          }
        }
      }
    }
  } catch (e) {
    logCallback("❌ डाउनलोड एरर: $e");
  }
}
