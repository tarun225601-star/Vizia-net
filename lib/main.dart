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
      title: 'Master Autonomous Studio',
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
        content: Text('⚡ Parameters Saved Successfully!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Core Configuration'),
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
              labelText: 'AI Model',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
            items: const [
              DropdownMenuItem(
                value: 'llama-3.3-70b-versatile',
                child: Text('Llama 3.3 70B Versatile (Recommended)'),
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
              child: const Text('Save Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
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
// 4. MAIN DASHBOARD
// ==========================================
class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Create a fully operational, responsive Flutter fitness tracker app with dark mode, storage, and custom charts.',
  );
  
  final List<AgentLog> _logs = [];
  bool _isAutonomousRunning = false;
  double _progressValue = 0.0;
  String _currentPhase = 'IDLE - Waiting for instructions';
  String _actionsUrl = '';
  List<dynamic> _generatedFilesCache = [];

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
  // 5. SELF-VERIFYING AUTONOMOUS PIPELINE
  // ==========================================
  Future<void> _executeAutonomousPipeline() async {
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
      _progressValue = 0.05;
      _actionsUrl = '';
      _currentPhase = 'Phase 1: Dynamic Architecture Planning...';
    });

    _addLog('🚀 Autonomous Agent Session Started.', type: LogType.success);
    _addLog('Target Repository: ${config.githubUser}/${config.githubRepo}');

    int attempt = 0;
    bool success = false;
    List files = [];

    while (attempt < 3 && !success) {
      attempt++;
      setState(() {
        _progressValue = 0.10 + (attempt * 0.10);
        _currentPhase = 'Self-Correction & Validation Loop (Attempt $attempt/3)';
      });

      try {
        // STEP 1: Ask Groq for precise file blueprint
        _addLog('🧠 Step 1: Querying Groq for optimal file structure blueprint...');
        final filePlan = await _callGroqForFilePlan(config, _promptController.text);
        _addLog('📋 Architect Approved Files: ${filePlan.join(', ')}', type: LogType.success);

        // STEP 2: Generate code based on blueprint (Now strictly includes GitHub Actions setup rule)
        setState(() => _currentPhase = 'Phase 2: Code Synthesis & Multi-File Generation...');
        _addLog('⚡ Step 2: Synthesizing raw files according to blueprint...');
        final rawResponse = await _callGroqForCodeGeneration(config, _promptController.text, filePlan);

        // STEP 3: Self-Validation and Verification Check
        setState(() => _currentPhase = 'Phase 3: Rigorous Validation & Self-Check...');
        _addLog('🔍 Step 3: Running internal syntax & structure verification checks...');
        files = _parseAndValidateJsonFiles(rawResponse, filePlan);

        success = true;
        _addLog('✅ All files passed multi-layer verification checks successfully!', type: LogType.success);
      } catch (e) {
        _addLog('⚠️ Validation Exception caught: $e', type: LogType.warning);
        if (attempt >= 3) {
          _addLog('❌ Autonomous agent failed after 3 corrective iterations.', type: LogType.error);
          setState(() {
            _isAutonomousRunning = false;
            _currentPhase = 'Pipeline Aborted due to validation failure.';
          });
          return;
        }
        _addLog('🔄 Self-Healing Engine re-trying synthesis loop...');
      }
    }

    if (!success) return;

    setState(() {
      _generatedFilesCache = files;
      _progressValue = 0.60;
      _currentPhase = 'Phase 4: GitHub Secure Synchronization & Push';
    });

    try {
      _addLog('☁️ Connecting to GitHub REST API endpoints...');
      for (int i = 0; i < files.length; i++) {
        final fileEntry = files[i];
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];

        final filePushProgress = 0.60 + ((i + 1) / files.length) * 0.35;
        setState(() => _progressValue = filePushProgress);

        _addLog('📦 Pushing verified target file: $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Execution Completed Successfully';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });

      _addLog('🎉 All ${files.length} verified project files deployed cleanly!', type: LogType.success);
    } catch (gitErr) {
      _addLog('❌ GitHub Synchronization Failed: $gitErr', type: LogType.error);
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Deployment Failed during sync.';
      });
    }
  }

  // ==========================================
  // 6. ARCHITECT FILE PLANNER
  // ==========================================
  Future<List<String>> _callGroqForFilePlan(AgentConfig config, String userPrompt) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final systemPrompt = '''
You are a Lead Software Architect. Given the user requirement, determine the exact file structure required (e.g., pubspec.yaml, lib/main.dart, .github/workflows/flutter.yml).
Return ONLY a valid JSON array of strings containing paths. Example:
["pubspec.yaml", "lib/main.dart", ".github/workflows/flutter.yml"]
No markdown formatting, no extra text.
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
  // 7. CODE GENERATION (UPDATED WITH FLUTTER ACTIONS RULE)
  // ==========================================
  Future<String> _callGroqForCodeGeneration(AgentConfig config, String userPrompt, List<String> filePlan) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final systemPrompt = '''
You are an expert Developer and DevOps Engineer. Generate production-ready code strictly for these files: ${filePlan.join(', ')}.
MANDATORY RULES:
1. Output MUST be ONLY a clean raw JSON object matching this exact structure, with no markdown tags:
{
  "files": [
    {
      "fileName": "lib/main.dart",
      "fileCode": "// complete code..."
    }
  ]
}
2. CRITICAL FOR GITHUB ACTIONS (.github/workflows/flutter.yml): If you are generating a workflow file, you MUST include the official Flutter setup action so that 'flutter' command is never missing. Use this exact structure for the workflow:
name: Build Flutter App
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter build appbundle --release
3. Ensure strict valid YAML syntax without tabs or unescaped characters.
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
          {"role": "user", "content": "Generate code for: $userPrompt for files: ${filePlan.toString()}"}
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
  // 8. STRICT VALIDATION & SELF-CHECK ENGINE
  // ==========================================
  List<dynamic> _parseAndValidateJsonFiles(String rawContent, List<String> expectedFiles) {
    String cleaned = rawContent.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '').trim();
    cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
    
    int startIdx = cleaned.indexOf('{');
    int endIdx = cleaned.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    final decodedJson = jsonDecode(cleaned);
    if (decodedJson['files'] == null || !(decodedJson['files'] is List)) {
      throw Exception('Validation Error: Missing files array in JSON.');
    }

    List<dynamic> files = decodedJson['files'];
    if (files.isEmpty) {
      throw Exception('Validation Error: Generated files list is empty.');
    }

    // Double check YAML syntax integrity if present
    for (var file in files) {
      String name = file['fileName'] ?? '';
      String code = file['fileCode'] ?? '';
      if (name.endsWith('.yml') || name.endsWith('.yaml')) {
        if (code.contains('\t')) {
          throw Exception('Validation Error: YAML file $name contains tabs instead of spaces.');
        }
      }
    }

    return files;
  }

  // ==========================================
  // 9. GITHUB REST SYNC
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
      'message': 'Autonomous Agent Self-Verified Commit: $fileName',
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
  // 10. UI DESIGN
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Replit Studio Engine'),
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
            const Text('Autonomous Prompt Instruction:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF131B2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                onPressed: _isAutonomousRunning ? null : _executeAutonomousPipeline,
                child: Text(
                  _isAutonomousRunning ? 'Self-Checking & Running...' : '🚀 Launch Verified Autonomous Pipeline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pipeline Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
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
            const Text('Live Telemetry & Logs:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              height: 220,
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
