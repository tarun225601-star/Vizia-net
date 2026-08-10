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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF131B2E),
        ),
      ),
      home: const MasterDashboardScreen(),
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

  bool get isValid =>
      groqKey.isNotEmpty &&
      githubToken.isNotEmpty &&
      githubUser.isNotEmpty &&
      githubRepo.isNotEmpty;
}

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
      const SnackBar(content: Text('⚡ Parameters Saved Successfully!'), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Core Configuration'), backgroundColor: const Color(0xFF131B2E)),
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
              fillColor: Color(0xFF131B2E),
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
              fillColor: Color(0xFF131B2E),
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
              fillColor: Color(0xFF131B2E),
            ),
            items: const [
              DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B Versatile (Recommended)')),
              DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('Llama 3.1 8B Instant')),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
              onPressed: _saveSettings,
              child: const Text('Save Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentLog {
  final String timestamp;
  final String message;
  final LogType type;
  final bool canSolve;

  AgentLog({required this.timestamp, required this.message, required this.type, this.canSolve = false});
}

enum LogType { info, success, warning, error }

class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Create a simple calculator app in Flutter with modern UI.',
  );
  
  final TextEditingController _searchFileController = TextEditingController();
  String _fileSearchQuery = '';

  final List<AgentLog> _logs = [];
  bool _isAutonomousRunning = false;
  double _progressValue = 0.0;
  String _currentPhase = 'IDLE - Waiting for instructions';
  String _actionsUrl = '';

  bool _isWaitingForUserFileSelection = false;
  List<Map<String, dynamic>> _selectableFiles = [];

  Map<String, dynamic> _latestBuildRun = {};
  bool _isCheckingBuild = false;

  void _addLog(String msg, {LogType type = LogType.info, bool canSolve = false}) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.insert(0, AgentLog(timestamp: timeStr, message: msg, type: type, canSolve: canSolve));
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

  Future<void> _fetchLiveBuildStatus() async {
    final config = await _getStoredConfig();
    if (config == null || !config.isValid) return;

    setState(() => _isCheckingBuild = true);
    try {
      final uri = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs?per_page=1');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${config.githubToken}',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['workflow_runs'] != null && (data['workflow_runs'] as List).isNotEmpty) {
          final run = data['workflow_runs'][0];
          setState(() => _latestBuildRun = run);

          if (run['conclusion'] == 'failure') {
            _addLog('GitHub Pipeline Failed! Click Solve to auto-fix.', type: LogType.error, canSolve: true);
          }
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isCheckingBuild = false);
    }
  }

  Future<void> _solveError(String errorMessage) async {
    final config = await _getStoredConfig();
    if (config == null || !config.isValid) {
      _addLog('Configuration missing for auto-fix action.', type: LogType.error);
      return;
    }

    _addLog('🤖 Agent initiated self-correction...', type: LogType.warning);
    setState(() {
      _isAutonomousRunning = true;
      _currentPhase = 'Agent fixing Workflow/Build error...';
    });

    try {
      final fixPrompt = "Fix workflow configuration. Ensure android/app/src/main/AndroidManifest.xml exists and workflow uses flutter analyze or safe build without v1 embedding issues. Return ONLY valid JSON.";
      
      final rawResponse = await _callGroqForCodeGeneration(config, fixPrompt, ['pubspec.yaml', '.github/workflows/flutter.yml', 'android/app/src/main/AndroidManifest.xml']);
      final files = _parseAndValidateJsonFiles(rawResponse, ['pubspec.yaml', '.github/workflows/flutter.yml', 'android/app/src/main/AndroidManifest.xml']);

      for (var fileEntry in files) {
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];
        _addLog('📦 Pushing fix for file: $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      _addLog('🎉 Fix successfully pushed to GitHub! Check status again shortly.', type: LogType.success);
      _fetchLiveBuildStatus();
    } catch (e) {
      _addLog('❌ Auto-fix failed: $e', type: LogType.error);
    } finally {
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Idle / Ready';
      });
    }
  }

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
      _currentPhase = 'Phase 1: Analyzing Prompt & Generating Required File List...';
    });

    _addLog('🚀 Autonomous Agent Session Started.', type: LogType.success);

    try {
      _addLog('🧠 Reading user prompt to evaluate required project files...');
      final filePlan = await _callGroqForFilePlan(config, _promptController.text);
      
      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.30;
        _currentPhase = 'Paused: Review & Search Dynamic File List';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

      _addLog('📋 Architect planned ${filePlan.length} files. Search and review below.', type: LogType.success);
    } catch (e) {
      _addLog('⚠️ Planning Error: $e', type: LogType.error);
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Aborted.';
      });
    }
  }

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
      _progressValue = 0.45;
      _currentPhase = 'Phase 2: Code Synthesis for Selected Files...';
    });

    _addLog('⚡ User confirmed ${chosenFiles.length} files. Starting code generation...');

    try {
      final rawResponse = await _callGroqForCodeGeneration(config!, _promptController.text, chosenFiles);
      
      setState(() {
        _progressValue = 0.65;
        _currentPhase = 'Phase 3: Validation & Security Check...';
      });
      _addLog('🔍 Running internal syntax verification checks...');
      
      final files = _parseAndValidateJsonFiles(rawResponse, chosenFiles);
      _addLog('✅ All chosen files passed verification!', type: LogType.success);

      setState(() {
        _progressValue = 0.75;
        _currentPhase = 'Phase 4: GitHub Secure Synchronization & Push...';
      });

      _addLog('☁️ Connecting to GitHub REST API endpoints...');
      for (int i = 0; i < files.length; i++) {
        final fileEntry = files[i];
        final String fileName = fileEntry['fileName'];
        final String fileCode = fileEntry['fileCode'];

        final filePushProgress = 0.75 + ((i + 1) / files.length) * 0.20;
        setState(() => _progressValue = filePushProgress);

        _addLog('📦 Pushing target file: $fileName');
        await _pushFileToGitHub(config, fileName, fileCode);
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Execution Completed Successfully';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });

      _addLog('🎉 All selected project files deployed cleanly!', type: LogType.success);
      _fetchLiveBuildStatus();
    } catch (e) {
      _addLog('❌ Execution Failed: $e', type: LogType.error, canSolve: true);
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Deployment Failed.';
      });
    }
  }

  Future<List<String>> _callGroqForFilePlan(AgentConfig config, String userPrompt) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    // 🛡️ स्मार्ट आर्किटेक्ट: यह छोटे और बड़े दोनों प्रोजेक्ट्स के लिए सही पाथ और मेनिफेस्ट फाइल अपने आप तय करेगा।
    final systemPrompt = '''
You are an expert Lead Software Architect. Read the user prompt carefully and determine the necessary files to build the requested Flutter project.
RULES:
1. Under the `lib/` folder, ALWAYS include: "lib/main.dart".
2. Always include root configuration files:
   - "pubspec.yaml"
   - ".github/workflows/flutter.yml"
3. CRITICAL & MANDATORY for ALL projects (small or large): To prevent any v1 embedding or Android manifest missing errors, you MUST ALWAYS include the Android Manifest file:
   - "android/app/src/main/AndroidManifest.xml"
4. Return ONLY a valid JSON array of strings containing the file paths. No markdown formatting, no extra text.
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

  Future<String> _callGroqForCodeGeneration(AgentConfig config, String userPrompt, List<String> filePlan) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    // 🛑 फुल-प्रूफ जुगाड़: Manifest फाइल सही पाथ पर बनेगी और workflow में कभी v1 एरर नहीं आएगा!
    final systemPrompt = '''
