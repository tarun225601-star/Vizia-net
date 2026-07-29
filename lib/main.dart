import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MasterBoxApp());

class MasterBoxApp extends StatelessWidget {
  const MasterBoxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Master Box Pro',
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
// मॉडल: हर प्रोजेक्ट की अलग-अलग फाइलें और डाटा
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
  final String previewHtml;

  SavedProject({
    required this.projectTitle,
    required this.timestamp,
    required this.files,
    required this.previewHtml,
  });

  Map<String, dynamic> toJson() => {
        'projectTitle': projectTitle,
        'timestamp': timestamp,
        'files': files.map((f) => f.toJson()).toList(),
        'previewHtml': previewHtml,
      };

  factory SavedProject.fromJson(Map<String, dynamic> json) {
    var rawFiles = json['files'] as List? ?? [];
    List<ProjectFileItem> parsedFiles = rawFiles.map((f) => ProjectFileItem.fromJson(f)).toList();
    return SavedProject(
      projectTitle: json['projectTitle'] ?? 'Project',
      timestamp: json['timestamp'] ?? '',
      files: parsedFiles,
      previewHtml: json['previewHtml'] ?? '',
    );
  }
}

// ==========================================
// 1. सेटिंग्स स्क्रीन (अलग प्रोजेक्ट्स और उनकी अलग फाइलों का वॉल्ट)
// ==========================================
class MasterSettingsScreen extends StatefulWidget {
  const MasterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MasterSettingsScreen> createState() => _MasterSettingsScreenState();
}

