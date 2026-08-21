import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "⚠️ Error: ${details.exception}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const GroqStudioApp());
}

class GroqStudioApp extends StatelessWidget {
  const GroqStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groq Full-Stack Studio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        primaryColor: const Color(0xFF00F5D4),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F5D4),
          secondary: Color(0xFF7209B7),
          surface: Color(0xFF1D3557),
        ),
      ),
      home: const StudioHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudioHomeScreen extends StatefulWidget {
  const StudioHomeScreen({super.key});

  @override
  State<StudioHomeScreen> createState() => _StudioHomeScreenState();
}

class _StudioHomeScreenState extends State<StudioHomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  
  bool _isAutonomousRunning = false;
  bool _isGitHubConnected = false;
  double _progressValue = 0.0;
  String _currentPhase = 'Idle - Ready for Autonomous Full-Stack Generation.';
  
  final List<String> _logs = [];
  final Map<String, String> _generatedFilesMap = {};
  String _selectedViewFile = '';

  late AnimationController _brainAnimController;

  final List<String> _fallbackModels = [
    'llama-3.1-8b-instant',
    'llama-3.3-70b-versatile',
    'openai/gpt-oss-120b',
  ];

  @override
  void initState() {
    super.initState();
    _checkGitHubConfig();
    _brainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _brainAnimController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _checkGitHubConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('github_user') ?? '';
    final repo = prefs.getString('github_repo') ?? '';
    final token = prefs.getString('github_token') ?? '';
    if (user.isNotEmpty && repo.isNotEmpty && token.isNotEmpty) {
      setState(() {
        _isGitHubConnected = true;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
        0, 
        '[${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}]$message'
      );
    });
  }

  Future<List<String>> _fetchLiveModels() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('groq_api_key') ?? '';
    if (apiKey.isEmpty) return _fallbackModels;

    try {
      final response = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> liveModels = List<String>.from(data['data'].map((m) => m['id'].toString()));
        if (liveModels.isNotEmpty) {
          return liveModels;
        }
      }
    } catch (e) {
      // Ignore
    }
    return _fallbackModels;
  }

  void _showSettingsDialog() async {
    final groqKeyController = TextEditingController();
    final userController = TextEditingController();
    final repoController = TextEditingController();
    final tokenController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    groqKeyController.text = prefs.getString('groq_api_key') ?? '';
    userController.text = prefs.getString('github_user') ?? '';
    repoController.text = prefs.getString('github_repo') ?? '';
    tokenController.text = prefs.getString('github_token') ?? '';
    String selectedModel = prefs.getString('selected_model') ?? 'llama-3.1-8b-instant';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('⚙️ Studio & Model Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groqKeyController,
                  decoration: const InputDecoration(labelText: 'Groq API Key (gsk_...)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<String>>(
                  future: _fetchLiveModels(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    List<String> models = snapshot.data ?? _fallbackModels;
                    if (!models.contains(selectedModel)) {
                      models.insert(0, selectedModel);
                    }
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedModel,
                      items: models.map((m) => DropdownMenuItem(
                        value: m, 
                        child: Text(m, style: const TextStyle(fontSize: 12))
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedModel = val);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Select AI Model (Live List)'),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(labelText: 'GitHub Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repoController,
                  decoration: const InputDecoration(labelText: 'GitHub Repository Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(labelText: 'GitHub Personal Access Token'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await prefs.setString('groq_api_key', groqKeyController.text.trim());
                await prefs.setString('selected_model', selectedModel);
                await prefs.setString('github_user', userController.text.trim());
                await prefs.setString('github_repo', repoController.text.trim());
                await prefs.setString('github_token', tokenController.text.trim());
                
                await _checkGitHubConfig();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Settings Saved!')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _callGroqAPI(String systemPrompt, String userPrompt) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('groq_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      throw Exception('Groq API Key missing! Tap gear icon to set it.');
    }

    String preferredModel = prefs.getString('selected_model') ?? 'llama-3.1-8b-instant';
    List<String> modelsToTry = [preferredModel, ..._fallbackModels].toSet().toList();

    for (String model in modelsToTry) {
      try {
        final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            "model": model,
            "messages": [
              {"role": "system", "content": systemPrompt},
              {"role": "user", "content": userPrompt}
            ],
            "temperature": 0.1,
            "max_tokens": 4000,
          }),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          return decoded['choices'][0]['message']['content'];
        }
      } catch (e) {
        continue;
      }
    }
    throw Exception('All models failed. Please check your API key.');
  }

  Future<void> _startAutonomousBuild() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter requirements!')));
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.1;
      _currentPhase = '🧠 Groq Agent analyzing architecture...';
      _generatedFilesMap.clear();
      _logs.clear();
    });
    _addLog('🚀 Autonomous build started for: "$userPrompt"');

    try {
      const systemPrompt = '''
You are a strict JSON-only API. Output ONLY a valid JSON array of relative file paths (e.g. ["lib/main.dart", "pubspec.yaml"]). 
Do NOT include markdown formatting, backticks, or explanation text.
''';

      setState(() { _progressValue = 0.2; _currentPhase = '📂 Planning project file structure...'; });
      String content = await _callGroqAPI(systemPrompt, userPrompt);
      
      content = content.replaceAll('```json', '').replaceAll('```', '').replaceAll('`', '').trim();
      
      int start = content.indexOf('[');
      int end = content.lastIndexOf(']');
      if (start != -1 && end != -1) {
        content = content.substring(start, end + 1);
      }

      List<String> filePlan = [];
      try {
        List<dynamic> parsedList = jsonDecode(content);
        filePlan = parsedList.map((e) => e.toString()).toList();
      } catch (jsonErr) {
        _addLog('⚠️ JSON Parse warning: using default architecture layout.');
        filePlan = ['lib/main.dart', 'pubspec.yaml'];
      }
      
      if (!filePlan.contains('lib/main.dart')) filePlan.add('lib/main.dart');
      if (!filePlan.contains('pubspec.yaml')) filePlan.add('pubspec.yaml');

      _addLog('✅ Planned ${filePlan.length} files successfully.');

      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('github_user') ?? '';
      final repo = prefs.getString('github_repo') ?? '';
      final token = prefs.getString('github_token') ?? '';

      for (int i = 0; i < filePlan.length; i++) {
        String fileName = filePlan[i];
        double calcProgress = 0.3 + (((i + 1) / filePlan.length) * 0.5);
        
        setState(() {
          _progressValue = calcProgress;
          _currentPhase = '✍️ Writing code (${i + 1}/${filePlan.length}):$fileName';
        });
        _addLog('🔨 Generating code for: $fileName');

        const codeSystemPrompt = '''
You are an expert Senior Flutter Developer. Write production-ready, complete, fully working code ONLY inside markdown code blocks. Output ONLY the code.
''';
        String rawResponse = await _callGroqAPI(codeSystemPrompt, 'Requirement: $userPrompt\nFile:$fileName');
        String code = _extractCleanCode(rawResponse);
        
        _generatedFilesMap[fileName] = code;
      }

      if (user.isNotEmpty && repo.isNotEmpty && token.isNotEmpty) {
        setState(() {
          _progressValue = 0.85;
          _currentPhase = '🌐 Pushing generated files to GitHub...';
        });
        String fullRepoPath = '$user/$repo';
        _addLog('🔄 Connecting to GitHub repository: $fullRepoPath');

        for (var entry in _generatedFilesMap.entries) {
          await _pushFileToGitHub(fullRepoPath, token, entry.key, entry.value);
        }
        _addLog('✅ All files successfully pushed to GitHub!');
      } else {
        _addLog('ℹ️ GitHub credentials incomplete; files saved locally.');
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = '🎉 Build Complete! 100% Success.';
        if (_generatedFilesMap.isNotEmpty) {
          _selectedViewFile = _generatedFilesMap.keys.first;
        }
      });
      _addLog('✨ Autonomous Build & GitHub Sync finished successfully.');
    } catch (e) {
      setState(() => _isAutonomousRunning = false);
      _addLog('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  Future<void> _pushFileToGitHub(String fullRepo, String token, String path, String content) async {
    final url = Uri.parse('https://api.github.com/repos/$fullRepo/contents/$path');
    String? sha;
    
    final getRes = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json'});
    if (getRes.statusCode == 200) {
      sha = jsonDecode(getRes.body)['sha'];
    }

    final body = {
      "message": "Groq Agent Auto-Code: $path",
      "content": base64Encode(utf8.encode(content)),
      if (sha != null) "sha": sha,
    };

    final putRes = await http.put(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (putRes.statusCode != 200 && putRes.statusCode != 201) {
      throw Exception('GitHub Push Failed for $path');
    }
    _addLog('📂 Pushed to GitHub -> $path');
  }

  String _extractCleanCode(String raw) {
    if (raw.contains('```')) {
      int start = raw.indexOf('```');
      start = raw.indexOf('\n', start) + 1;
      int end = raw.lastIndexOf('```');
      if (end > start) return raw.substring(start, end).trim();
    }
    return raw.trim();
  }

  // असली WebView के साथ Live App Preview
  void _showAppPreview() {
    // एक सुंदर HTML पेज बनाओ जिसमें जेनरेटेड कोड और ऐप की डिटेल दिखे
    final mainCode = _generatedFilesMap['lib/main.dart'] ?? '// No main.dart found';
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>App Live Preview</title>
        <style>
          body { background-color: #0b132b; color: #00f5d4; font-family: monospace; padding: 16px; margin: 0; }
          h2 { color: #ffffff; border-bottom: 2px solid #00f5d4; padding-bottom: 8px; }
          .card { background: #1d3557; padding: 12px; border-radius: 8px; margin-bottom: 12px; border: 1px solid #00f5d4; }
          pre { background: #000; color: #00ffcc; padding: 10px; border-radius: 6px; overflow-x: auto; font-size: 11px; }
        </style>
      </head>
      <body>
        <h2>🚀 Live App Web Simulator</h2>
        <div class="card">
          <strong>Requirement:</strong> ${_promptController.text}
        </div>
        <div class="card">
          <strong>Generated Files:</strong> ${_generatedFilesMap.length} files built successfully.
        </div>
        <h3>📄 main.dart Code:</h3>
        <pre>${mainCode.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</pre>
      </body>
      </html>
    ''';

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlContent);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1D3557),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public, color: Color(0xFF00F5D4)),
                        SizedBox(width: 8),
                        Text('Live WebView Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: WebViewWidget(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RotationTransition(
              turns: _isAutonomousRunning ? _brainAnimController : const AlwaysStoppedAnimation(0),
              child: const Icon(Icons.psychology, color: Color(0xFF00F5D4)),
            ),
            const SizedBox(width: 8),
            const Text('Groq Full-Stack Studio'),
          ],
        ),
        backgroundColor: const Color(0xFF1D3557),
        actions: [
          if (_generatedFilesMap.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.remove_red_eye, color: Color(0xFF00F5D4)),
              tooltip: 'Preview App',
              onPressed: _showAppPreview,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🤖 Agent: Autonomous Mode', style: TextStyle(color: Color(0xFF00F5D4), fontSize: 12, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: _isGitHubConnected ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(_isGitHubConnected ? 'GitHub Synced' : 'GitHub Not Connected', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            TextField(
              controller: _promptController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Enter App Requirement (e.g. "make full marketplace app")', 
                border: OutlineInputBorder(), 
                filled: true, 
                fillColor: Colors.black26,
                labelStyle: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isAutonomousRunning ? null : _startAutonomousBuild,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F5D4), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('🚀 Start Autonomous Build & GitHub Push', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: _progressValue, 
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
              backgroundColor: Colors.white10,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(_currentPhase, style: const TextStyle(color: Color(0xFF00F5D4), fontSize: 11))),
                Text('${(_progressValue * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('💻 Live Agent Console & Files:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (_generatedFilesMap.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      final codeToCopy = _generatedFilesMap[_selectedViewFile] ?? '';
                      Clipboard.setData(ClipboardData(text: codeToCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('📋 Copied $_selectedViewFile!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 12),
                    label: const Text('Copy File', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7209B7), foregroundColor: Colors.white, minimumSize: const Size(80, 28)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            
            if (_generatedFilesMap.isNotEmpty)
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _generatedFilesMap.keys.map((fileName) {
                    bool isSelected = _selectedViewFile == fileName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text(fileName, style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : Colors.white)),
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
                        : _logs.join('\n'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.cyanAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
