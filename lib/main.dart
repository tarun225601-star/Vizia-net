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
      title: 'Groq 10k-Crore PWA Studio',
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
  String _currentPhase = 'Idle - Ready to build PWA Website.';
  
  final List<String> _logs = [];
  String _generatedWebsiteCode = '';
  String _liveDeploymentUrl = '';

  // सिर्फ एक्टिव और चालू Groq मॉडल्स की सूची
  final List<String> _activeModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
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

    for (String model in _activeModels) {
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
    throw Exception('All active models failed. Check your API key.');
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
      _currentPhase = '🧠 Generating PWA-ready website...';
      _logs.clear();
      _liveDeploymentUrl = '';
    });
    _addLog('🚀 Starting PWA Website Generation for: "$userPrompt"');

    try {
      const systemPrompt = '''
You are an expert Frontend Web Developer and PWA Architect.
Create a fully functional, stunning, single-file responsive PWA website (HTML containing embedded Tailwind CSS, JS, and a complete Web App Manifest inside a <script type="application/manifest+json"> or standard link manifest).
CRITICAL RULES:
1. Output MUST be ONLY valid HTML code starting with <!DOCTYPE html>.
2. Include a inline web app manifest or link tag so mobile browsers detect it as an installable app ("Add to Home Screen").
3. Use Tailwind CSS via CDN for modern styling.
4. NO markdown backticks in the response.
''';

      String rawCode = await _callGroqAPI(systemPrompt, userPrompt);
      String cleanHtml = _cleanHtmlCode(rawCode);

      setState(() {
        _generatedWebsiteCode = cleanHtml;
        _progressValue = 0.6;
        _currentPhase = '🌐 Pushing PWA code to GitHub...';
      });
      _addLog('✔️ PWA website code generated successfully.');

      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('github_user') ?? '';
      final repo = prefs.getString('github_repo') ?? '';
      final token = prefs.getString('github_token') ?? '';
      final vercelToken = prefs.getString('vercel_token') ?? '';

      if (user.isEmpty || repo.isEmpty || token.isEmpty || vercelToken.isEmpty) {
        throw Exception('GitHub or Vercel credentials missing in settings!');
      }

      await _pushFileToGitHub('$user/$repo', token, 'index.html', cleanHtml);
      
      const manifestContent = '''{
  "name": "Generated App",
  "short_name": "App",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0b132b",
  "theme_color": "#00f5d4",
  "icons": [
    {
      "src": "https://img.icons8.com/fluency/96/application.png",
      "sizes": "96x96",
      "type": "image/png"
    }
  ]
}''';
      await _pushFileToGitHub('$user/$repo', token, 'manifest.json', manifestContent);
      _addLog('✅ Pushed index.html & manifest.json to GitHub repository.');

      setState(() {
        _progressValue = 0.8;
        _currentPhase = '🚀 Deploying live on Vercel...';
      });

      String liveUrl = await _deployToVercel(repo, vercelToken);

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = '🎉 PWA Website Live Successfully!';
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
      "message": "PWA Deployment: Update $path",
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

  void _showLiveWebView() {
    if (_liveDeploymentUrl.isEmpty) return;

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_liveDeploymentUrl));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1D3557),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: double.maxFinite,
          height: 550,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('👀 Live Website Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
        title: const Text('Groq 10k-Crore PWA Studio'),
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
                      hintText: 'Enter business idea (e.g. Local Delivery App)...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isAutonomousRunning ? null : _startWebsiteBuildAndDeploy,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Build PWA'),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🚀 PWA Live & Ready!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showLiveWebView,
                        child: const Text('👀 Click here to preview live app inside studio', style: TextStyle(fontSize: 11, color: Colors.white, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                        onPressed: _showLiveWebView,
                        child: const Text('Preview'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _liveDeploymentUrl));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Live PWA URL Copied!')));
                        },
                        child: const Text('Copy Link'),
                      ),
                    ],
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
                        child: const Text('Generated PWA Code:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: SelectableText(
                                  _generatedWebsiteCode.isEmpty ? 'Enter prompt and click Build PWA to generate...' : _generatedWebsiteCode,
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