class _MasterSettingsScreenState extends State<MasterSettingsScreen> {
  final TextEditingController _groqKeyController = TextEditingController();
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
      List<String> rawList = prefs.getStringList('saved_projects_vault_v3') ?? [];
      savedProjectsList = rawList.map((item) => SavedProject.fromJson(jsonDecode(item))).toList();
    });
  }

  Future<void> _saveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', _groqKeyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Groq API Key सुरक्षित हो गई है!')),
    );
  }

  Future<void> _deleteProject(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedProjectsList.removeAt(index);
    });
    List<String> rawList = savedProjectsList.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('saved_projects_vault_v3', rawList);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ प्रोजेक्ट डिलीट कर दिया गया है।')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('लोकल सेटिंग्स और फाइल कोड वॉल्ट'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              onPressed: _saveKey,
              icon: const Icon(Icons.save),
              label: const Text('की सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              '📦 सहेजे गए प्रोजेक्ट्स और उनकी अलग-अलग फाइलें:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: savedProjectsList.isEmpty
                  ? const Center(child: Text('कोई प्रोजेक्ट सेव नहीं है।', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: savedProjectsList.length,
                      itemBuilder: (context, projIndex) {
                        final project = savedProjectsList[projIndex];
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
                                    Text(
                                      project.projectTitle,
                                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () => _deleteProject(projIndex),
                                    ),
                                  ],
                                ),
                                Text('समय: ${project.timestamp}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                const SizedBox(height: 8),
                                const Text('📁 इस प्रोजेक्ट की फाइलें:', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                ...project.files.map((file) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('📄 ${file.fileName}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.cyanAccent,
                                                foregroundColor: Colors.black,
                                                minimumSize: const Size(60, 26),
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                              ),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: file.fileCode));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('📋 "${file.fileName}" का कोड कॉपी हो गया!')),
                                                );
                                              },
                                              icon: const Icon(Icons.copy, size: 12),
                                              label: const Text('कॉपी', style: TextStyle(fontSize: 10)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 60,
                                          child: SingleChildScrollView(
                                            child: Text(
                                              file.fileCode,
                                              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 9),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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

// ==========================================
// 2. फुल स्क्रीन वेब प्रीव्यू पेज
// ==========================================
class FullScreenPreviewPage extends StatelessWidget {
  final String htmlCode;
  final String appTitle;

  const FullScreenPreviewPage({Key? key, required this.htmlCode, required this.appTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

// ==========================================
// 3. होम स्क्रीन (मल्टी-फाइल मैनेजर + फुल स्क्रीन वेब प्रीव्यू)
// ==========================================
class MasterHomePage extends StatefulWidget {
  const MasterHomePage({Key? key}) : super(key: key);

  @override
  State<MasterHomePage> createState() => _MasterHomePageState();
}

class _MasterHomePageState extends State<MasterHomePage> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Build a modern responsive calculator app with HTML/CSS/JS',
  );

  bool isProcessing = false;
  String statusMessage = 'तैयार है...';
  bool showWebViewButton = false;
  String currentPreviewHtml = '';
  String currentProjectTitle = '';
  List<ProjectFileItem> currentFiles = [];

  Future<void> _runEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_key') ?? '';

    if (groqKey.isEmpty) {
      setState(() => statusMessage = '❌ त्रुटि: कृपया सेटिंग्स में जाकर Groq API Key दर्ज करें!');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      isProcessing = true;
      statusMessage = '🔄 एआई से अलग-अलग फाइलें और वेब प्रीव्यू तैयार हो रहा है...';
      showWebViewButton = false;
      currentFiles.clear();
    });

    try {
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
              "content": "You are an elite developer. Generate a multi-file project structure based on the prompt. Return ONLY a valid JSON object in this exact format without markdown blocks: {\"files\": [{\"fileName\": \"main.dart\", \"fileCode\": \"...\"}, {\"fileName\": \"pubspec.yaml\", \"fileCode\": \"...\"}], \"previewHtml\": \"... (fully styled responsive HTML/CSS/JS app for webview preview) ...\"}"
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawContent = data['choices'][0]['message']['content'];

        if (rawContent.contains('```json')) {
          rawContent = rawContent.split('```json')[1].split('```')[0];
        } else if (rawContent.contains('```')) {
          rawContent = rawContent.split('```')[1].split('```')[0];
        }
        rawContent = rawContent.trim();

        final parsedJson = jsonDecode(rawContent);
        final List<dynamic> fileListJson = parsedJson['files'] ?? [];
        List<ProjectFileItem> fetchedFiles = fileListJson.map((f) => ProjectFileItem.fromJson(f)).toList();
        String previewHtml = parsedJson['previewHtml'] ?? '<html><body style="background:#0F172A;color:white;text-align:center;padding-top:50px;"><h1>Preview Ready</h1></body></html>';

        // प्रोजेक्ट सेव करना
        List<String> rawList = prefs.getStringList('saved_projects_vault_v3') ?? [];
        List<SavedProject> existingProjects = rawList.map((item) => SavedProject.fromJson(jsonDecode(item))).toList();
        
        int nextNum = existingProjects.length + 1;
        String shortTitle = prompt.length > 20 ? '${prompt.substring(0, 20)}...' : prompt;
        String projTitle = 'Project #$nextNum: $shortTitle';
        String timeStr = TimeOfDay.fromDateTime(DateTime.now()).format(context);

        SavedProject newProj = SavedProject(
          projectTitle: projTitle,
          timestamp: timeStr,
          files: fetchedFiles,
          previewHtml: previewHtml,
        );
        existingProjects.insert(0, newProj);

        List<String> updatedRawList = existingProjects.map((item) => jsonEncode(item.toJson())).toList();
        await prefs.setStringList('saved_projects_vault_v3', updatedRawList);

        setState(() {
          currentFiles = fetchedFiles;
          currentPreviewHtml = previewHtml;
          currentProjectTitle = projTitle;
          isProcessing = false;
          showWebViewButton = true;
          statusMessage = '✅ "${projTitle}" की सभी फाइलें और वेब प्रीव्यू तैयार है!';
        });
      } else {
        setState(() {
          isProcessing = false;
          statusMessage = '⚠️ API एरर: ${response.statusCode}';
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
        title: const Text('मास्टर बॉक्स प्रो (मल्टी-फाइल + वेब प्रीव्यू)'),
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
            const Text('ऐप/प्रोजेक्ट प्रॉम्प्ट लिखें:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
                icon: isProcessing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bolt),
                label: Text(isProcessing ? 'फाइलें बनाई जा रही हैं...' : '⚡ प्रोजेक्ट फाइलें व वेब प्रीव्यू बनाएँ', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Text(statusMessage, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            
            // फुल स्क्रीन वेब व्यू बटन (अब हमेशा दिखेगा जब ऐप बन जाएगी)
            if (showWebViewButton) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenPreviewPage(
                          htmlCode: currentPreviewHtml,
                          appTitle: currentProjectTitle,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen, size: 28),
                  label: const Text('🚀 फुल स्क्रीन में वेब ऐप चलाकर देखें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const Text('📁 जनरेटेड प्रोजेक्ट फाइलें (अलग-अलग):', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Expanded(
              child: currentFiles.isEmpty
                  ? const Center(child: Text('// यहाँ प्रोजेक्ट की अलग-अलग फाइलें दिखेंगी...', style: TextStyle(color: Colors.white54, fontSize: 12)))
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('📄 ${file.fileName}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, minimumSize: const Size(70, 28)),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: file.fileCode));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('📋 "${file.fileName}" कॉपी हो गया!')),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 14),
                                      label: const Text('कॉपी', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 70,
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
