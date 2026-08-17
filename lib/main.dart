import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AutonomousEnterpriseApp());
}

class AutonomousEnterpriseApp extends StatelessWidget {
  const AutonomousEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autonomous Enterprise Studio',
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
  final String groqKey;
  final String anthropicKey;
  final String githubToken;
  final String githubUser;
  final String githubRepo;
  final String selectedModel;

  AgentConfig({
    required this.groqKey,
    required this.anthropicKey,
    required this.githubToken,
    required this.githubUser,
    required this.githubRepo,
    required this.selectedModel,
  });
}

class EnterpriseStudioScreen extends StatefulWidget {
  const EnterpriseStudioScreen({super.key});

  @override
  State<EnterpriseStudioScreen> createState() => _EnterpriseStudioScreenState();
}

class _EnterpriseStudioScreenState extends State<EnterpriseStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _searchFileController = TextEditingController();

  bool _isAutonomousRunning = false;
  bool _isWaitingForUserFileSelection = false;
  double _progressValue = 0.0;
  String _currentPhase = 'Idle - Ready for Enterprise Task.';
  String _fileSearchQuery = '';

  final List<String> _logs = [];
  List<Map<String, dynamic>> _selectableFiles = [];
  String _actionsUrl = '';

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final config = await _getStoredConfig();
    if (config.groqKey == 'YOUR_GROQ_API_KEY') {
      _addLog('⚠️ Default configuration detected. Please check settings.');
    } else {
      _addLog('⚙️ Loaded stored configurations successfully (Hybrid Grok + Claude Engine Ready).');
    }
  }

  void _addLog(String message, {String type = 'info'}) {
    setState(() {
      _logs.insert(
        0, 
        '[${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}] $message'
      );
    });
  }

  Future<AgentConfig> _getStoredConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return AgentConfig(
      groqKey: prefs.getString('groq_key') ?? 'YOUR_GROQ_API_KEY',
      anthropicKey: prefs.getString('anthropic_key') ?? '',
      githubToken: prefs.getString('github_token') ?? 'YOUR_GITHUB_TOKEN',
      githubUser: prefs.getString('github_user') ?? 'tarun225601-star',
      githubRepo: prefs.getString('github_repo') ?? 'real_time',
      selectedModel: prefs.getString('agent_model') ?? 'claude-3-5-sonnet-20241022',
    );
  }

  Future<void> _saveConfig(AgentConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', config.groqKey);
    await prefs.setString('anthropic_key', config.anthropicKey);
    await prefs.setString('github_token', config.githubToken);
    await prefs.setString('github_user', config.githubUser);
    await prefs.setString('github_repo', config.githubRepo);
    await prefs.setString('agent_model', config.selectedModel);
  }

  void _showSettingsDialog() {
    final groqKeyController = TextEditingController();
    final anthropicKeyController = TextEditingController();
    final githubTokenController = TextEditingController();
    final githubUserController = TextEditingController();
    final githubRepoController = TextEditingController();
    String selectedModel = 'claude-3-5-sonnet-20241022';

    _getStoredConfig().then((config) {
      groqKeyController.text = config.groqKey;
      anthropicKeyController.text = config.anthropicKey;
      githubTokenController.text = config.githubToken;
      githubUserController.text = config.githubUser;
      githubRepoController.text = config.githubRepo;
      selectedModel = config.selectedModel;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enterprise Studio Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groqKeyController,
                decoration: const InputDecoration(labelText: 'Groq / Grok API Key (Scout)'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: anthropicKeyController,
                decoration: const InputDecoration(labelText: 'Anthropic Claude API Key (Master Coder)'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: githubTokenController,
                decoration: const InputDecoration(labelText: 'GitHub Personal Access Token'),
                obscureText: true,
              ),
              TextField(
                controller: githubUserController,
                decoration: const InputDecoration(labelText: 'GitHub Username'),
              ),
              TextField(
                controller: githubRepoController,
                decoration: const InputDecoration(labelText: 'GitHub Repository Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedModel,
                decoration: const InputDecoration(labelText: 'Primary Code Engine'),
                items: const [
                  DropdownMenuItem(value: 'claude-3-5-sonnet-20241022', child: Text('Claude 3.5 Sonnet (Master Coder)')),
                  DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B (Groq)')),
                ],
                onChanged: (val) {
                  if (val != null) selectedModel = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newConfig = AgentConfig(
                groqKey: groqKeyController.text.trim(),
                anthropicKey: anthropicKeyController.text.trim(),
                githubToken: githubTokenController.text.trim(),
                githubUser: githubUserController.text.trim(),
                githubRepo: githubRepoController.text.trim(),
                selectedModel: selectedModel,
              );
              await _saveConfig(newConfig);
              Navigator.pop(context);
              _addLog('💾 Hybrid Configuration updated successfully.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // AI Router: Grok (Scout) -> Claude (Master Coder)
  Future<String> _callAiModel({required AgentConfig config, required String systemPrompt, required String userPrompt}) async {
    // अगर यूजर ने Claude चुना है या क्लाउड की चाबी है, तो कोडिंग के लिए Claude 3.5 Sonnet का इस्तेमाल होगा
    if (config.anthropicKey.isNotEmpty && config.selectedModel.contains('claude')) {
      _addLog('🤖 Routing request to Claude 3.5 Sonnet (Master Coder)...');
      final uri = Uri.parse('https://api.anthropic.com/v1/messages');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': config.anthropicKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          "model": "claude-3-5-sonnet-20241022",
          "max_tokens": 4000,
          "system": systemPrompt,
          "messages": [
            {"role": "user", "content": userPrompt}
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Claude API Error: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      return decoded['content'][0]['text'];
    } else {
      // फॉलबैक या Groq API (Llama 3.3 70B)
      _addLog('⚡ Routing request to Groq / Llama Engine...');
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.groqKey}',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt}
          ],
          "temperature": 0.2,
          "max_tokens": 4000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API Error: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      return decoded['choices'][0]['message']['content'];
    }
  }

  Future<void> _startAutonomousPipeline() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter a prompt or app requirement!')),
      );
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.2;
      _currentPhase = 'Analyzing prompt and mapping file paths via AI Router...';
      _selectableFiles.clear();
      _actionsUrl = '';
    });

    _addLog('🚀 Initializing Groq Scout + Claude Coder Pipeline...');

    try {
      final config = await _getStoredConfig();
      
      final systemPrompt = '''
You are an expert, meticulous Flutter developer and senior architect. Your task is to generate the exact set of files and code required for the user's prompt, ensuring every single file is placed in its STRICT AND CORRECT project path.

CRITICAL PATH RULES:
1. Flutter main UI/Logic code MUST always be inside the "lib/" directory (e.g., "lib/main.dart", "lib/screens/home_screen.dart").
2. Configuration files MUST follow Flutter standards (e.g., "pubspec.yaml", "android/app/build.gradle", "android/app/src/main/AndroidManifest.xml").
3. DO NOT invent arbitrary or broken paths. Use standard Flutter workspace hierarchies.
4. Generate ONLY the necessary number of files based on the prompt complexity.

Output MUST be a valid JSON array of objects with this exact structure:
[
  {
    "fileName": "lib/main.dart",
    "fileCode": "actual clean code string here..."
  }
]
Do NOT output any markdown outside the JSON block. Strictly return a valid JSON array.
'''.trim();

      String content = await _callAiModel(
        config: config, 
        systemPrompt: systemPrompt, 
        userPrompt: userPrompt,
      );
      
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = content.indexOf('[');
      int endIndex = content.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        content = content.substring(startIndex, endIndex + 1);
      }
      
      List<dynamic> parsedList = jsonDecode(content);
      List<String> filePlan = parsedList.map((e) => e['fileName'].toString()).toList();

      if (!filePlan.contains('lib/main.dart')) {
        filePlan.add('lib/main.dart');
      }

      _addLog('📋 Generated ${filePlan.length} files successfully.');

      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.5;
        _currentPhase = 'Review paths & files, then push to GitHub.';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

    } catch (e) {
      _addLog('⚠️ Generation Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Failed to generate files.';
      });
    }
  }

  Future<void> _confirmAndExecuteBuild() async {
    final chosenFiles = _selectableFiles
        .where((f) => f['selected'] == true)
        .map((f) => f['path'].toString())
        .toList();

    if (chosenFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select at least one file!')),
      );
      return;
    }

    setState(() {
      _isWaitingForUserFileSelection = false;
      _isAutonomousRunning = true;
      _progressValue = 0.7;
      _currentPhase = 'Synthesizing clean code with Claude and pushing to GitHub...';
    });

    try {
      final config = await _getStoredConfig();

      final systemPrompt = '''
You are an expert Flutter developer. Generate the full code for the requested files based on the user requirement. Ensure correct paths.
Output MUST be a valid JSON array of objects with this exact structure:
[
  {
    "fileName": "lib/main.dart",
    "fileCode": "actual clean code string here..."
  }
]
Do NOT output markdown outside the JSON. Strictly valid JSON array.
''';

      String rawResponse = await _callAiModel(
        config: config,
        systemPrompt: systemPrompt,
        userPrompt: 'Generate code for files: ${jsonEncode(chosenFiles)} based on user requirement: ${_promptController.text.trim()}',
      );

      _addLog('📦 Verifying Android folder structures and config files...');
      final files = _parsePlainFiles(rawResponse, config.githubRepo);

      _addLog('☁️ Pushing files to correct GitHub repository paths...');
      for (int i = 0; i < files.length; i++) {
        final fileEntry = files[i];
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];

        _addLog('📤 Uploading to path -> $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Successfully committed all files to correct paths!';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });
      _addLog('🎉 All files successfully committed to correct repository paths!');

    } catch (e) {
      _addLog('⚠️ Push Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Failed to push files.';
      });
    }
  }

  List<Map<String, dynamic>> _parsePlainFiles(String rawResponse, String packageName) {
    try {
      String cleaned = rawResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = cleaned.indexOf('[');
      int endIndex = cleaned.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }

      List<dynamic> list = [];
      try {
        list = jsonDecode(cleaned);
      } catch (_) {
        list = [];
      }

      List<Map<String, dynamic>> parsedFiles = [];
      for (var item in list) {
        parsedFiles.add({
          'fileName': item['fileName'] ?? '',
          'fileCode': item['fileCode'] ?? '',
        });
      }

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'pubspec.yaml');
      parsedFiles.add({
        'fileName': 'pubspec.yaml',
        'fileCode': '''name: $packageName
description: A new Flutter application.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '^3.3.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.2
  provider: ^6.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString().contains('AndroidManifest.xml'));
      parsedFiles.add({
        'fileName': 'android/app/src/main/AndroidManifest.xml',
        'fileCode': '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="$packageName"
        android:name="\${applicationName}">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'android/app/build.gradle');
      parsedFiles.add({
        'fileName': 'android/app/build.gradle',
        'fileCode': '''plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.$packageName"
    compileSdkVersion 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.example.$packageName"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString().endsWith('.yml') || file['fileName'].toString().endsWith('.yaml'));
      parsedFiles.add({
        'fileName': '.github/workflows/flutter.yml',
        'fileCode': '''name: Build Flutter App

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
      - run: flutter pub get
      - run: flutter build apk --release
      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
''',
      });

      return parsedFiles;
    } catch (e) {
      throw Exception('Parsing Error: $e');
    }
  }

  Future<void> _pushFileToGitHub(AgentConfig config, String fileName, String fileCode) async {
    final url = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/contents/$fileName');
    
    String? existingSha;
    try {
      final getResponse = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${config.githubToken}',
          'Accept': 'application/vnd.github+json',
        },
      );
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        existingSha = data['sha'];
      }
    } catch (_) {}

    final encodedContent = base64Encode(utf8.encode(fileCode));

    final Map<String, dynamic> bodyData = {
      "message": "Autonomous Structure Generator: Update $fileName",
      "content": encodedContent,
      "branch": "main",
    };

    if (existingSha != null) {
      bodyData["sha"] = existingSha;
    }

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${config.githubToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github+json',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to push $fileName to GitHub: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _selectableFiles.where((f) {
      return f['path'].toLowerCase().contains(_fileSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Enterprise Studio'),
        backgroundColor: const Color(0xFF1D3557),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enter App Requirement / Prompt',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isAutonomousRunning || _isWaitingForUserFileSelection ? null : _startAutonomousPipeline,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5D4), 
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🔍 Step 1: Generate Correct Paths & Files (Hybrid)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
            ),
            const SizedBox(height: 8),
            Text('Status: ${(_progressValue * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_currentPhase, style: const TextStyle(color: Color(0xFF00F5D4))),
            const SizedBox(height: 12),
            if (_isWaitingForUserFileSelection) ...[
              TextField(
                controller: _searchFileController,
                onChanged: (val) => setState(() => _fileSearchQuery = val),
                decoration: const InputDecoration(
                  labelText: 'Search Files...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Review Paths & Select Files to Push:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final fileItem = filteredFiles[index];
                    return CheckboxListTile(
                      title: Text(fileItem['path']),
                      value: fileItem['selected'],
                      activeColor: const Color(0xFF00F5D4),
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          fileItem['selected'] = val ?? true;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _confirmAndExecuteBuild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5D4), 
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('🚀 Step 2: Push Files to Correct GitHub Paths', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _logs[index], 
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_actionsUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: Text('Actions URL: $_actionsUrl', style: const TextStyle(color: Color(0xFF00F5D4))),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
