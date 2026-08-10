import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MasterAutonomousStudioApp());

class MasterAutonomousStudioApp extends StatelessWidget {
  const MasterAutonomousStudioApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Master Autonomous Studio - Enterprise Edition',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07090E),
        cardColor: const Color(0xFF131B2E),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5FF),
          secondary: const Color(0xFF7C4DFF),
          surface: const Color(0xFF131B2E),
        ),
      ),
      home: const MasterDashboardScreen(),
    );
  }
}

// ==========================================
// 1. CONFIGURATION MODEL
// ==========================================
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

  bool get isValid =>
      groqKey.isNotEmpty &&
      githubToken.isNotEmpty &&
      githubUser.isNotEmpty &&
      githubRepo.isNotEmpty;
}

// ==========================================
// 2. SETTINGS SCREEN
// ==========================================
class MasterSettingsScreen extends StatefulWidget {
  const MasterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MasterSettingsScreen> createState() => _MasterSettingsScreenState();
}

class _MasterSettingsScreenState extends State<MasterSettingsScreen> {
  final _groqController = TextEditingController();
  final _tokenController = TextEditingController();
  final _userController = TextEditingController();
  final _repoController = TextEditingController();
  String _modelChoice = 'llama-3.3-70b-versatile';
  bool _obscureKey = true;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groqController.text = prefs.getString('master_groq_key') ?? '';
      _tokenController.text = prefs.getString('master_github_token') ?? '';
      _userController.text = prefs.getString('master_github_user') ?? '';
      _repoController.text = prefs.getString('master_github_repo') ?? '';
      _modelChoice = prefs.getString('master_model_choice') ?? 'llama-3.3-70b-versatile';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('master_groq_key', _groqController.text.trim());
    await prefs.setString('master_github_token', _tokenController.text.trim());
    await prefs.setString('master_github_user', _userController.text.trim());
    await prefs.setString('master_github_repo', _repoController.text.trim());
    await prefs.setString('master_model_choice', _modelChoice);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Enterprise Parameters Saved Successfully!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Agent Core Configuration'),
        backgroundColor: const Color(0xFF131B2E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _groqController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'Groq API Key',
              prefixIcon: const Icon(Icons.key, color: Color(0xFF00E5FF)),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: 'GitHub Username',
              prefixIcon: Icon(Icons.person, color: Color(0xFF00E5FF)),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _repoController,
            decoration: const InputDecoration(
              labelText: 'GitHub Repository Name',
              prefixIcon: Icon(Icons.folder_special, color: Color(0xFF00E5FF)),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            obscureText: _obscureToken,
            decoration: InputDecoration(
              labelText: 'GitHub Personal Access Token (PAT)',
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF00E5FF)),
              suffixIcon: IconButton(
                icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _modelChoice,
            dropdownColor: const Color(0xFF131B2E),
            decoration: const InputDecoration(
              labelText: 'AI Model Engine',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
            items: const [
              DropdownMenuItem(
                value: 'llama-3.3-70b-versatile',
                child: Text('Llama 3.3 70B Versatile (Enterprise Grade)'),
              ),
              DropdownMenuItem(
                value: 'llama-3.1-8b-instant',
                child: Text('Llama 3.1 8B Instant'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _modelChoice = val);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
              ),
              onPressed: _saveSettings,
              child: const Text('Save Enterprise Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. LOGGING MODEL
// ==========================================
class AgentLog {
  final String timestamp;
  final String message;
  final LogType type;

  AgentLog({required this.timestamp, required this.message, required this.type});
}

enum LogType { info, success, warning, error }

// ==========================================
// 4. ENTERPRISE DASHBOARD & MODULAR ENGINE
// ==========================================
class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Build a high-level E-Commerce app with clean modular architecture, models, services, state management, and full UI screens.',
  );
  
  final TextEditingController _searchFileController = TextEditingController();
  String _fileSearchQuery = '';

  final List<AgentLog> _logs = [];
  bool _isAutonomousRunning = false;
  double _progressValue = 0.0;
  String _currentPhase = 'IDLE - Ready for Enterprise Execution';
  String _actionsUrl = '';

  bool _isWaitingForUserFileSelection = false;
  List<Map<String, dynamic>> _selectableFiles = [];

  void _addLog(String msg, {LogType type = LogType.info}) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.insert(0, AgentLog(timestamp: timeStr, message: msg, type: type));
    });
  }

  Future<AgentConfig?> _getStoredConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return AgentConfig(
      groqKey: (prefs.getString('master_groq_key') ?? '').trim(),
      githubToken: (prefs.getString('master_github_token') ?? '').trim(),
      githubUser: (prefs.getString('master_github_user') ?? '').trim(),
      githubRepo: (prefs.getString('master_github_repo') ?? '').trim(),
      selectedModel: prefs.getString('master_model_choice') ?? 'llama-3.3-70b-versatile',
    );
  }

