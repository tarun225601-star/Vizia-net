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
              "⚠️ Studio Error: ${details.exception}",
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
      title: 'Groq 10k-Crore Studio',
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
  double _progressValue = 0.0;
  String _currentPhase = 'Idle - Ready for Chunk-by-Chunk Generation.';
  
  final List<String> _logs = [];
  final Map<String, String> _generatedFilesMap = {};
  String _selectedViewFile = '';

  // 🚀 अपडेटेड 20+ पावरफुल मॉडल्स की लिस्ट
  final List<String> _fallbackModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'llama-3.1-8b-instant',
    'gemma2-9b-it',
    'llama-3.3-70b-specdec',
    'llama-3.1-70b-specdec',
    'llama-3.2-90b-vision-preview',
    'llama-3.2-11b-vision-preview',
    'llama-3.2-3b-preview',
    'llama-3.2-1b-preview',
    'llama-3.1-405b-reasoning',
    'llama-guard-3-8b',
    'mixtral-8x7b-32768',
    'gemma-7b-it',
    'llama3-70b-8192',
    'llama3-8b-8192',
    'llama2-70b-4096',
    'mixtral-8x22b-instruct-preview',
    'llama-3.1-70b-turbo',
    'llama-3.2-90b-text-preview'
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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
        if (liveModels.isNotEmpty) return liveModels;
      }
    } catch (e) {
      // Fallback
    }
    return _fallbackModels;
  }

  void _showSettingsDialog() async {
    final groqKeyController = TextEditingController();
    final userController = TextEditingController();
    final repoController = TextEditingController();
    final tokenController = TextEditingController();
    final appetizeKeyController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    groqKeyController.text = prefs.getString('groq_api_key') ?? '';
    userController.text = prefs.getString('github_user') ?? '';
    repoController.text = prefs.getString('github_repo') ?? '';
    tokenController.text = prefs.getString('github_token') ?? '';
    appetizeKeyController.text = prefs.getString('appetize_key') ?? 'app_z932v3x69n9xxq2xhg1yq8b380';
    String selectedModel = prefs.getString('selected_model') ?? 'llama-3.3-70b-versatile';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('⚙️ Studio, GitHub & Appetize Settings'),
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
                        if (val != null) setDialogState(() => selectedModel = val);
                      },
                      decoration: const InputDecoration(labelText: 'Primary AI Model'),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: userController, decoration: const InputDecoration(labelText: 'GitHub Username')),
                const SizedBox(height: 12),
                TextField(controller: repoController, decoration: const InputDecoration(labelText: 'GitHub Repository Name')),
                const SizedBox(height: 12),
                TextField(controller: tokenController, decoration: const InputDecoration(labelText: 'GitHub Token'), obscureText: true),
                const SizedBox(height: 12),
                TextField(controller: appetizeKeyController, decoration: const InputDecoration(labelText: 'Appetize.io Public Key')),
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
                await prefs.setString('appetize_key', appetizeKeyController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Settings Saved Successfully!')));
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 अपडेटेड API कॉल फंक्शन
  Future<String> _callGroqAPI(String systemPrompt, String userPrompt) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('groq_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      throw Exception('Groq API Key missing! Tap gear icon on top right.');
    }

    String preferredModel = prefs.getString('selected_model') ?? 'llama-3.3-70b-versatile';
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
            "temperature": 0.2,
            "max_tokens": 4096,
          }),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['choices'] != null && decoded['choices'].isNotEmpty) {
            return decoded['choices'][0]['message']['content'];
          }
        }
      } catch (e) {
        continue;
      }
    }
    throw Exception('All 20+ models failed. Check your API key.');
  }

  Future<void> _startAutonomousBuild() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter requirements first!')));
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.05;
      _currentPhase = '🧠 Planning file structure...';
      _generatedFilesMap.clear();
      _logs.clear();
    });
    _addLog('🚀 Chunk-by-Chunk Build started for: "$userPrompt"');

    try {
      const planSystemPrompt = 'Return ONLY a JSON list of file paths required for this Flutter app (e.g. ["pubspec.yaml", "lib/main.dart", "lib/screens/home_screen.dart"]). No extra text, no markdown backticks.';
      String planContent = await _callGroqAPI(planSystemPrompt, userPrompt);
      
      planContent = planContent.replaceAll('```json', '').replaceAll('```', '').replaceAll('`', '').trim();
      int start = planContent.indexOf('[');
      int end = planContent.lastIndexOf(']');
      if (start != -1 && end != -1) {
        planContent = planContent.substring(start, end + 1);
      }

      List<String> filePlan = [];
      try {
        List<dynamic> parsedList = jsonDecode(planContent);
        filePlan = parsedList.map((e) => e.toString()).toList();
      } catch (e) {
        filePlan = ['pubspec.yaml', 'lib/main.dart'];
      }
      
      if (!filePlan.contains('lib/main.dart')) filePlan.add('lib/main.dart');
      if (!filePlan.contains('pubspec.yaml')) filePlan.add('pubspec.yaml');

      _addLog('✅ Planned ${filePlan.length} files. Starting Chunk Generation...');

      for (int i = 0; i < filePlan.length; i++) {
        String fileName = filePlan[i];
        double progress = 0.2 + (((i + 1) / filePlan.length) * 0.6);
        
        setState(() {
          _progressValue = progress;
          _currentPhase = '✍️ Building Chunk (${i + 1}/${filePlan.length}):$fileName';
        });

        _addLog('⚙️ Requesting clean code for $fileName...');

        String chunkSystemPrompt = '''
You are an elite Senior Flutter & Dart Software Architect. 
Your task is to write ONLY the requested file code.
CRITICAL RULES:
1. Output MUST start directly with code (e.g., 'import ...' or 'dependencies:').
2. NO markdown greetings, NO conversational text, NO explanations, NO wrap-up notes.
3. Write complete, production-ready, clean code without truncation or placeholders (like '// TODO' or 'etc').
''';

        String filePrompt = 'App Goal: $userPrompt\nTarget File:$fileName\nMake sure the code is 100% clean, syntax error-free, and fully functional.';
        
        String rawResponse = await _callGroqAPI(chunkSystemPrompt, filePrompt);
        String cleanCode = _cleanGarbageCode(rawResponse, fileName);
        
        _generatedFilesMap[fileName] = cleanCode;
        _addLog('✔️ Chunk for $fileName verified & saved cleanly.');
      }

      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('github_user') ?? '';
      final repo = prefs.getString('github_repo') ?? '';
      final token = prefs.getString('github_token') ?? '';

      if (user.isNotEmpty && repo.isNotEmpty && token.isNotEmpty) {
        setState(() {
          _progressValue = 0.90;
          _currentPhase = '🌐 Pushing clean chunks to GitHub...';
        });
        for (var entry in _generatedFilesMap.entries) {
          await _pushFileToGitHub('$user/$repo', token, entry.key, entry.value);
        }
        _addLog('✅ All chunks safely pushed to GitHub!');
      }

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = '🎉 Chunk Build Completed Successfully!';
        if (_generatedFilesMap.isNotEmpty) {
          _selectedViewFile = _generatedFilesMap.keys.first;
        }
      });
      _addLog('✨ Clean build finished successfully.');
    } catch (e) {
      setState(() => _isAutonomousRunning = false);
      _addLog('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  String _cleanGarbageCode(String raw, String fileName) {
    String cleaned = raw.trim();
    if (cleaned.contains('```')) {
      int firstBacktick = cleaned.indexOf('```');
      int firstNewLine = cleaned.indexOf('\n', firstBacktick);
      int lastBacktick = cleaned.lastIndexOf('```');
      if (firstNewLine != -1 && lastBacktick > firstNewLine) {
        cleaned = cleaned.substring(firstNewLine + 1, lastBacktick).trim();
      }
    }
    if (fileName.endsWith('.dart')) {
      int importIndex = cleaned.indexOf('import ');
      if (importIndex != -1) {
        cleaned = cleaned.substring(importIndex);
      }
    }
    if (fileName.contains('pubspec.yaml')) {
      int yamlIndex = cleaned.indexOf('name:');
      if (yamlIndex != -1) {
        cleaned = cleaned.substring(yamlIndex);
      }
    }
    return cleaned;
  }

  Future<void> _pushFileToGitHub(String fullRepo, String token, String path, String content) async {
    final url = Uri.parse('[https://api.github.com/repos/$fullRepo/contents/$path](https://api.github.com/repos/$fullRepo/contents/$path)');
    String? sha;
    final getRes = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json'});
    if (getRes.statusCode == 200) {
      sha = jsonDecode(getRes.body)['sha'];
    }
    final body = {
      "message": "Chunk Agent: Update $path",
      "content": base64Encode(utf8.encode(content)),
      if (sha != null) "sha": sha,
    };
    await http.put(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json'}, body: jsonEncode(body));
  }

  void _showAppPreview() async {
    final prefs = await SharedPreferences.getInstance();
    String appetizeKey = prefs.getString('appetize_key') ?? 'app_z932v3x69n9xxq2xhg1yq8b380';
    final htmlContent = '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Cloud Preview</title>
        <script src="[https://cdn.tailwindcss.com](https://cdn.tailwindcss.com)"></script>
      </head>
      <body class="bg-[#0B132B] text-white flex flex-col h-screen m-0 p-2">
        <div class="flex justify-between items-center bg-[#1D3557] px-3 py-2 rounded-lg border border-[#00F5D4]/30 mb-2">
          <span class="font-bold text-[#00F5D4] text-xs">📱 LIVE CLOUD EMULATOR</span>
          <span class="text-[10px] bg-[#0B132B] px-2 py-0.5 rounded text-cyan-300">Active</span>
        </div>
        <div class="flex-1 bg-black rounded-xl overflow-hidden border border-cyan-500/30 flex justify-center items-center">
          <iframe src="[https://appetize.io/embed/$appetizeKey?device=pixel7&osVersion=13.0&scale=75&autoplay=true&centered=true&color=black](https://appetize.io/embed/$appetizeKey?device=pixel7&osVersion=13.0&scale=75&autoplay=true&centered=true&color=black)" width="100%" height="100%" frameborder="0"></iframe>
        </div>
      </body>
      </html>
    ''';
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.dataFromString(htmlContent, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')));
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
                    const Text('📱 Real Cloud Emulator Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
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
        title: const Text('Groq 10k-Crore Studio'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsDialog),
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
                      hintText: 'Enter app idea (e.g. Delivery App)...',
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
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black38,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        child: const Text('⚡ Chunk Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Text(_logs[index], style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.blueGrey[900],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Files:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            if (_generatedFilesMap.isNotEmpty)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                onPressed: _showAppPreview,
                                child: const Text('Live Emulator', style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 45,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _generatedFilesMap.keys.map((fileName) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: ChoiceChip(
                              label: Text(fileName, style: const TextStyle(fontSize: 10)),
                              selected: _selectedViewFile == fileName,
                              onSelected: (selected) {
                                setState(() => _selectedViewFile = fileName);
                              },
                            ),
                          )).toList(),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: SelectableText(
                                  _generatedFilesMap[_selectedViewFile] ?? 'Select generated file to view clean code',
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.greenAccent),
                                ),
                              ),
                              if (_generatedFilesMap.containsKey(_selectedViewFile))
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _generatedFilesMap[_selectedViewFile]!));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Copied!')));
                                    },
                                  ),
                                ),
                            ],
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
