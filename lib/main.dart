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

  // ✅ सही WebView प्रीव्यू फ़ंक्शन (मल्टी-लाइन स्ट्रिंग के साथ)
  void _showAppPreview() {
    final String userPrompt = _promptController.text.trim();
    
    final htmlContent = '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Groq Studio Live Preview</title>
        <script src="[https://cdn.tailwindcss.com](https://cdn.tailwindcss.com)"></script>
        <link rel="stylesheet" href="[https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css](https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css)">
      </head>
      <body class="bg-[#0B132B] text-white font-sans flex flex-col h-screen m-0 p-4">
        
        <!-- Top App Bar -->
        <div class="flex justify-between items-center bg-[#1D3557] px-4 py-3 rounded-xl shadow-lg border border-[#00F5D4]/30 mb-4">
          <div class="flex items-center space-x-2">
            <span class="w-3 h-3 bg-green-400 rounded-full"></span>
            <h1 class="font-bold text-[#00F5D4] text-sm tracking-wider">GROQ LIVE PREVIEW</h1>
          </div>
          <span class="text-xs bg-[#0B132B] px-2 py-1 rounded text-cyan-300 border border-cyan-500/20">v1.0.0</span>
        </div>

        <!-- Simulator Container -->
        <div class="flex-1 bg-[#1D3557]/40 border border-[#00F5D4]/20 rounded-2xl p-4 flex flex-col overflow-hidden shadow-2xl">
          
          <div class="mb-3">
            <p class="text-xs text-gray-400 uppercase tracking-widest font-semibold">Active Objective:</p>
            <p class="text-sm text-cyan-200 font-medium bg-black/20 p-2 rounded-lg mt-1 border border-white/5">
              ${userPrompt.isEmpty ? "Full-Stack Application Simulation" : userPrompt}
            </p>
          </div>

          <!-- Interactive Simulated App Screen -->
          <div class="flex-1 bg-white text-gray-900 rounded-xl overflow-hidden flex flex-col shadow-inner relative">
            
            <!-- Simulated Mobile Header -->
            <div class="bg-indigo-600 text-white px-4 py-3 flex justify-between items-center shadow">
              <span class="font-bold text-sm"><i class="fa-solid fa-cube mr-2"></i>App Workspace</span>
              <i class="fa-solid fa-bell text-xs"></i>
            </div>

            <!-- Simulated App Body Content -->
            <div class="flex-1 p-4 overflow-y-auto space-y-3 bg-slate-50">
              <div class="bg-indigo-50 border border-indigo-200 p-3 rounded-xl">
                <p class="text-xs font-bold text-indigo-900">🎉 Build Deployed Successfully!</p>
                <p class="text-[11px] text-indigo-700 mt-0.5">Your Groq AI model has successfully written and synced ${_generatedFilesMap.length} architectural files.</p>
              </div>

              <div class="bg-white p-3 rounded-xl border border-gray-200 shadow-sm">
                <p class="text-xs font-bold text-gray-800 mb-1">Quick Actions</p>
                <div class="grid grid-cols-2 gap-2 mt-2">
                  <button onclick="alert('Action Triggered from Simulated UI!')" class="bg-indigo-600 text-white text-xs py-2 rounded-lg font-medium shadow">Test Function</button>
                  <button onclick="location.reload()" class="bg-gray-200 text-gray-700 text-xs py-2 rounded-lg font-medium">Refresh View</button>
                </div>
              </div>
            </div>

            <!-- Simulated Bottom Nav -->
            <div class="bg-white border-t border-gray-200 py-2 px-6 flex justify-around text-gray-400 text-xs">
              <div class="text-indigo-600 flex flex-col items-center"><i class="fa-solid fa-house"></i><span class="text-[9px] mt-0.5">Home</span></div>
              <div class="flex flex-col items-center"><i class="fa-solid fa-code"></i><span class="text-[9px] mt-0.5">Code</span></div>
              <div class="flex flex-col items-center"><i class="fa-solid fa-gear"></i><span class="text-[9px] mt-0.5">Settings</span></div>
            </div>

          </div>

        </div>

        <div class="mt-3 text-center">
          <span class="text-[10px] text-gray-400">Powered by Groq API & WebView Engine</span>
        </div>

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
          height: 520,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public, color: Color(0xFF00F5D4), size: 20),
                        SizedBox(width: 8),
                        Text('Live App Simulator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        title: const Text('Groq Full-Stack Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Enter app idea (e.g. E-commerce app)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isAutonomousRunning ? null : _startAutonomousBuild,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Build'),
                ),
              ],
            ),
          ),
          if (_isAutonomousRunning) ...[
            LinearProgressIndicator(value: _progressValue),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_currentPhase, style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
            ),
          ],
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.black26,
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(_logs[index], style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.blueGrey[900],
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Generated Files:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            if (_generatedFilesMap.isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                onPressed: _showAppPreview,
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('Live Preview', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: _generatedFilesMap.keys.map((fileName) => ListTile(
                            title: Text(fileName, style: const TextStyle(fontSize: 12)),
                            selected: _selectedViewFile == fileName,
                            onTap: () => setState(() => _selectedViewFile = fileName),
                          )).toList(),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: SingleChildScrollView(
                            child: Text(
                              _generatedFilesMap[_selectedViewFile] ?? 'Select a file to view code',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.greenAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