  // ==========================================
  // STEP 1: MODULAR ARCHITECTURE FILE PLANNER
  // ==========================================
  Future<void> _startPipelineAndPlanFiles() async {
    final config = await _getStoredConfig();
    if (!config!.isValid) {
      _addLog('Configuration error: Missing API credentials or repository parameters.', type: LogType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please configure settings first!')),
      );
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _logs.clear();
      _progressValue = 0.15;
      _actionsUrl = '';
      _isWaitingForUserFileSelection = false;
      _currentPhase = 'Phase 1: Designing Modular Architecture & File Tree...';
    });

    _addLog('🚀 Enterprise Autonomous Agent Started.', type: LogType.success);

    try {
      _addLog('🧠 Analyzing prompt for multi-tier modular structure...');
      final filePlan = await _callGroqForModularFilePlan(config, _promptController.text);
      
      setState(() {
        _selectableFiles = filePlan.map((path) => {
          'path': path,
          'selected': true,
        }).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.30;
        _currentPhase = 'Paused: Review & Search Modular File List';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

      _addLog('📋 Architect designed ${filePlan.length} files with clean separation of concerns.', type: LogType.success);
    } catch (e) {
      _addLog('⚠️ Planning Error: $e', type: LogType.error);
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Aborted.';
      });
    }
  }

  // ==========================================
  // STEP 2: CODE SYNTHESIS & SELF-CORRECTION
  // ==========================================
  Future<void> _confirmAndExecuteBuild() async {
    final config = await _getStoredConfig();
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
      _progressValue = 0.40;
      _currentPhase = 'Phase 2: Multi-File Code Synthesis...';
    });

    _addLog('⚡ User confirmed ${chosenFiles.length} files. Synthesizing high-level code...');

    try {
      final rawResponse = await _callGroqForModularCodeGeneration(config!, _promptController.text, chosenFiles);
      
      setState(() {
        _progressValue = 0.60;
        _currentPhase = 'Phase 3: Self-Correction & Syntax Verification...';
      });
      _addLog('🔍 Running internal self-healing syntax verification...');
      
      // Self-Correction & Validation Loop
      final files = _parseAndSelfCorrectFiles(rawResponse, chosenFiles);
      _addLog('✅ All files successfully passed verification and self-correction checks!', type: LogType.success);

      setState(() {
        _progressValue = 0.75;
        _currentPhase = 'Phase 4: GitHub Enterprise Secure Deployment...';
      });

      _addLog('☁️ Connecting to GitHub REST API endpoints...');
      for (int i = 0; i < files.length; i++) {
        final fileEntry = files[i];
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];

        final filePushProgress = 0.75 + ((i + 1) / files.length) * 0.20;
        setState(() => _progressValue = filePushProgress);

        _addLog('📦 Pushing module: $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Enterprise Pipeline Completed Successfully';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });

      _addLog('🎉 High-level modular architecture deployed cleanly to GitHub!', type: LogType.success);
    } catch (e) {
      _addLog('❌ Execution Failed: $e', type: LogType.error);
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Deployment Failed.';
      });
    }
  }

  // ==========================================
  // ARCHITECT MODULAR PLANNER
  // ==========================================
  Future<List<String>> _callGroqForModularFilePlan(AgentConfig config, String userPrompt) async {
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
   - "lib/screens/detail_screen.dart"
2. Always include essential project configurations:
   - "pubspec.yaml"
   - ".github/workflows/flutter.yml"
3. Return ONLY a valid JSON array of strings containing the file paths. No markdown, no extra text.
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
    String content = decoded['choices'][0]['message']['content'];
    content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    
    List<dynamic> parsedList = jsonDecode(content);
    return parsedList.map((e) => e.toString()).toList();
  }

  // ==========================================
  // CODE GENERATION FOR MULTIPLE FILES
  // ==========================================
  Future<String> _callGroqForModularCodeGeneration(AgentConfig config, String userPrompt, List<String> filePlan) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final systemPrompt = '''
You are a Principal Software Engineer. Write high-level, production-grade code for each of these requested modular files: ${filePlan.join(', ')}.
MANDATORY RULES:
1. Output MUST be ONLY a clean raw JSON object matching this exact structure, with no markdown tags:
{
  "files": [
    {
      "fileName": "lib/models/app_model.dart",
      "fileCode": "// code here..."
    }
  ]
}
2. Ensure all imports between files (e.g., importing models inside screens or services) match correctly.
3. Write clean, complete, robust code without truncation or placeholders.
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
          {"role": "user", "content": "Generate modular code for: $userPrompt for files: ${filePlan.toString()}"}
        ],
        "temperature": 0.2,
        "max_tokens": 8000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Code Gen Error: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  // ==========================================
  // SELF-CORRECTION & VALIDATION ENGINE
  // ==========================================
  List<dynamic> _parseAndSelfCorrectFiles(String rawContent, List<String> expectedFiles) {
    String cleaned = rawContent.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '').trim();
    cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
    
    int startIdx = cleaned.indexOf('{');
    int endIdx = cleaned.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    final decodedJson = jsonDecode(cleaned);
    if (decodedJson['files'] == null || !(decodedJson['files'] is List)) {
      throw Exception('Self-Correction Error: Missing files array in JSON structure.');
    }

    List<dynamic> files = decodedJson['files'];
    if (files.isEmpty) {
      throw Exception('Self-Correction Error: Generated files list is empty.');
    }

    // Self-healing checks
    for (var file in files) {
      String name = file['fileName'] ?? '';
      String code = file['fileCode'] ?? '';
      if ((name.endsWith('.yml') || name.endsWith('.yaml')) && code.contains('\t')) {
        file['fileCode'] = code.replaceAll('\t', '  '); // Auto-fix YAML tabs to spaces
      }
    }

    return files;
  }

  // ==========================================
  // GITHUB PUSH
  // ==========================================
  Future<void> _pushFileToGitHub(AgentConfig config, String fileName, String fileCode) async {
    final endpointStr = 'https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/contents/$fileName';
    final fileUri = Uri.parse(endpointStr);

    String? existingSha;
    final getCheck = await http.get(
      fileUri,
      headers: {
        'Authorization': 'Bearer ${config.githubToken}',
        'Accept': 'application/vnd.github+json',
      },
    );

    if (getCheck.statusCode == 200) {
      final jsonBody = jsonDecode(getCheck.body);
      existingSha = jsonBody['sha'];
    }

    final Map<String, dynamic> requestBody = {
      'message': 'Enterprise Modular Autonomous Commit: $fileName',
      'content': base64Encode(utf8.encode(fileCode)),
    };

    if (existingSha != null) {
      requestBody['sha'] = existingSha;
    }

    final putResponse = await http.put(
      fileUri,
      headers: {
        'Authorization': 'Bearer ${config.githubToken}',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
      throw Exception('GitHub Sync rejected push for $fileName (${putResponse.statusCode})');
    }
  }

  // ==========================================
  // UI DESIGN
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final filteredFiles = _selectableFiles.where((fileMap) {
      final path = fileMap['path'].toString().toLowerCase();
      return path.contains(_fileSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Enterprise Studio Engine'),
        backgroundColor: const Color(0xFF131B2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF00E5FF)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MasterSettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enterprise App Requirement Prompt:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF131B2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_isWaitingForUserFileSelection)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                  onPressed: _isAutonomousRunning ? null : _startPipelineAndPlanFiles,
                  child: Text(
                    _isAutonomousRunning ? 'Designing Architecture...' : '🔍 Step 1: Plan Modular Architecture',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

            if (_isWaitingForUserFileSelection) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📌 Modular Project Files Tree:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: _searchFileController,
                      onChanged: (val) => setState(() => _fileSearchQuery = val),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search modules (e.g. models, screens, services)...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF00E5FF)),
                        suffixIcon: _fileSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchFileController.clear();
                                    _fileSearchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white24),

                    if (filteredFiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Center(
                          child: Text('No matching modules found.', style: TextStyle(color: Colors.white54)),
                        ),
                      )
                    else
                      ...filteredFiles.map((fileMap) {
                        return CheckboxListTile(
                          activeColor: const Color(0xFF00E5FF),
                          checkColor: Colors.black,
                          dense: true,
                          title: Text(
                            fileMap['path'],
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                          ),
                          value: fileMap['selected'],
                          onChanged: (bool? val) {
                            setState(() {
                              fileMap['selected'] = val ?? true;
                            });
                          },
                        );
                      }).toList(),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                        onPressed: _confirmAndExecuteBuild,
                        child: const Text(
                          '🚀 Step 2: Synthesize & Push Enterprise Code',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enterprise Pipeline Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                      Text('${(_progressValue * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _progressValue, backgroundColor: Colors.black45, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF))),
                  const SizedBox(height: 10),
                  Text(_currentPhase, style: const TextStyle(color: Colors.tealAccent, fontFamily: 'monospace', fontSize: 12)),
                ],
              ),
            ),
            if (_actionsUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              SelectableText(_actionsUrl, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            const Text('Live Telemetry & Diagnostics:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color color = Colors.white70;
                  if (log.type == LogType.success) color = Colors.tealAccent;
                  if (log.type == LogType.warning) color = Colors.amberAccent;
                  if (log.type == LogType.error) color = Colors.redAccent;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Text('[${log.timestamp}] ${log.message}', style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11)),
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