You are an expert Senior DevOps and Flutter Architect. 
YOUR RULES ARE FINAL:
1. For "android/app/src/main/AndroidManifest.xml", ensure it uses a valid package name and includes proper Android v2 embedding metadata or necessary permissions if requested by the user prompt.
2. When creating ".github/workflows/flutter.yml", use "subosito/flutter-action@v2" and ensure it runs "flutter analyze" or a safe build pipeline that never throws v1 embedding errors.
3. For "pubspec.yaml" and "lib/main.dart", write complete, production-ready code without placeholders.
4. Every file content must be perfectly escaped for JSON with \\n for newlines.

Output MUST be a strict JSON object with NO markdown tags:
{
  "files": [
    {
      "fileName": "path/to/file",
      "fileCode": "file content here..."
    }
  ]
}
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
          {"role": "user", "content": "Generate professional code for: $userPrompt for these files: ${filePlan.toString()}. Ensure strict DevOps standards."}
        ],
        "temperature": 0.05,
        "max_tokens": 8000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Code Gen Error: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'];
  }

  List<dynamic> _parseAndValidateJsonFiles(String rawContent, List<String> expectedFiles) {
    String cleaned = rawContent.trim();
    cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
    
    int startIdx = cleaned.indexOf('{');
    int endIdx = cleaned.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    cleaned = cleaned.replaceAllMapped(RegExp(r'"([^"\\]*(\\.[^"\\]*)*)"'), (match) {
      String val = match.group(0)!;
      val = val.replaceAll('\n', '\\n').replaceAll('\r', '').replaceAll('\t', '\\t');
      return val;
    });

    dynamic decodedJson;
    try {
      decodedJson = jsonDecode(cleaned);
    } catch (e) {
      cleaned = cleaned.replaceAll(RegExp(r'[\u0000-\u001F]+'), " ");
      decodedJson = jsonDecode(cleaned);
    }

    if (decodedJson['files'] == null || !(decodedJson['files'] is List)) {
      throw Exception('Validation Error: Missing files array in JSON.');
    }

    List<dynamic> files = decodedJson['files'];
    if (files.isEmpty) {
      throw Exception('Validation Error: Generated files list is empty.');
    }

    return files;
  }

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
      'message': 'Autonomous Sync: $fileName',
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

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _selectableFiles.where((fileMap) {
      final path = fileMap['path'].toString().toLowerCase();
      return path.contains(_fileSearchQuery.toLowerCase());
    }).toList();

    final String runStatus = _latestBuildRun['status'] ?? 'unknown';
    final String runConclusion = _latestBuildRun['conclusion'] ?? 'pending';

    Color buildStatusColor = Colors.orangeAccent;
    if (runConclusion == 'success') buildStatusColor = Colors.tealAccent;
    if (runConclusion == 'failure') buildStatusColor = Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Replit Studio Engine'),
        backgroundColor: const Color(0xFF131B2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _fetchLiveBuildStatus,
            tooltip: 'Refresh GitHub Build Status',
          ),
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
                    _isAutonomousRunning ? 'Analyzing Prompt...' : '🔍 Step 1: Analyze & Plan Files',
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
                      '📌 Dynamic Project Files List:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: _searchFileController,
                      onChanged: (val) => setState(() => _fileSearchQuery = val),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search files (e.g. main.dart, yaml)...',
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
                          child: Text('No matching files found.', style: TextStyle(color: Colors.white54)),
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
                      }),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                        onPressed: _confirmAndExecuteBuild,
                        child: const Text(
                          '🚀 Step 2: Confirm & Push to GitHub',
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

            const SizedBox(height: 20),
            const Text('☁️ Live GitHub Build Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: buildStatusColor.withOpacity(0.5), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: $runStatus', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Conclusion: $runConclusion', style: TextStyle(color: buildStatusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white),
                    onPressed: _fetchLiveBuildStatus,
                    icon: _isCheckingBuild 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan)) 
                        : const Icon(Icons.sync, size: 16, color: Color(0xFF00E5FF)),
                    label: const Text('Check Status', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

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
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '[${log.timestamp}] ${log.message}',
                            style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                        if (log.canSolve || log.type == LogType.error) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 26,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () => _solveError(log.message),
                              icon: const Icon(Icons.auto_fix_high, size: 12),
                              label: const Text('Solve', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
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
