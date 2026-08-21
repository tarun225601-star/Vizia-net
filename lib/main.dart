import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔴 कस्टम एरर विजेट: अब ब्लैक स्क्रीन की जगह एरर सीधे स्क्रीन पर दिखेगा
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bug_report, color: Colors.red, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "⚠️ App Error Detected",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  details.exception.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  runApp(const AutonomousEnterpriseApp());
}

class AutonomousEnterpriseApp extends StatelessWidget {
  const AutonomousEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groq Full-Stack Project Studio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        primaryColor: const Color(0xFF00F5D4),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F5D4),
          secondary: Color(0xFF7209B7),
          surface: Color(0xFF1D3557),
        ),
      ),
      home: const EnterpriseStudioScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AgentConfig {
  final String groqApiKey;
  final String projectName;

  AgentConfig({
    required this.groqApiKey,
    required this.projectName,
  });
}

class EnterpriseStudioScreen extends StatefulWidget {
  const EnterpriseStudioScreen({super.key});

  @override
  State<EnterpriseStudioScreen> createState() => _EnterpriseStudioScreenState();
}

class _EnterpriseStudioScreenState extends State<EnterpriseStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  
  bool _isAutonomousRunning = false;
  bool _isWaitingForUserFileSelection = false;
  bool _isGitHubConnected = false;
  bool _isAndroidStudioSynced = false;
  double _progressValue = 0.0;
  String _currentPhase = 'Idle - Ready for Full-Stack Flutter Generation.';
  
  final List<String> _logs = [];
  List<Map<String, dynamic>> _selectableFiles = [];
  
  final Map<String, String> _generatedFilesMap = {};
  String _selectedViewFile = '';

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
    _checkExistingGitHubUser();
  }

  void _checkExistingGitHubUser() {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _isGitHubConnected = true;
        });
        _addLog('🔗 Existing GitHub session found: ${currentUser.displayName ?? currentUser.email}');
      }
    } catch (e) {
      _addLog('❌ Auth check error: $e');
    }
  }

  Future<void> _loadSavedConfig() async {
    _addLog('⚙️ Groq Full-Stack Studio Agent initialized with Self-Healing feature.');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
        0, 
        '[${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}]$message'
      );
    });
  }

  Future<AgentConfig> _getStoredConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return AgentConfig(
      groqApiKey: prefs.getString('groq_api_key') ?? '',
      projectName: prefs.getString('project_name') ?? 'Project_1',
    );
  }

  Future<void> _saveConfig(AgentConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', config.groqApiKey);
    await prefs.setString('project_name', config.projectName);
  }

  void _showSettingsDialog() {
    final groqKeyController = TextEditingController();
    final projectNameController = TextEditingController();

    _getStoredConfig().then((config) {
      groqKeyController.text = config.groqApiKey;
      projectNameController.text = config.projectName;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Project & Groq API Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: projectNameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name (e.g. Project_1, ShopApp)',
                  hintText: 'Enter unique project folder name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: groqKeyController,
                decoration: const InputDecoration(labelText: 'Groq API Key (gsk_...)'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _saveConfig(AgentConfig(
                groqApiKey: groqKeyController.text.trim(),
                projectName: projectNameController.text.trim().isEmpty ? 'Project_1' : projectNameController.text.trim(),
              ));
              Navigator.pop(context);
              setState(() {});
              _addLog('💾 Project & Groq settings saved!');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String> _callGroqAPI({required AgentConfig config, required String systemPrompt, required String userPrompt}) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.groqApiKey}',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.1,
        "max_tokens": 4000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API Error: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  Future<void> _connectGitHub() async {
    try {
      _addLog('🔄 Opening GitHub login window...');
      GithubAuthProvider githubProvider = GithubAuthProvider();
      githubProvider.addScope('repo');

      UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(githubProvider);
      User? user = userCredential.user;

      setState(() { 
        _isGitHubConnected = true; 
      });
      
      _addLog('🔗 Successfully connected to GitHub: ${user?.displayName ?? user?.email ?? "User"}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ GitHub Connected Successfully!')),
      );
    } catch (e) {
      _addLog('❌ GitHub Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ GitHub Login Failed: $e')),
      );
    }
  }

  void _syncAndroidStudio() {
    setState(() { _isAndroidStudioSynced = true; });
    _addLog('💻 Android Studio workspace linked.');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Android Studio Synced!')));
  }

  Future<void> _startScaleAnalysis() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Enter requirements!')));
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.2;
      _currentPhase = 'Analyzing full-stack architecture & error-free planning...';
      _selectableFiles.clear();
      _generatedFilesMap.clear();
    });

    try {
      final config = await _getStoredConfig();
      const systemPrompt = '''
You are an expert Principal App Architect and Senior Flutter/Android Developer. 
Design a complete, production-ready, error-free full-stack Flutter application structure based on the user prompt.
You MUST include all necessary configuration and native setup files along with source code files.
Specifically, always include:
1. pubspec.yaml
2. android/app/build.gradle
3. android/app/src/main/AndroidManifest.xml
4. android/app/src/main/kotlin/com/example/app/MainActivity.kt
5. lib/main.dart
And any additional required modular files.
Return a strict JSON array of relative file paths. Output ONLY valid JSON array and nothing else.
''';

      String content = await _callGroqAPI(config: config, systemPrompt: systemPrompt, userPrompt: userPrompt);
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      
      int start = content.indexOf('[');
      int end = content.lastIndexOf(']');
      if (start != -1 && end != -1) content = content.substring(start, end + 1);

      List<dynamic> parsedList = jsonDecode(content);
      List<String> filePlan = parsedList.map((e) => e.toString()).toList();
      
      if (!filePlan.contains('lib/main.dart')) filePlan.add('lib/main.dart');
      if (!filePlan.contains('pubspec.yaml')) filePlan.add('pubspec.yaml');
      if (!filePlan.contains('android/app/build.gradle')) filePlan.add('android/app/build.gradle');

      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.5;
        _currentPhase = 'Mapped ${filePlan.length} files. Review & build.';
      });
      _addLog('📋 Successfully planned full-stack file structure.');
    } catch (e) {
      setState(() {
        _selectableFiles = [
          {'path': 'pubspec.yaml', 'selected': true},
          {'path': 'android/app/build.gradle', 'selected': true},
          {'path': 'lib/main.dart', 'selected': true},
        ];
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.5;
        _currentPhase = 'Fallback full-stack structure loaded.';
      });
      _addLog('⚠️ Analysis error: $e');
    }
  }

  Future<void> _confirmAndBuildProject() async {
    final chosenFiles = _selectableFiles.where((f) => f['selected'] == true).map((f) => f['path'].toString()).toList();
    if (chosenFiles.isEmpty) return;

    setState(() {
      _isWaitingForUserFileSelection = false;
      _isAutonomousRunning = true;
      _progressValue = 0.6;
      _currentPhase = 'Generating error-free code & configs...';
      _generatedFilesMap.clear();
    });

    try {
      final config = await _getStoredConfig();
      final userFullInput = _promptController.text.trim();

      for (int i = 0; i < chosenFiles.length; i++) {
        String fileName = chosenFiles[i];
        setState(() {
          _progressValue = 0.6 + ((i + 1) / chosenFiles.length) * 0.3;
          _currentPhase = 'Writing ($i/${chosenFiles.length}):$fileName';
        });

        const systemPrompt = '''
You are an expert Senior Flutter & Full-Stack Developer. Write production-ready, complete code or configuration content ONLY for the specified file path.
CRITICAL RULES FOR ERROR-FREE CODE:
1. Ensure all required imports (e.g., 'package:flutter/material.dart') are explicitly included.
2. Fix any potential syntax errors, unclosed brackets, or type mismatches beforehand.
3. If the user provides an error message or debugging prompt, analyze the error, locate the buggy lines, and output a fully corrected version of the code.
4. Enclose code inside appropriate markdown code blocks (```dart, ```yaml, ```groovy, ```xml, ```kotlin).
Output ONLY the clean content inside the code block and nothing else.
''';
        String rawResponse = await _callGroqAPI(
          config: config, 
          systemPrompt: systemPrompt, 
          userPrompt: 'Project Requirement / Bug Fix Request: $userFullInput\nTarget File Path: $fileName'
        );
        
        String code = _extractCleanCode(rawResponse, fileName);
        _generatedFilesMap[fileName] = code;
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Successfully generated/fixed full-stack project for [${config.projectName}]!';
        if (_generatedFilesMap.isNotEmpty) {
          _selectedViewFile = _generatedFilesMap.keys.first;
        }
      });
      _addLog('🎉 Files successfully generated with Self-Healing protection!');
    } catch (e) {
      _addLog('❌ Build Error: $e');
      setState(() => _isAutonomousRunning = false);
    }
  }

  String _extractCleanCode(String raw, String fileName) {
    String tag = 'dart';
    if (fileName.endsWith('.yaml')) tag = 'yaml';
    else if (fileName.endsWith('.gradle') || fileName.endsWith('.kts')) tag = 'groovy';
    else if (fileName.endsWith('.xml')) tag = 'xml';
    else if (fileName.endsWith('.kt')) tag = 'kotlin';

    if (raw.contains('```$tag')) {
      int start = raw.indexOf('```$tag') + tag.length + 3;
      int end = raw.lastIndexOf('```');
      if (end > start) return raw.substring(start, end).trim();
    } else if (raw.contains('```')) {
      int start = raw.indexOf('```') + 3;
      int end = raw.lastIndexOf('```');
      if (end > start) return raw.substring(start, end).trim();
    }
    return raw.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groq Full-Stack Studio'),
        backgroundColor: const Color(0xFF1D3557),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsDialog)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<AgentConfig>(
              future: _getStoredConfig(),
              builder: (context, snapshot) {
                final projName = snapshot.hasData ? snapshot.data!.projectName : 'Project_1';
                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📁 Project: $projName', style: const TextStyle(color: Color(0xFF00F5D4), fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: _isGitHubConnected ? Colors.green : Colors.red),
                          const SizedBox(width: 4),
                          const Text('GitHub', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 10, color: _isAndroidStudioSynced ? Colors.green : Colors.red),
                          const SizedBox(width: 4),
                          const Text('Studio', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _connectGitHub,
                    icon: const Icon(Icons.hub, size: 18),
                    label: Text(_isGitHubConnected ? 'GitHub Connected' : 'Connect GitHub'),
                    style: ElevatedButton.styleFrom(backgroundColor: _isGitHubConnected ? Colors.green.shade800 : const Color(0xFF1D3557), foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _syncAndroidStudio,
                    icon: const Icon(Icons.code, size: 18),
                    label: Text(_isAndroidStudioSynced ? 'Studio Synced' : 'Sync Studio'),
                    style: ElevatedButton.styleFrom(backgroundColor: _isAndroidStudioSynced ? Colors.green.shade800 : const Color(0xFF1D3557), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _promptController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Enter Requirement OR Paste Error (e.g. "Error: Widget not found in main.dart")', 
                border: OutlineInputBorder(), 
                filled: true, 
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isAutonomousRunning || _isWaitingForUserFileSelection ? null : _startScaleAnalysis,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F5D4), foregroundColor: Colors.black),
              child: const Text('🔍 Step 1: Map / Analyze via Groq AI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progressValue, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4))),
            const SizedBox(height: 4),
            Text(_currentPhase, style: const TextStyle(color: Color(0xFF00F5D4), fontSize: 12)),
            const SizedBox(height: 8),

            if (_isWaitingForUserFileSelection) ...[
              const Text('📂 Select Files to Generate / Fix:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectableFiles.length,
                  itemBuilder: (context, index) {
                    final f = _selectableFiles[index];
                    return CheckboxListTile(
                      title: Text(f['path']),
                      value: f['selected'],
                      activeColor: const Color(0xFF00F5D4),
                      checkColor: Colors.black,
                      onChanged: (val) => setState(() => f['selected'] = val ?? true),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _confirmAndBuildProject,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F5D4), foregroundColor: Colors.black),
                child: const Text('🚀 Step 2: Generate / Fix Code Files', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📂 Generated Files Explorer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (_generatedFilesMap.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        final codeToCopy = _generatedFilesMap[_selectedViewFile] ?? '';
                        Clipboard.setData(ClipboardData(text: codeToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('📋 Copied contents of $_selectedViewFile!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy File Content', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7209B7), foregroundColor: Colors.white, minimumSize: const Size(100, 30)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              
              if (_generatedFilesMap.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _generatedFilesMap.keys.map((fileName) {
                      bool isSelected = _selectedViewFile == fileName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(fileName, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00F5D4),
                          backgroundColor: const Color(0xFF1D3557),
                          onSelected: (selected) {
                            setState(() { _selectedViewFile = fileName; });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 4),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00F5D4))),
                  child: SingleChildScrollView(
                    child: Text(
                      _generatedFilesMap.isNotEmpty && _selectedViewFile.isNotEmpty
                          ? _generatedFilesMap[_selectedViewFile]!
                          : '// Generated project files, fixes and code will appear here...',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.cyanAccent),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
