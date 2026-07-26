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
  String? _selectedImagePath; // चुनी गई इमेज का रास्ता स्टोर करने के लिए

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, "[${TimeOfDay.now().format(context)}] $message");
    });
  }

  // एजेंटिक लूप स्टार्ट करने वाला बटन फंक्शन
  Future<void> _startProcess() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty && _selectedImagePath == null) {
      _addLog("⚠️ कृपया पहले कोई प्रॉम्प्ट दर्ज करें या एरर स्क्रीनशॉट चुनें!");
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

    await startAgenticLoop(
      prompt: prompt.isEmpty ? "इस स्क्रीनशॉट में दिए गए एरर को देखकर Flutter कोड को पूरी तरह ठीक करो।" : prompt, 
      imagePath: _selectedImagePath,
      path: 'lib/generated_app.dart', 
      repoOwner: repoOwner, 
      repoName: repoName, 
      githubToken: githubToken, 
      groqKey: groqKey, 
      logCallback: _addLog
    );

    // काम पूरा होने पर इमेज पाथ साफ़ कर दें
    setState(() {
      _selectedImagePath = null;
      _isLoading = false;
    });
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
              decoration: InputDecoration(
                labelText: 'आप क्या ऐप बनवाना चाहते हैं या एरर सुधारना है?',
                border: const OutlineInputBorder(),
                suffixIcon: _selectedImagePath != null 
                    ? const Icon(Icons.check_circle, color: Colors.green) 
                    : null,
              ),
            ),
            if (_selectedImagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "📷 स्क्रीनशॉट जुड़ा हुआ है: ${_selectedImagePath!.split('/').last}",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
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
                // इमेज पिकर बटन (अब यह इमेज को एआई के पास भेजेगा)
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                  icon: const Icon(Icons.image, color: Colors.greenAccent),
                  tooltip: 'एरर स्क्रीनशॉट अपलोड करें',
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _selectedImagePath = image.path;
                      });
                      _addLog("🖼️ एरर स्क्रीनशॉट सेलेक्ट हो गया है! अब 'एजेंट शुरू करें' दबाएं।");
                    }
                  },
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
// एजेंटिक लूप और लॉजिक फंक्शन्स (Vision Enabled)
// ==========================================
Future<void> startAgenticLoop({
  required String prompt,
  String? imagePath,
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
    logCallback("🔄 कोशिश नंबर $attempt जारी है...");

    // अब यह विजन API को कॉल करेगा ताकि इमेज और टेक्स्ट दोनों समझ आ सकें
    String aiGeneratedCode = await callGroqVisionApi(
      prompt: currentPrompt, 
      imagePath: attempt == 1 ? imagePath : null, // पहली कोशिश में इमेज साथ जाएगी
      apiKey: groqKey, 
      logCallback: logCallback
    );
    
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
      logCallback("⚠️ एजेंट को बिल्ड एरर मिला, ऑटो-सुधार कर रहा है...");

      currentPrompt = """
      $prompt
      
      [SYSTEM BUILD ERROR FEEDBACK]:
      $capturedError
      
      पिछला कोड इस एरर की वजह से फेल हो गया। इसे पूरी तरह ठीक कर और नया सही raw Dart कोड दे।
      """;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  if (!isBuildSuccessful) {
    logCallback("❌ 3 कोशिशों के बाद भी यह ठीक नहीं हो पाया।");
  }
}

// Groq Vision API कॉल करने का फंक्शन (जो इमेज और टेक्स्ट दोनों पढ़ेगा)
Future<String> callGroqVisionApi({
  required String prompt,
  String? imagePath,
  required String apiKey,
  required Function(String) logCallback,
}) async {
  try {
    logCallback("🤖 Groq AI (Vision) से कोड विश्लेषण और सुधार करवा रहे हैं...");
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    List<dynamic> contentList = [
      {
        "type": "text",
        "text": "You are an expert Flutter developer. Output ONLY valid raw Dart code inside the file without markdown backticks. $prompt"
      }
    ];

    // अगर यूजर ने स्क्रीनशॉट दिया है, तो उसे Base64 में बदलकर विजन मॉडल को भेजें
    if (imagePath != null && File(imagePath).existsSync()) {
      logCallback("🖼️ एरर स्क्रीनशॉट को एआई विजन के पास भेजा जा रहा है...");
      List<int> imageBytes = File(imagePath).readAsBytesSync();
      String base64Image = base64Encode(imageBytes);
      contentList.add({
        "type": "image_url",
        "image_url": {
          "url": "data:image/jpeg;base64,$base64Image"
        }
      });
    }

    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": "meta-llama/llama-3.2-90b-vision-preview", // विजन मॉडल का उपयोग
        "messages": [
          {
            "role": "user",
            "content": contentList
          }
        ],
        "temperature": 0.3,
        "max_tokens": 4096
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
      "message": "AI Agent Auto-Commit (Vision Fixed)",
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
