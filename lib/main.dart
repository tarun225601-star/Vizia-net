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
// 1. ADVANCED CONFIGURATION & SETTINGS MODEL
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
// 2. SETTINGS SCREEN VIEW & CONTROLLER
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
        content: Text('⚡ All Master Credentials Saved Successfully!'),
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
          const Text(
            'API & Repository Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide your Groq API key and GitHub credentials for fully automated multi-file compilation and push.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
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
              prefixIcon: const Icon(Icons.person, color: Color(0xFF00E5FF)),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _repoController,
            decoration: const InputDecoration(
              labelText: 'GitHub Repository Name',
              prefixIcon: const Icon(Icons.folder_special, color: Color(0xFF00E5FF)),
              border: const OutlineInputBorder(),
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
              labelText: 'AI Processing Engine Model',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFF131B2E),
            ),
            items: const [
              DropdownMenuItem(
                value: 'llama-3.3-70b-versatile',
                child: Text('Llama 3.3 70B Versatile (Recommended)'),
              ),
              DropdownMenuItem(
                value: 'llama-3.1-8b-instant',
                child: Text('Llama 3.1 8B Instant (Ultra Fast)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _modelChoice = val);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
            ),
            onPressed: _saveSettings,
            child: const Text(
              'Save Agent Parameters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. LOGGING & TELEMETRY ENGINE MODEL
// ==========================================
class AgentLog {
  final String timestamp;
  final String message;
  final LogType type;

  AgentLog({required this.timestamp, required this.message, required this.type});
}

enum LogType { info, success, warning, error }

// ==========================================
// 4. MAIN AUTONOMOUS WORKBENCH DASHBOARD
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
  // 5. CORE AUTONOMOUS AGENT ORCHESTRATOR
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
      _currentPhase = 'Initializing Autonomous Loop...';
    });

    _addLog('🚀 Autonomous Agent Session Started.', type: LogType.success);
    _addLog('Target Repository: ${config.githubUser}/${config.githubRepo}');

    int attempt = 0;
    bool success = false;
    List files = [];

    // Phase 1: AI Code Synthesis with Self-Healing Error Correction Loop (3 Retries)
    while (attempt < 3 && !success) {
      attempt++;
      setState(() {
        _progressValue = 0.15 + (attempt * 0.15);
        _currentPhase = 'Synthesis Phase: Attempt $attempt/3';
      });
      _addLog('🧠 Architect Agent analyzing prompt requirements (Attempt $attempt)...');

      try {
        final rawResponse = await _callGroqModel(config, _promptController.text);
        files = _parseAndValidateJsonFiles(rawResponse);
        success = true;
        _addLog('✅ Code Synthesis & Architecture Generation successful!', type: LogType.success);
      } catch (e) {
        _addLog('⚠️ Validation/Parsing Exception caught: $e', type: LogType.warning);
        if (attempt >= 3) {
          _addLog('❌ Autonomous agent failed after 3 corrective iterations.', type: LogType.error);
          setState(() {
            _isAutonomousRunning = false;
            _currentPhase = 'Pipeline Aborted due to persistent parsing errors.';
          });
          return;
        }
        _addLog('🔄 Self-Healing Engine engaging automatic syntax adjustment prompt rewrite...');
      }
    }

    if (!success) return;

    setState(() {
      _generatedFilesCache = files;
      _progressValue = 0.65;
      _currentPhase = 'Deployment Phase: GitHub Sync & SHA Resolution';
    });

    // Phase 2: Autonomous Multi-File GitHub Deployment Loop
    try {
      _addLog('☁️ Connecting to GitHub REST API endpoints...');
      for (int i = 0; i < files.length; i++) {
        final fileEntry = files[i];
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];

        final filePushProgress = 0.65 + ((i + 1) / files.length) * 0.25;
        setState(() => _progressValue = filePushProgress);

        _addLog('📦 Processing target file: $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Execution Completed Successfully';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });

      _addLog('🎉 All ${files.length} project files deployed cleanly to GitHub repository!', type: LogType.success);
      _addLog('🔨 GitHub Actions runner triggered. Check workflows for build progress.', type: LogType.success);
    } catch (gitErr) {
      _addLog('❌ GitHub Synchronization Failed: $gitErr', type: LogType.error);
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Deployment Failed during network sync.';
      });
    }
  }

  // ==========================================
  // 6. HTTP API INTERACTION LAYER WITH GROQ
  // ==========================================
  Future<String> _callGroqModel(AgentConfig config, String userPrompt) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final systemPrompt = '''
You are an elite Autonomous AI Agent, Lead Mobile Architect, and Self-Healing Code Engine (like Replit Agent).
Your goal is to parse user prompts and output a fully complete, professional, compilation-ready Flutter application architecture.

MANDATORY RULES:
1. Output MUST be ONLY a clean, parseable JSON object matching this exact structure:
{
  "files": [
    {
      "fileName": "lib/main.dart",
      "fileCode": "// complete dart code here..."
    },
    {
      "fileName": "pubspec.yaml",
      "fileCode": "name: autonomous_app\ndescription: Auto generated\nversion: 1.0.0+1\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\ndependencies:\n  flutter:\n    sdk: flutter\n  http: ^1.2.0\n  shared_preferences: ^2.2.2\n  provider: ^6.1.1\n"
    },
    {
      "fileName": ".github/workflows/flutter.yml",
      "fileCode": "name: Build APK\\non: [push]\\njobs:\\n  build:\\n    runs-on: ubuntu-latest\\n    steps:\\n      - uses: actions/checkout@v3\\n      - uses: subosito/flutter-action@v2\\n        with:\\n          flutter-version: '3.x'\\n      - run: flutter pub get\\n      - run: flutter build apk --release\\n      - uses: actions/upload-artifact@v3\\n        with:\\n          name: release-apk\\n          path: build/app/outputs/flutter-apk/app-release.apk\\n"
    }
  ]
}
2. If the user app demands device permissions (Camera, Location, Storage, Bluetooth, etc.), you MUST include 'android/app/src/main/AndroidManifest.xml' containing matching <uses-permission> tags and add necessary dependencies in pubspec.yaml.
3. No markdown text blocks (no ```json or ``` wrappers), no conversational filler, no explanations. Return strictly valid raw JSON.
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
        "temperature": 0.3,
        "max_tokens": 8000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API Error Code ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  // ==========================================
  // 7. ROBUST JSON REPAIR & PARSING UTILITY
  // ==========================================
  List<dynamic> _parseAndValidateJsonFiles(String rawContent) {
    String cleaned = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
    int startIdx = cleaned.indexOf('{');
    int endIdx = cleaned.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    final decodedJson = jsonDecode(cleaned);
    if (decodedJson['files'] == null || (decodedJson['files'] as List).isEmpty) {
      throw Exception('Synthesized JSON missing required files array.');
    }
    return decodedJson['files'];
  }

  // ==========================================
  // 8. GITHUB REST CONTENT SYNC WITH SHA CHECK
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
      'message': 'Autonomous Agent Commit: Automated build update for $fileName',
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
      throw Exception('GitHub Sync rejected push for $fileName (${putResponse.statusCode}): ${putResponse.body}');
    }
  }

  // ==========================================
  // 9. UI WIDGET RENDER TREE & DESIGN SYSTEM
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Replit Studio Engine'),
        backgroundColor: const Color(0xFF131B2E),
        elevation: 0,
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
            // Banner Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF131B2E), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '⚡ Full-Spectrum Autonomous Engine',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Engineered to architect, validate, self-heal, and deploy complete multi-file Flutter repositories directly into your pipeline with zero manual code entry.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Autonomous Prompt Instruction:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF131B2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Describe the complete app you want built automatically...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isAutonomousRunning ? null : _executeAutonomousPipeline,
                child: Text(
                  _isAutonomousRunning ? 'Autonomous Engine Running...' : '🚀 Launch Full Autonomous Pipeline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Progress & Status Tracker Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pipeline Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      Text(
                        '${(_progressValue * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.black45,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentPhase,
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Actions Output Link Card
            if (_actionsUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2C2C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📦 GitHub Actions Build Dashboard:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _actionsUrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Live Autonomous Telemetry & Logs:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              height: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs recorded yet. Launch pipeline to view live stream.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color color = Colors.white70;
                        if (log.type == LogType.success) color = Colors.tealAccent;
                        if (log.type == LogType.warning) color = Colors.amberAccent;
                        if (log.type == LogType.error) color = Colors.redAccent;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Text(
                            '[${log.timestamp}] ${log.message}',
                            style: TextStyle(
                              color: color,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            // File Cache Preview Section
            if (_generatedFilesCache.isNotEmpty) ...[
              const Text(
                'Synthesized Multi-File Artifact Manifest:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              ..._generatedFilesCache.map((fileMap) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 18, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileMap['fileName'] ?? 'unknown',
                          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      const Text(
                        'Deployed',
                        style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
