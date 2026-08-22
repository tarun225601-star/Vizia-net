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
      title: 'Groq 10k-Crore PWA Studio Pro',
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
  bool _isFetchingModels = false;
  double _progressValue = 0.0;
  String _currentPhase = 'Idle - Ready for Multi-Step Autonomous PWA Generation.';
  
  final List<String> _logs = [];
  String _generatedWebsiteCode = '';
  String _liveDeploymentUrl = '';

  List<String> _modelsList = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant'
  ];
  String _selectedModel = 'llama-3.3-70b-versatile';

  @override
  void initState() {
    super.initState();
    _fetchActiveModelsFromGroq();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
        0, 
        '[${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}] $message'
      );
    });
  }

  Future<void> _fetchActiveModelsFromGroq() async {
    setState(() => _isFetchingModels = true);
    _addLog('🔄 Fetching clean active chat models from Groq...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final groqKey = prefs.getString('groq_api_key') ?? '';

      if (groqKey.isEmpty) {
        _addLog('⚠️ Groq API Key is empty. Please set it in Settings.');
        setState(() => _isFetchingModels = false);
        return;
      }

      final url = Uri.parse('https://api.groq.com/openai/v1/models');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $groqKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List modelsData = data['data'];
        
        List<String> fetchedModels = [];
        for (var model in modelsData) {
          String modelId = model['id'];
          if ((modelId.contains('llama') || modelId.contains('mixtral') || modelId.contains('gemma') || modelId.contains('gpt')) &&
              !modelId.contains('guard') && 
              !modelId.contains('safeguard') &&
              !modelId.contains('embed') && 
              !modelId.contains('whisper') &&
              !modelId.contains('moderation')) {
            fetchedModels.add(modelId);
          }
        }

        if (fetchedModels.isNotEmpty) {
          setState(() {
            _modelsList = fetchedModels;
            if (!_modelsList.contains(_selectedModel)) {
              _selectedModel = _modelsList.first;
            }
          });
          _addLog('✅ Success! Loaded ${_modelsList.length} pure chat models.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🔥 Loaded ${_modelsList.length} active chat models!')),
          );
        } else {
          _addLog('❌ No valid chat models found.');
        }
      } else {
        _addLog('❌ Failed to fetch models: ${response.body}');
      }
    } catch (e) {
      _addLog('❌ Error fetching models: $e');
    } finally {
      setState(() => _isFetchingModels = false);
    }
  }

  void _showSettingsDialog() async {
    final userController = TextEditingController();
    final repoController = TextEditingController();
    final tokenController = TextEditingController();
    final vercelTokenController = TextEditingController();
    final groqKeyController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    userController.text = prefs.getString('github_user') ?? '';
    repoController.text = prefs.getString('github_repo') ?? '';
    tokenController.text = prefs.getString('github_token') ?? '';
    vercelTokenController.text = prefs.getString('vercel_token') ?? '';
    groqKeyController.text = prefs.getString('groq_api_key') ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚙️ Studio Configuration Center'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: userController, decoration: const InputDecoration(labelText: 'GitHub Username')),
              const SizedBox(height: 12),
              TextField(controller: repoController, decoration: const InputDecoration(labelText: 'GitHub Repository Name')),
              const SizedBox(height: 12),
              TextField(controller: tokenController, decoration: const InputDecoration(labelText: 'GitHub Personal Token'), obscureText: true),
              const SizedBox(height: 12),
              TextField(controller: vercelTokenController, decoration: const InputDecoration(labelText: 'Vercel Deployment Token'), obscureText: true),
              const SizedBox(height: 12),
              TextField(controller: groqKeyController, decoration: const InputDecoration(labelText: 'Groq API Key'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await prefs.setString('github_user', userController.text.trim());
              await prefs.setString('github_repo', repoController.text.trim());
              await prefs.setString('github_token', tokenController.text.trim());
              await prefs.setString('vercel_token', vercelTokenController.text.trim());
              await prefs.setString('groq_api_key', groqKeyController.text.trim());
              Navigator.pop(context);
              
              _fetchActiveModelsFromGroq();
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Credentials Saved & Models Refreshing!')));
            },
            child: const Text('Save & Fetch Models'),
          ),
        ],
      ),
    );
  }

  // 🚀 उन्नत और मजबूत Groq API कॉल जो बिना टोकन कट किए फुल-लॉजिक कोड जनरेट करेगा
  Future<String> _generateCodeViaGroq(String userPrompt) async {
    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_api_key') ?? '';

    if (groqKey.isEmpty) {
      throw Exception('Groq API Key is missing! Please configure it in settings.');
    }

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $groqKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": _selectedModel,
        "messages": [
          {
            "role": "system",
            "content": "You are the world's most elite full-stack master developer and AI architect. Your task is to build a completely functional, enterprise-grade, production-ready single-file PWA website. CRITICAL RULES: 1. Every single button, filter tab, search bar, cart drawer, and interactive form MUST have complete, error-free vanilla JavaScript logic embedded. NO dummy buttons, NO missing functions. 2. Use pure Tailwind CSS via CDN or embedded internal styles cleanly. 3. Ensure local storage persistence for state (cart, products, user sessions). 4. Return ONLY raw HTML code without markdown block wrappers."
          },
          {
            "role": "user",
            "content": "Build a comprehensive, fully interactive web application for the following business requirements: $userPrompt"
          }
        ],
        "temperature": 0.4,
        "max_tokens": 8000
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String content = data['choices'][0]['message']['content'];
      content = content.replaceAll('```html', '').replaceAll('```', '').trim();
      return content;
    } else {
      throw Exception('Groq API Error: ${response.body}');
    }
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
      _currentPhase = '🤖 Phase 1: Analyzing architecture & structuring modules...';
      _logs.clear();
      _liveDeploymentUrl = '';
    });
    _addLog('🚀 Starting Autonomous Enterprise Build for: "$userPrompt" using $_selectedModel');

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _progressValue = 0.5;
        _currentPhase = '💻 Phase 2: Writing bulletproof backend logic & UI components via Groq...';
      });
      _addLog('⚙️ Executing deep neural generation with full script wiring...');

      String cleanHtml = await _generateCodeViaGroq(userPrompt);

      setState(() {
        _generatedWebsiteCode = cleanHtml;
        _progressValue = 0.8;
        _currentPhase = '🚀 Phase 3: Pushing independent deployment bundle to Vercel cloud...';
      });
      _addLog('✔️ Complete working code generated successfully.');

      final prefs = await SharedPreferences.getInstance();
      final vercelToken = prefs.getString('vercel_token') ?? '';

      if (vercelToken.isEmpty) {
        throw Exception('Vercel Token missing in settings!');
      }

      String sanitizedPrompt = userPrompt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (sanitizedPrompt.length > 8) sanitizedPrompt = sanitizedPrompt.substring(0, 8);
      String uniqueProjectName = 'pwa-$sanitizedPrompt-${DateTime.now().millisecondsSinceEpoch}';

      String liveUrl = await _deployDirectlyToVercel(uniqueProjectName, cleanHtml, vercelToken);

      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = '🎉 Enterprise PWA Live Successfully!';
        _liveDeploymentUrl = liveUrl;
      });
      _addLog('✨ Live Deployment Successful: $liveUrl');

    } catch (e) {
      setState(() => _isAutonomousRunning = false);
      _addLog('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  Future<String> _deployDirectlyToVercel(String uniqueProjectName, String htmlContent, String vercelToken) async {
    final url = Uri.parse('https://api.vercel.com/v13/deployments');
    
    final body = {
      "name": uniqueProjectName,
      "files": [
        {
          "file": "index.html",
          "data": htmlContent
        }
      ],
      "projectSettings": {
        "framework": null
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
      if (data['url'] != null) {
        return "https://${data['url']}";
      } else if (data['name'] != null) {
        return "https://${data['name']}.vercel.app";
      }
      throw Exception('Deployment response missing URL');
    } else {
      throw Exception('Vercel Direct Deployment Failed: ${response.body}');
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        title: const Text('Groq 10k-Crore PWA Studio Pro'),
        actions: [
          IconButton(
            icon: _isFetchingModels 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.refresh),
            tooltip: 'Refresh Active Models',
            onPressed: _fetchActiveModelsFromGroq,
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Model: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _modelsList.contains(_selectedModel) ? _selectedModel : _modelsList.first,
                            isExpanded: true,
                            items: _modelsList.map((model) => DropdownMenuItem(
                              value: model,
                              child: Text(model, style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedModel = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'Enter business idea (e.g. Multi-vendor Marketplace)...',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
