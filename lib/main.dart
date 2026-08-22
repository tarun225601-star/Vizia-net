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
      title: 'Groq 10k-Crore Web Studio',
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
  String _currentPhase = 'Idle - Ready to build & deploy website.';
  
  final List<String> _logs = [];
  String _generatedWebsiteCode = '';
  String _liveDeploymentUrl = '';

  final List<String> _fallbackModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'llama-3.1-8b-instant',
    'gemma2-9b-it',
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

  void _showSettingsDialog() async {
    final groqKeyController = TextEditingController();
    final userController = TextEditingController();
    final repoController = TextEditingController();
    final tokenController = TextEditingController();
    final vercelTokenController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    groqKeyController.text = prefs.getString('groq_api_key') ?? '';
    userController.text = prefs.getString('github_user') ?? '';
    repoController.text = prefs.getString('github_repo') ?? '';
    tokenController.text = prefs.getString('github_token') ?? '';
    vercelTokenController.text = prefs.getString('vercel_token') ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚙️ Studio, GitHub & Vercel Settings'),
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
              TextField(controller: userController, decoration: const InputDecoration(labelText: 'GitHub Username')),
              const SizedBox(height: 12),
              TextField(controller: repoController, decoration: const InputDecoration(labelText: 'GitHub Repository Name')),
              const SizedBox(height: 12),
              TextField(controller: tokenController, decoration: const InputDecoration(labelText: 'GitHub Token'), obscureText: true),
              const SizedBox(height: 12),
              TextField(controller: vercelTokenController, decoration: const InputDecoration(labelText: 'Vercel Token'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await prefs.setString('groq_api_key', groqKeyController.text.trim());
              await prefs.setString('github_user', userController.text.trim());
              await prefs.setString('github_repo', repoController.text.trim());
              await prefs.setString('github_token', tokenController.text.trim());
              await prefs.setString('vercel_token', vercelTokenController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Settings Saved Successfully!')));
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Future<String> _callGroqAPI(String systemPrompt, String userPrompt) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('groq_api_key')?.trim() ?? '';
    
    if (apiKey.isEmpty) {
      throw Exception('Groq API Key missing! Tap settings icon on top right.');
    }

    for (String model in _fallbackModels) {
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
            "temperature": 0.3,
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
    throw Exception('All models failed. Check your API key.');
  }

  Future<void> _startWebsiteBuildAndDeploy() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter business requirements first!')));
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.2;
      _currentPhase = '🧠 Generating complete website (HTML/CSS/JS)...';
      _logs.clear();
      _liveDeploymentUrl = '';
    });
    _addLog('🚀 Starting Website Generation for: "$userPrompt"');

    try {
      const systemPrompt = '''
You are an expert Frontend Web Developer and UI/UX Designer.
Create a fully functional, beautiful, single-file responsive website (HTML containing embedded CSS and JavaScript) based on the user's business idea.
CRITICAL RULES:
1. Output MUST be ONLY valid HTML code.
2. Use Tailwind CSS via CDN for stunning modern styling.
3. Include interactive JavaScript elements if required by the business logic.
4. NO markdown backticks in the response, start directly with <!DOCTYPE html>.
''';

      String rawCode = await _callGroqAPI(systemPrompt, userPrompt);
      String cleanHtml = _cleanHtmlCode(rawCode);

      setState(() {
        _generatedWebsiteCode = cleanHtml;
        _progressValue = 0.6;
        _currentPhase = '🌐 Pushing code to GitHub...';
      });
      _addLog('✔️ Website code generated successfully.');

      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('github_user') ?? '';
      final repo = prefs.getString('github_repo') ?? '';
      final token = prefs.getString('github_token') ?? '';
      final vercelToken = prefs.getString('vercel_token') ?? '';

      if (user.isEmpty || repo.isEmpty || token.isEmpty || vercelToken.isEmpty) {
        throw Exception('GitHub or Vercel credentials missing in settings!');
      }

      // Push index.html to GitHub
      await _pushFileToGitHub('$user/$repo', token, 'index.html', cleanHtml);
      _addLog('✅ Pushed index.html to GitHub repository.');

      setState(() {
        _progressValue = 0.8;
        _currentPhase = '🚀 Deploying live on Vercel...';
      });

      // Deploy via Vercel API
      String liveUrl = await _deployToVercel(repo, vercelToken);

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = '🎉 Website Live Successfully!';
        _liveDeploymentUrl = liveUrl;
      });
      _addLog('✨ Live Deployment Successful: $liveUrl');

    } catch (e) {
      setState(() => _isAutonomousRunning = false);
      _addLog('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  String _cleanHtmlCode(String raw) {
    String cleaned = raw.trim();
    if (cleaned.contains('```')) {
      int firstBacktick = cleaned.indexOf('```');
      int firstNewLine = cleaned.indexOf('\n', firstBacktick);
      int lastBacktick = cleaned.lastIndexOf('```');
      if (firstNewLine != -1 && lastBacktick > firstNewLine) {
        cleaned = cleaned.substring(firstNewLine + 1, lastBacktick).trim();
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
      "message": "Automated Deployment: Update $path",
      "content": base64Encode(utf8.encode(content)),
      if (sha != null) "sha": sha,
    };
    await http.put(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json'}, body: jsonEncode(body));
  }

  Future<String> _deployToVercel(String repoName, String vercelToken) async {
    final url = Uri.parse('[https://api.vercel.com/v13/deployments](https://api.vercel.com/v13/deployments)');
    final body = {
      "name": repoName.toLowerCase(),
      "gitSource": {
        "type": "github",
        "repo": repoName,
        "org": (await SharedPreferences.getInstance()).getString('github_user') ?? ''
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $vercelToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return "https://${data['url']}";
    } else {
      throw Exception('Vercel Deployment Failed: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groq 10k-Crore Web Studio'),
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
                      hintText: 'Enter business idea (e.g. Local Bakery Store)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isAutonomousRunning ? null : _startWebsiteBuildAndDeploy,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Build & Deploy'),
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
          if (_liveDeploymentUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.tealAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('🚀 Live Website Ready!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _liveDeploymentUrl));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Live URL Copied!')));
                    },
                    child: const Text('Copy Link'),
                  ),
                ],
              ),
            ),
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
                        child: const Text('⚡ Deployment Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        width: double.infinity,
                        child: const Text('Generated Website Code:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: SelectableText(
                                  _generatedWebsiteCode.isEmpty ? 'Enter prompt and click Build & Deploy to generate website...' : _generatedWebsiteCode,
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.greenAccent),
                                ),
                              ),
                              if (_generatedWebsiteCode.isNotEmpty)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _generatedWebsiteCode));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Code Copied!')));
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
