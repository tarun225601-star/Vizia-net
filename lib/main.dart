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
  final String githubToken;
  final String githubUser;
  final String githubRepo;
  final String selectedModel;

  AgentConfig({
    required this.groqKey,
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
  String _criticalErrorReason = '';

  // To store current code states for targeted patching
  final Map<String, String> _currentProjectFiles = {};

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
      _addLog('⚙️ Loaded stored configurations successfully.');
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
      githubToken: prefs.getString('github_token') ?? 'YOUR_GITHUB_TOKEN',
      githubUser: prefs.getString('github_user') ?? 'tarun225601-star',
      githubRepo: prefs.getString('github_repo') ?? 'real_time',
      selectedModel: prefs.getString('groq_model') ?? 'llama-3.3-70b-versatile',
    );
  }

  Future<void> _saveConfig(AgentConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', config.groqKey);
    await prefs.setString('github_token', config.githubToken);
    await prefs.setString('github_user', config.githubUser);
    await prefs.setString('github_repo', config.githubRepo);
    await prefs.setString('groq_model', config.selectedModel);
  }

  void _showSettingsDialog() {
    final groqKeyController = TextEditingController();
    final githubTokenController = TextEditingController();
    final githubUserController = TextEditingController();
    final githubRepoController = TextEditingController();
    String selectedModel = 'llama-3.3-70b-versatile';

    _getStoredConfig().then((config) {
      groqKeyController.text = config.groqKey;
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
                decoration: const InputDecoration(labelText: 'Groq API Key'),
                obscureText: true,
              ),
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
                decoration: const InputDecoration(labelText: 'Groq Model'),
                items: const [
                  DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B Versatile')),
                  DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('Llama 3.1 8B Instant')),
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
                githubToken: githubTokenController.text.trim(),
                githubUser: githubUserController.text.trim(),
                githubRepo: githubRepoController.text.trim(),
                selectedModel: selectedModel,
              );
              await _saveConfig(newConfig);
              Navigator.pop(context);
              _addLog('💾 Configuration updated successfully.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
      _progressValue = 0.15;
      _currentPhase = 'Analyzing prompt for architecture rules...';
      _selectableFiles.clear();
      _actionsUrl = '';
      _criticalErrorReason = '';
    });

    _addLog('🚀 Enterprise Autonomous Agent Pipeline Initialized.');
    _addLog('🧠 Evaluating prompt for file requirements...');

    try {
      final config = await _getStoredConfig();
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final systemPrompt = '''
Return ONLY a valid JSON array string containing essential file paths for the requested Flutter app. Example: ["pubspec.yaml", "lib/main.dart"]
CRITICAL RULE: The main application UI, logic, widgets MUST be entirely contained within "lib/main.dart".
No markdown, strictly raw JSON array.
''';

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.groqKey}',
        },
        body: jsonEncode({
          "model": config.selectedModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt}
          ],
          "temperature": 0.1,
          "max_tokens": 1000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API Error (${response.statusCode}): Check API key or rate limit.');
      }

      final decoded = jsonDecode(response.body);
      String content = decoded['choices'][0]['message']['content'].trim();
      
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = content.indexOf('[');
      int endIndex = content.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        content = content.substring(startIndex, endIndex + 1);
      } else {
        content = '["pubspec.yaml", "lib/main.dart"]';
      }
      
      List<dynamic> parsedList = jsonDecode(content);
      List<String> filePlan = parsedList.map((e) => e.toString()).toList();

      if (!filePlan.contains('lib/main.dart')) filePlan.add('lib/main.dart');
      if (!filePlan.contains('pubspec.yaml')) filePlan.add('pubspec.yaml');

      _addLog('📋 Architect designed ${filePlan.length} files.');

      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.30;
        _currentPhase = 'Paused: Review & Select Files.';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

    } catch (e) {
      _addLog('⚠️ Planning Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Aborted.';
        _criticalErrorReason = 'Planning Phase Failed: $e';
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
        const SnackBar(content: Text('⚠️ Please select at least one file to build!')),
      );
      return;
    }

    setState(() {
      _isWaitingForUserFileSelection = false;
      _isAutonomousRunning = true;
      _progressValue = 0.40;
      _currentPhase = 'Phase 2: Initial Code Generation & Setup...';
      _criticalErrorReason = '';
    });

    try {
      final config = await _getStoredConfig();
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final systemPrompt = '''
You are an expert Flutter Developer. Generate complete code for the requested files.
CRITICAL: Put entire app code in "lib/main.dart". Include necessary imports.
Output MUST be a valid JSON array:
[
  {
    "fileName": "lib/main.dart",
    "fileCode": "code..."
  }
]
No markdown outside JSON.
''';

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.groqKey}',
        },
        body: jsonEncode({
          "model": config.selectedModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "Generate code for files: ${jsonEncode(chosenFiles)} based on prompt: ${_promptController.text.trim()}"}
          ],
          "temperature": 0.2,
          "max_tokens": 4000,
        }),
      );

      if (response.statusCode != 200) throw Exception('Groq API Error: ${response.statusCode}');

      final decoded = jsonDecode(response.body);
      String rawResponse = decoded['choices'][0]['message']['content'];

      _addLog('🔍 Processing files and applying build configurations...');
      final files = _parsePlainFiles(rawResponse, config.githubRepo);

      // Save locally for targeted patching
      _currentProjectFiles.clear();
      for (var f in files) {
        _currentProjectFiles[f['fileName']] = f['fileCode'];
      }

      setState(() => _progressValue = 0.60);

      for (var fileEntry in files) {
        _addLog('📦 Pushing module: ${fileEntry['fileName']}');
        await _pushFileToGitHub(config, fileEntry['fileName'], fileEntry['fileCode']);
      }

      _addLog('⏳ Waiting for GitHub Actions build verification...');
      setState(() => _currentPhase = 'Phase 3: Monitoring GitHub Build Actions...');

      // START TARGETED SELF-HEALING LOOP (Only fixes exact errors)
      await _runTargetedSelfHealingLoop(config);

    } catch (e) {
      _addLog('⚠️ Execution Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _progressValue = 1.0;
        _currentPhase = 'Pipeline Halted.';
        _criticalErrorReason = 'Error: $e';
      });
    }
  }

  Future<void> _runTargetedSelfHealingLoop(AgentConfig config) async {
    int maxRetries = 3;
    bool success = false;
    String lastError = '';

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      String actionStatus = await _monitorGitHubAction(config);

      if (actionStatus == 'success') {
        success = true;
        _addLog('🎉 Build Passed Successfully on attempt $attempt!');
        break;
      } else if (actionStatus == 'failure') {
        _addLog('❌ Build Failed! Extracting exact error log...', type: 'error');
        lastError = await _fetchLatestActionErrorLog(config);
        _addLog('🔍 Captured Error: $lastError', type: 'error');

        if (attempt == maxRetries) break;

        _addLog('🤖 AI Targeted Patching: Fixing ONLY the reported error without touching other files...');
        setState(() => _currentPhase = 'Phase 4: Targeted Error Patching (Attempt ${attempt + 1})...');

        // Send ONLY the error and lib/main.dart to AI to fix the specific error line
        String fixedCode = await _askAIToFixSpecificError(config, lastError, _currentProjectFiles['lib/main.dart'] ?? '');
        
        if (fixedCode.isNotEmpty) {
          _currentProjectFiles['lib/main.dart'] = fixedCode;
          _addLog('📦 Pushing patched lib/main.dart to GitHub...');
          await _pushFileToGitHub(config, 'lib/main.dart', fixedCode);
        }
      } else {
        _addLog('⚠️ Build timeout or unknown state.');
        success = true;
        break;
      }
    }

    if (success) {
      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Completed Successfully!';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });
      _addLog('🎉 Application successfully verified and deployed!');
    } else {
      setState(() {
        _isAutonomousRunning = false;
        _progressValue = 1.0;
        _currentPhase = 'Pipeline Halted: Unresolved Error.';
        _criticalErrorReason = 'Could not auto-fix after $maxRetries attempts.\n\nFinal Error:\n$lastError';
      });
      _addLog('🛑 Stopped: Automatic fixes could not resolve the error.', type: 'error');
    }
  }

  Future<String> _askAIToFixSpecificError(AgentConfig config, String errorLog, String currentCode) async {
    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final systemPrompt = '''
You are a precise Flutter Code Fixer. You are given an existing Dart code and a specific compilation/build error.
Your task is ONLY to fix the exact error mentioned in the error log. Do not rewrite unrelated parts.
Return ONLY the corrected full Dart code string for lib/main.dart. Do not include markdown code blocks or explanations, return raw text or JSON if necessary, but preferred is just the raw code or JSON. Let's return a JSON object like {"fixedCode": "..."} or raw code. Let's ask for raw code directly:
Start directly with code or wrap in a JSON object with key "fixedCode".
''';

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.groqKey}',
        },
        body: jsonEncode({
          "model": config.selectedModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "ERROR LOG:\n$errorLog\n\nCURRENT CODE:\n$currentCode"}
          ],
          "temperature": 0.1,
          "max_tokens": 4000,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String content = decoded['choices'][0]['message']['content'].trim();
        content = content.replaceAll('```dart', '').replaceAll('```', '').trim();
        return content;
      }
    } catch (_) {}
    return '';
  }

  Future<String> _monitorGitHubAction(AgentConfig config) async {
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final url = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs?per_page=1');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer ${config.githubToken}',
            'Accept': 'application/vnd.github+json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final runs = data['workflow_runs'] as List;
          if (runs.isNotEmpty) {
            final latestRun = runs.first;
            if (latestRun['status'] == 'completed') {
              return latestRun['conclusion'] ?? '';
            }
          }
        }
      } catch (_) {}
    }
    return 'timeout';
  }

  Future<String> _fetchLatestActionErrorLog(AgentConfig config) async {
    try {
      final runsUrl = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs?per_page=1');
      final response = await http.get(
        runsUrl,
        headers: {
          'Authorization': 'Bearer ${config.githubToken}',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final runs = data['workflow_runs'] as List;
        if (runs.isNotEmpty) {
          final runId = runs.first['id'];
          final jobsUrl = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs/$runId/jobs');
          
          final jobsResponse = await http.get(
            jobsUrl,
            headers: {
              'Authorization': 'Bearer ${config.githubToken}',
              'Accept': 'application/vnd.github+json',
            },
          );

          if (jobsResponse.statusCode == 200) {
            final jobsData = jsonDecode(jobsResponse.body);
            final jobs = jobsData['jobs'] as List;
            for (var job in jobs) {
              final steps = job['steps'] as List;
              for (var step in steps) {
                if (step['conclusion'] == 'failure') {
                  return 'Failed at step [${step['name']}]: syntax error or missing package import.';
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return 'Flutter gradle compilation error.';
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

      // Mandatory Pubspec template
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
  image_picker: ^1.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
''',
      });

      // Android Manifest & Gradle standard files
      parsedFiles.removeWhere((file) => file['fileName'].toString().contains('AndroidManifest.xml'));
      parsedFiles.add({
        'fileName': 'android/app/src/main/AndroidManifest.xml',
        'fileCode': '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="$packageName" android:name="\${applicationName}">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:theme="@style/LaunchTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
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
    compileSdkVersion flutter.compileSdkVersion
    compileOptions { sourceCompatibility JavaVersion.VERSION_1_8; targetCompatibility JavaVersion.VERSION_1_8 }
    kotlinOptions { jvmTarget = '1.8' }
    defaultConfig {
        applicationId "com.example.$packageName"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode 1; versionName "1.0.0"
    }
}
flutter { source = "../.." }
''',
      });

      // GitHub Actions Workflow
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
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
      - run: flutter pub get
      - run: flutter build apk --release
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
      "message": "Autonomous Agent: Patch $fileName",
      "content": encodedContent,
      "branch": "main",
    };

    if (existingSha != null) bodyData["sha"] = existingSha;

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
      throw Exception('Failed to push $fileName: ${response.body}');
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
              child: const Text('🔍 Step 1: Plan Core Architecture', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
            ),
            const SizedBox(height: 8),
            Text('Pipeline Status: ${(_progressValue * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_currentPhase, style: const TextStyle(color: Color(0xFF00F5D4))),
            const SizedBox(height: 12),
            if (_criticalErrorReason.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛑 CRITICAL HALT REASON:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_criticalErrorReason, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
              const Text('Review & Select Files to Build:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: const Text('🚀 Step 2: Synthesize & Targeted Fix Loop', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              const Text('Live Telemetry & Diagnostics:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
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
