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
      title: 'Autonomous Enterprise Studio - Final Smart Scale',
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
  final String openRouterKey;
  final String githubToken;
  final String githubUser;
  final String githubRepo;
  final String selectedModel;

  AgentConfig({
    required this.openRouterKey,
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
  String _currentPhase = 'Idle - Ready for Smart-Scale App Build.';
  String _fileSearchQuery = '';

  final List<String> _logs = [];
  List<Map<String, dynamic>> _selectableFiles = [];
  String _actionsUrl = '';

  final List<Map<String, String>> _vipModels = [
    {'name': 'Claude 3.5 Sonnet (Anthropic - Best for Code)', 'id': 'anthropic/claude-3.5-sonnet'},
    {'name': 'Claude 3.5 Opus (Anthropic - Heavy Logic)', 'id': 'anthropic/claude-3-opus'},
    {'name': 'DeepSeek R1 (Reasoning Master)', 'id': 'deepseek/deepseek-r1'},
    {'name': 'DeepSeek V3 (Lightning Fast Coding)', 'id': 'deepseek/deepseek-chat'},
    {'name': 'GPT-4o (OpenAI Flagship)', 'id': 'openai/gpt-4o'},
    {'name': 'GPT-4o Mini (OpenAI Fast)', 'id': 'openai/gpt-4o-mini'},
    {'name': 'Llama 3.3 70B Instruct (Meta)', 'id': 'meta-llama/llama-3.3-70b-instruct'},
    {'name': 'Qwen 2.5 Coder 32B (Specialized Code)', 'id': 'qwen/qwen-2.5-coder-32b-instruct'},
    {'name': 'Mistral Large 2 (Mistral AI)', 'id': 'mistralai/mistral-large-2407'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final config = await _getStoredConfig();
    if (config.openRouterKey == 'YOUR_OPENROUTER_API_KEY') {
      _addLog('⚠️ Default configuration detected. Please configure via Gear Icon.');
    } else {
      _addLog('⚙️ Loaded Agent configuration successfully.');
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
      openRouterKey: prefs.getString('openrouter_key') ?? 'YOUR_OPENROUTER_API_KEY',
      githubToken: prefs.getString('github_token') ?? 'YOUR_GITHUB_TOKEN',
      githubUser: prefs.getString('github_user') ?? 'tarun225601-star',
      githubRepo: prefs.getString('github_repo') ?? 'real_time',
      selectedModel: prefs.getString('openrouter_model') ?? 'anthropic/claude-3.5-sonnet',
    );
  }

  Future<void> _saveConfig(AgentConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_key', config.openRouterKey);
    await prefs.setString('github_token', config.githubToken);
    await prefs.setString('github_user', config.githubUser);
    await prefs.setString('github_repo', config.githubRepo);
    await prefs.setString('openrouter_model', config.selectedModel);
  }

  void _showSettingsDialog() {
    final openRouterKeyController = TextEditingController();
    final githubTokenController = TextEditingController();
    final githubUserController = TextEditingController();
    final githubRepoController = TextEditingController();
    
    String currentSelectedModel = 'anthropic/claude-3.5-sonnet';

    _getStoredConfig().then((config) {
      openRouterKeyController.text = config.openRouterKey;
      githubTokenController.text = config.githubToken;
      githubUserController.text = config.githubUser;
      githubRepoController.text = config.githubRepo;
      currentSelectedModel = config.selectedModel;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Studio Settings & API Keys'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: openRouterKeyController,
                  decoration: const InputDecoration(labelText: 'OpenRouter API Key'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                const Text('Select VIP Model:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00F5D4))),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _vipModelExists(currentSelectedModel) ? currentSelectedModel : _vipModels[0]['id'],
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1D3557),
                  items: _vipModels.map((model) {
                    return DropdownMenuItem<String>(
                      value: model['id'],
                      child: Text(
                        model['name']!, 
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        currentSelectedModel = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
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
                  openRouterKey: openRouterKeyController.text.trim(),
                  githubToken: githubTokenController.text.trim(),
                  githubUser: githubUserController.text.trim(),
                  githubRepo: githubRepoController.text.trim(),
                  selectedModel: currentSelectedModel,
                );
                await _saveConfig(newConfig);
                Navigator.pop(context);
                setState(() {});
                _addLog('💾 Configuration & API Keys saved successfully!');
              },
              child: const Text('Save Keys'),
            ),
          ],
        ),
      ),
    );
  }

  bool _vipModelExists(String modelId) {
    return _vipModels.any((m) => m['id'] == modelId);
  }

  Future<String> _callOpenRouter({
    required AgentConfig config, 
    required String systemPrompt, 
    required String userPrompt,
  }) async {
    _addLog('🚀 Routing request via OpenRouter to [${config.selectedModel}]...');
    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.openRouterKey}',
        'HTTP-Referer': 'https://github.com/${config.githubUser}/${config.githubRepo}',
        'X-Title': 'Final Smart Scale Studio',
      },
      body: jsonEncode({
        "model": config.selectedModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userPrompt}
        ],
        "temperature": 0.1,
        "max_tokens": 8000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API StatusCode ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  Future<void> _startScaleAnalysis() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter an app requirement!')),
      );
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.2;
      _currentPhase = 'Analyzing app scale (Utility vs Massive Marketplace)...';
      _selectableFiles.clear();
      _actionsUrl = '';
    });

    try {
      final config = await _getStoredConfig();
      
      const systemPrompt = '''
You are an expert Flutter Architect. Analyze the user prompt:
1. FOR SIMPLE APPS (Calculator, Notes): Return only ['lib/main.dart'].
2. FOR MASSIVE/COMPLEX APPS (Marketplace, E-commerce, Instagram): Return structured paths like ['lib/main.dart', 'lib/screens/home_screen.dart', 'lib/models/item.dart', 'lib/services/api_service.dart'].
3. Output MUST be a strictly valid JSON array of strings, NO markdown outside:
[
  "lib/main.dart"
]
''';

      String content = await _callOpenRouter(
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
      List<String> filePlan = parsedList.map((e) => e.toString()).toList();

      if (!filePlan.contains('lib/main.dart')) {
        filePlan.add('lib/main.dart');
      }

      _addLog('📋 Scaled successfully into ${filePlan.length} file(s). Review & Confirm.');

      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.5;
        _currentPhase = 'Review files and push to GitHub.';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

    } catch (e) {
      // Fallback agar plan parse na ho
      setState(() {
        _selectableFiles = [
          {'path': 'lib/main.dart', 'selected': true}
        ];
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.5;
        _currentPhase = 'Fallback: Single file mode activated.';
      });
      _addLog('⚠️ Scale Analysis fallback to main.dart due to: $e');
    }
  }

  // --- टुकड़ों में कोड जनरेट करने वाला सेफ और नया मेथड ---
  Future<void> _confirmAndPushBuild() async {
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
      _progressValue = 0.6;
      _currentPhase = 'Generating code file-by-file to prevent token errors...';
    });

    try {
      final config = await _getStoredConfig();

      // हर फाइल को एक-एक करके टुकड़ों में बनाएंगे ताकि टोकन और पार्सिंग का लोचा खत्म हो जाए
      for (int i = 0; i < chosenFiles.length; i++) {
        String fileName = chosenFiles[i];
        double progress = 0.6 + ((i + 1) / chosenFiles.length) * 0.3;
        
        setState(() {
          _progressValue = progress > 0.9 ? 0.9 : progress;
          _currentPhase = 'Generating code for: $fileName';
        });

        _addLog('🤖 Requesting code for $fileName...');

        final systemPrompt = '''
You are an expert Flutter Developer. Write production-ready, 100% bug-free code ONLY for the file: $fileName.
CRITICAL RULES:
1. Ensure absolute package imports if multi-file: `import 'package:${config.githubRepo}/...';`.
2. Include a Settings Gear Icon in the app bar that opens a dialog to save local API keys using SharedPreferences.
3. Return ONLY clean Dart code inside standard markdown code blocks (```dart ... ```) or plain text. Do not wrap in complex JSON arrays.
''';

        String rawResponse = await _callOpenRouter(
          config: config,
          systemPrompt: systemPrompt,
          userPrompt: 'App Requirement: ${_promptController.text.trim()}\nTarget File: $fileName',
        );

        // कोड को क्लीन करना
        String fileCode = _extractCleanCode(rawResponse);

        _addLog('📤 Pushing $fileName to GitHub...');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      // अंत में pubspec.yaml जोड़ेंगे
      _addLog('📦 Creating & Pushing pubspec.yaml...');
      String pubspecCode = '''name: ${config.githubRepo}
description: A smart-scale Flutter application with API key settings.
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
''';
      await _pushFileToGitHub(config, 'pubspec.yaml', pubspecCode);

      _addLog('⚙️ Injecting GitHub Actions Workflow with APK Artifact support...');
      await _pushFileToGitHub(config, '.github/workflows/flutter.yml', _getArtifactWorkflowYaml());

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Successfully committed all files & workflow!';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });
      _addLog('🎉 Deployment complete! Check GitHub Actions for your downloadable APK.');

    } catch (e) {
      _addLog('❌ Push Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Failed during GitHub commit.';
      });
    }
  }

  // एआई के रिस्पॉन्स से सिर्फ डार्ट कोड निकालने का सेफ तरीका (पार्सिंग एरर प्रूफ)
  String _extractCleanCode(String rawResponse) {
    try {
      String cleaned = rawResponse.trim();
      // अगर मार्कडाउन ब्लॉक है तो उसे एक्सट्रेक्ट करो
      if (cleaned.contains('```dart')) {
        int start = cleaned.indexOf('```dart') + 7;
        int end = cleaned.lastIndexOf('```');
        if (end > start) {
          cleaned = cleaned.substring(start, end).trim();
        }
      } else if (cleaned.contains('```')) {
        int start = cleaned.indexOf('```') + 3;
        int end = cleaned.lastIndexOf('```');
        if (end > start) {
          cleaned = cleaned.substring(start, end).trim();
        }
      }
      return cleaned;
    } catch (_) {
      return rawResponse; // फेल होने पर पूरा रॉ रिस्पॉन्स रिटर्न कर देगा ताकि क्रैश न हो
    }
  }

  String _getArtifactWorkflowYaml() {
    return '''name: Flutter Build & Generate APK Artifact

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
          channel: 'stable'

      - name: Auto-Heal & Create Android Structure
        run: |
          PROJECT_NAME=\$(grep '^name:' pubspec.yaml | head -n 1 | awk '{print \$2}' | tr -d '\\r' | tr -d '"' | tr -d "'")
          rm -rf android ios .dart_tool build
          flutter create . --project-name "\$PROJECT_NAME" --platforms=android

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK Release
        run: flutter build apk --release

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          retention-days: 7
''';
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
      "message": "Final Smart-Scale Engine: Update $fileName",
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
      throw Exception('GitHub Push Failed for $fileName: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _selectableFiles.where((f) {
      return f['path'].toLowerCase().contains(_fileSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Smart-Scale Studio'),
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
            FutureBuilder<AgentConfig>(
              future: _getStoredConfig(),
              builder: (context, snapshot) {
                final modelName = snapshot.hasData ? snapshot.data!.selectedModel : 'Loading...';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D3557),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active Model: $modelName',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF00F5D4), fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enter App Requirement (e.g. Marketplace App with Firebase)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isAutonomousRunning || _isWaitingForUserFileSelection ? null : _startScaleAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5D4), 
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🔍 Step 1: Analyze Scale & Map Structure', style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: _confirmAndPushBuild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5D4), 
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('🚀 Step 2: Push Code & Generate APK', style: TextStyle(fontWeight: FontWeight.bold)),
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
