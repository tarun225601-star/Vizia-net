import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MasterBoxApp());

class MasterBoxApp extends StatelessWidget {
  const MasterBoxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Master Box - GitHub CI/CD Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        primaryColor: Colors.cyanAccent,
      ),
      home: const MasterHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// प्रोजेक्ट फाइल मॉडल
// ==========================================
class ProjectFileItem {
  final String fileName;
  final String fileCode;

  ProjectFileItem({required this.fileName, required this.fileCode});

  Map<String, dynamic> toJson() => {'fileName': fileName, 'fileCode': fileCode};

  factory ProjectFileItem.fromJson(Map<String, dynamic> json) => ProjectFileItem(
        fileName: json['fileName'] ?? 'file.dart',
        fileCode: json['fileCode'] ?? '',
      );
}

class SavedProject {
  final String projectTitle;
  final String timestamp;
  final List<ProjectFileItem> files;
  final String githubRepoUrl;

  SavedProject({
    required this.projectTitle,
    required this.timestamp,
    required this.files,
    required this.githubRepoUrl,
  });

  Map<String, dynamic> toJson() => {
        'projectTitle': projectTitle,
        'timestamp': timestamp,
        'files': files.map((f) => f.toJson()).toList(),
        'githubRepoUrl': githubRepoUrl,
      };

  factory SavedProject.fromJson(Map<String, dynamic> json) {
    var rawFiles = json['files'] as List? ?? [];
    List<ProjectFileItem> parsedFiles = rawFiles.map((f) => ProjectFileItem.fromJson(f)).toList();
    return SavedProject(
      projectTitle: json['projectTitle'] ?? 'Project',
      timestamp: json['timestamp'] ?? '',
      files: parsedFiles,
      githubRepoUrl: json['githubRepoUrl'] ?? '',
    );
  }
}

// ==========================================
// 1. सेटिंग्स स्क्रीन
// ==========================================
class MasterSettingsScreen extends StatefulWidget {
  const MasterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MasterSettingsScreen> createState() => _MasterSettingsScreenState();
}

