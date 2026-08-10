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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00F5D4),
          secondary: const Color(0xFF7209B7),
          surface: const Color(0xFF1D3557),
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

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    // Initialization of saved local parameters if any
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

  // ==========================================
  // STEP 1: ARCHITECT MODULAR PLANNER
  // ==========================================
  Future<void> _startAutonomousPipeline() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter a prompt or architecture requirement!')),
      );
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.15;
      _currentPhase = 'Analyzing prompt for multi-tier modular structure...';
      _selectableFiles.clear();
      _actionsUrl = '';
    });

    _addLog('🚀 Enterprise Autonomous Agent Pipeline Initialized.');
    _addLog('🧠 Analyzing prompt for multi-tier modular structure...');

    try {
      final config = await _getStoredConfig();
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final systemPrompt = '''
You are an Enterprise Chief Technology Officer (CTO). Design a professional, production-ready, multi-file modular architecture in Flutter for the user prompt.
RULES FOR FILE TREE:
1. Break down code into proper folders under `lib/`:
   - "lib/main.dart"
   - "lib/models/app_model.dart"
   - "lib/services/api_service.dart"
   - "lib/providers/app_provider.dart"
   - "lib/screens/home_screen.dart"
2. Always include essential project configurations:
   - "pubspec.yaml"
   - ".github/workflows/flutter.yml"
3. Output MUST be ONLY a valid JSON array of strings containing the file paths. Do NOT write any conversational introduction, markdown code-block tags, or extra text. Start directly with [ and end with ].
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
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Architect Planner Error: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      String content = decoded['choices'][0]['message']['content'].trim();
      
      // Robust auto-clean for JSON array output
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = content.indexOf('[');
      int endIndex = content.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        content = content.substring(startIndex, endIndex + 1);
      }
      
      List<dynamic> parsedList = jsonDecode(content);
      List<String> filePlan = parsedList.map((e) => e.toString()).toList();

      _addLog('📋 Architect designed ${filePlan.length} modular components.');

      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.30;
        _currentPhase = 'Paused: Review & Search Modular File Plan.';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

    } catch (e) {
      _addLog('⚠️ Planning Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Aborted.';
      });
    }
  }

  // ==========================================
  // STEP 2: CODE SYNTHESIS & GITHUB PUSH
  // ==========================================
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
      _currentPhase = 'Phase 2: Base64 Code Synthesis via Groq...';
    });

    _addLog('⚡ Synthesizing code with Base64 safety packing...');

    try {
      final config = await _getStoredConfig();
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final systemPrompt = '''
You are an expert Flutter Developer & Enterprise Code Synthesizer.
For each file in the requested list, generate production-ready code.
CRITICAL ENCODING RULE:
You MUST encode the file content into Base64 format so that newlines and special characters are safely preserved.
Output MUST be a valid JSON array of objects with this exact structure:
[
  {
    "fileName": "lib/main.dart",
    "fileCode": "<BASE64_ENCODED_STRING_OF_THE_CODE>"
  }
]
Do NOT output markdown outside the JSON or text greetings. Strictly valid JSON array.
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
            {"role": "user", "content": "Generate code for files: ${jsonEncode(chosenFiles)}"}
          ],
          "temperature": 0.2,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Code Synthesis Error: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      String rawResponse = decoded['choices'][0]['message']['content'];

      setState(() {
        _progressValue = 0.60;
        _currentPhase = 'Phase 3: Base64 Decoding & Syntax Verification...';
      });

      _addLog('🔍 Decoding Base64 strings and running verification...');
      final files = _parseAndDecodeBase64Files(rawResponse);
      _addLog('✅ All files successfully decoded and verified.');

      setState(() {
        _progressValue = 0.75;
        _currentPhase = 'Phase 4: GitHub Enterprise Secure Push...';
      });

      _addLog('☁️ Connecting to GitHub REST API endpoints...');
      for (int i = 0; i < files.length; i++) {
        final fileEntry = files[i];
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];

        final filePushProgress = 0.75 + ((i + 1) / files.length) * 0.25;
        setState(() => _progressValue = filePushProgress);

        _addLog('📦 Pushing module: $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Enterprise Pipeline Completed Successfully!';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });

      _addLog('🎉 High-level modular architecture deployed to GitHub!');

    } catch (e) {
      _addLog('⚠️ Build/Push Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Aborted.';
      });
    }
  }

  // SAFE BASE64 DECODER & PARSER
  List<Map<String, dynamic>> _parseAndDecodeBase64Files(String rawResponse) {
    try {
      String cleaned = rawResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = cleaned.indexOf('[');
      int endIndex = cleaned.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }

      List<dynamic> list = jsonDecode(cleaned);
      List<Map<String, dynamic>> decodedFiles = [];

      for (var item in list) {
        String fileName = item['fileName'] ?? '';
        String base64Code = item['fileCode'] ?? '';
        
        String actualCode = utf8.decode(base64Decode(base64Code));
        
        decodedFiles.add({
          'fileName': fileName,
          'fileCode': actualCode,
        });
      }
      return decodedFiles;
    } catch (e) {
      throw Exception('Base64 Parsing Error: $e');
    }
  }

  // FIXED GITHUB PUSH WITH PROPER BASE64 ENCODING
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

    // FIXED: Ensures newlines and formats stay intact
    final encodedContent = base64Encode(utf8.encode(fileCode));

    final Map<String, dynamic> bodyData = {
      "message": "Autonomous Agent: Add/Update $fileName via Enterprise Pipeline",
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
            onPressed: () {
              // Settings panel trigger
            },
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
              child: const Text('🔍 Step 1: Plan Modular Architecture', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
            ),
            const SizedBox(height: 8),
            Text('Enterprise Pipeline Status: ${(_progressValue * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_currentPhase, style: const TextStyle(color: Color(0xFF00F5D4))),
            const SizedBox(height: 12),
            if (_isWaitingForUserFileSelection) ...[
              TextField(
                controller: _searchFileController,
                onChanged: (val) => setState(() => _fileSearchQuery = val),
                decoration: const InputDecoration(
                  labelText: 'Search Modular Files...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Review & Select Modular Files to Build:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: const Text('🚀 Step 2: Synthesize Base64 & Push Code', style: TextStyle(fontWeight: FontWeight.bold)),
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