class _MasterSettingsScreenState extends State<MasterSettingsScreen> {
  final TextEditingController _groqKeyController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _githubUsernameController = TextEditingController();
  final TextEditingController _repoNameController = TextEditingController();
  List<SavedProject> savedProjectsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groqKeyController.text = prefs.getString('groq_key') ?? '';
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _githubUsernameController.text = prefs.getString('github_username') ?? '';
      _repoNameController.text = prefs.getString('github_repo_name') ?? '';
      List<String> rawList = prefs.getStringList('saved_projects_vault_v6') ?? [];
      savedProjectsList = rawList.map((item) => SavedProject.fromJson(jsonDecode(item))).toList();
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', _groqKeyController.text.trim());
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('github_username', _githubUsernameController.text.trim());
    await prefs.setString('github_repo_name', _repoNameController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ सेटिंग्स सफलतापूर्वक सेव हो गई हैं!')),
    );
  }

  Future<void> _deleteProject(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedProjectsList.removeAt(index);
    });
    List<String> rawList = savedProjectsList.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('saved_projects_vault_v6', rawList);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ प्रोजेक्ट हटा दिया गया है।')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub CI/CD सेटिंग्स'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _groqKeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Groq Cloud API Key',
                prefixIcon: Icon(Icons.bolt, color: Colors.cyanAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _githubUsernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'GitHub Username',
                prefixIcon: Icon(Icons.person, color: Colors.amberAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Target GitHub Repository Name (जहाँ कोड जाएगा)',
                prefixIcon: Icon(Icons.folder, color: Colors.greenAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _githubTokenController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'GitHub Personal Access Token (PAT)',
                prefixIcon: Icon(Icons.code, color: Colors.cyanAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              onPressed: _saveKeys,
              icon: const Icon(Icons.save),
              label: const Text('सेटिंग्स सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              '📦 पुरानी हिस्ट्री:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
            const SizedBox(height: 10),
            ...savedProjectsList.asMap().entries.map((entry) {
              int projIndex = entry.key;
              final project = entry.value;
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project.projectTitle,
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteProject(projIndex),
                          ),
                        ],
                      ),
                      if (project.githubRepoUrl.isNotEmpty)
                        Text('🔗 Repo: ${project.githubRepoUrl}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                      Text('समय: ${project.timestamp}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. होम स्क्रीन & ऑटोमेशन इंजन
// ==========================================
class MasterHomePage extends StatefulWidget {
  const MasterHomePage({Key? key}) : super(key: key);

  @override
  State<MasterHomePage> createState() => _MasterHomePageState();
}

class _MasterHomePageState extends State<MasterHomePage> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Build a fully working Flutter calculator app with nice UI',
  );

  bool isProcessing = false;
  String statusMessage = 'तैयार है...';
  String currentRepoUrl = '';
  List<ProjectFileItem> currentFiles = [];

  // क्रैश रोकने के लिए फुलप्रूफ JSON क्लीनर
  String _cleanJsonString(String input) {
    if (input.contains('```json')) {
      input = input.split('```json')[1].split('```')[0];
    } else if (input.contains('```')) {
      input = input.split('```')[1].split('```')[0];
    }
    input = input.trim();
    input = input.replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '');
    return input;
  }

  // गिटहब पर रिपॉजिटरी चेक करना, फाइलें भेजना और Actions ट्रिगर करना
  Future<String> _pushFilesToFixedRepo(List<ProjectFileItem> files) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('github_token') ?? '';
    final username = prefs.getString('github_username') ?? '';
    final repoName = prefs.getString('github_repo_name') ?? '';

    if (token.isEmpty || username.isEmpty || repoName.isEmpty) {
      throw Exception('GitHub Token, Username या Repo Name सेटिंग्स में अधूरा है!');
    }

    // 1. रिपॉजिटरी चेक करें, अगर न हो तो बनाएं
    final repoCheckUrl = Uri.parse('https://api.github.com/repos/$username/$repoName');
    final checkResponse = await http.get(repoCheckUrl, headers: {'Authorization': 'Bearer $token'});

    if (checkResponse.statusCode == 404) {
      final createRepoUrl = Uri.parse('https://api.github.com/user/repos');
      await http.post(
        createRepoUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': repoName,
          'description': 'Automated Flutter App Builder by Master Box',
          'private': false,
          'auto_init': true,
        }),
      );
    }

    // 2. सभी फाइलों (और .github/workflows/flutter.yml) को पुश/अपडेट करें
    for (var file in files) {
      // पाथ ठीक से सेट करें (जैसे subfolders के लिए)
      final filePath = file.fileName.trim();
      final fileUrl = Uri.parse('https://api.github.com/repos/$username/$repoName/contents/$filePath');
      
      String? fileSha;
      final getCheck = await http.get(fileUrl, headers: {'Authorization': 'Bearer $token'});
      if (getCheck.statusCode == 200) {
        fileSha = jsonDecode(getCheck.body)['sha'];
      }

      String encodedContent = base64Encode(utf8.encode(file.fileCode));

      Map<String, dynamic> bodyData = {
        'message': 'CI/CD AI Agent: Update $filePath',
        'content': encodedContent,
      };
      if (fileSha != null) {
        bodyData['sha'] = fileSha;
      }

      await http.put(
        fileUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );
    }

    return 'https://github.com/$username/$repoName/actions';
  }

  Future<void> _runEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_key') ?? '';

    if (groqKey.isEmpty) {
      setState(() => statusMessage = '❌ त्रुटि: सेटिंग्स में Groq API Key दर्ज करें!');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      isProcessing = true;
      statusMessage = '🔄 AI ऐप कोड और Build Actions फाइल बना रहा है...';
      currentFiles.clear();
    });

    try {
      // Groq API से पूरा Flutter प्रोजेक्ट और GitHub Actions स्क्रिप्ट मांग रहे हैं
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": """You are an elite Flutter & DevOps Architect. 
Generate a complete working Flutter project structure based on user prompt.
You MUST include these files:
1. "lib/main.dart" (Complete executable app)
2. "pubspec.yaml" (Valid dependencies)
3. ".github/workflows/flutter.yml" (GitHub action script to build APK: triggers on push, uses subosito/flutter-action, runs flutter build apk --release, and uploads artifact).

Return ONLY a valid JSON object in this exact format without any markdown wrappers:
{
  "files": [
    {"fileName": "lib/main.dart", "fileCode": "...code..."},
    {"fileName": "pubspec.yaml", "fileCode": "...code..."},
    {"fileName": ".github/workflows/flutter.yml", "fileCode": "name: Build APK\non: [push]\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v3\n      - uses: subosito/flutter-action@v2\n        with:\n          flutter-version: '3.x'\n      - run: flutter pub get\n      - run: flutter build apk --release\n      - uses: actions/upload-artifact@v3\n        with:\n          name: release-apk\n          path: build/app/outputs/flutter-apk/app-release.apk"}
  ]
}"""
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.4,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawContent = data['choices'][0]['message']['content'];
        String cleanedJsonStr = _cleanJsonString(rawContent);

        final parsedJson = jsonDecode(cleanedJsonStr);
        final List<dynamic> fileListJson = parsedJson['files'] ?? [];
        List<ProjectFileItem> fetchedFiles = fileListJson.map((f) => ProjectFileItem.fromJson(f)).toList();

        setState(() => statusMessage = '☁️ गिटहब पर कोड पुश हो रहा है और बिल्ड शुरू हो रही है...');

        // गिटहब पर पुश करें
        String actionsUrl = '';
        try {
          actionsUrl = await _pushFilesToFixedRepo(fetchedFiles);
        } catch (e) {
          actionsUrl = 'GitHub Push Error: $e';
        }

        // हिस्ट्री सेव करें
        List<String> rawList = prefs.getStringList('saved_projects_vault_v6') ?? [];
        List<SavedProject> existingProjects = rawList.map((item) => SavedProject.fromJson(jsonDecode(item))).toList();
        
        int nextNum = existingProjects.length + 1;
        String shortTitle = prompt.length > 20 ? '${prompt.substring(0, 20)}...' : prompt;
        SavedProject newProj = SavedProject(
          projectTitle: 'Project #$nextNum: $shortTitle',
          timestamp: TimeOfDay.fromDateTime(DateTime.now()).format(context),
          files: fetchedFiles,
          githubRepoUrl: actionsUrl,
        );
        existingProjects.insert(0, newProj);
        await prefs.setStringList('saved_projects_vault_v6', existingProjects.map((item) => jsonEncode(item.toJson())).toList());

        setState(() {
          currentFiles = fetchedFiles;
          currentRepoUrl = actionsUrl;
          isProcessing = false;
          statusMessage = '✅ काम हो गया! GitHub Actions पर APK बनना शुरू हो गया है।';
        });
      } else {
        setState(() {
          isProcessing = false;
          statusMessage = '⚠️ API Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        statusMessage = '⚠️ एरर: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('मास्टर बॉक्स - APK CI/CD Builder'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MasterSettingsScreen()),
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
            const Text('ऐप बनवाने के लिए प्रॉम्ट लिखें:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _promptController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                onPressed: isProcessing ? null : _runEngine,
                icon: isProcessing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.rocket_launch),
                label: Text(isProcessing ? 'बिल्ड प्रोसेस जारी है...' : '⚡ ऐप बनाओ और APK बिल्ड चलाओ', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Text(statusMessage, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
            if (currentRepoUrl.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('🔗 Actions Link (यहाँ APK मिलेगा): $currentRepoUrl', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
            ],
            const SizedBox(height: 12),
            const Text('📁 जनरेटेड प्रोजेक्ट फाइलें:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Expanded(
              child: currentFiles.isEmpty
                  ? const Center(child: Text('// यहाँ कोड फाइलें दिखेंगी...', style: TextStyle(color: Colors.white54, fontSize: 12)))
                  : ListView.builder(
                      itemCount: currentFiles.length,
                      itemBuilder: (context, index) {
                        final file = currentFiles[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📄 ${file.fileName}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 50,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      file.fileCode,
                                      style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
