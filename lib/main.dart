import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ViziaStudioApp());
}

class ViziaStudioApp extends StatelessWidget {
  const ViziaStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia AI Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.blueAccent,
      ),
      home: const StudioHomeScreen(),
    );
  }
}

class StudioHomeScreen extends StatefulWidget {
  const StudioHomeScreen({super.key});

  @override
  State<StudioHomeScreen> createState() => _StudioHomeScreenState();
}

class _StudioHomeScreenState extends State<StudioHomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String _statusLog = "System Ready. Open Settings to configure keys, then run your AI Agent.";

  // 🚀 Full Replit-Style Agent Pipeline
  Future<void> _runReplitAgent() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    // Load saved API keys from device storage
    final prefs = await SharedPreferences.getInstance();
    String supabaseUrl = prefs.getString('supabase_url') ?? '';
    String supabaseKey = prefs.getString('supabase_key') ?? '';
    String openAiKey = prefs.getString('openai_key') ?? '';
    String githubToken = prefs.getString('github_token') ?? '';
    String repoOwner = prefs.getString('repo_owner') ?? '';
    String repoName = prefs.getString('repo_name') ?? '';

    if (supabaseUrl.isEmpty || openAiKey.isEmpty || githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty) {
      setState(() {
        _statusLog = "Error: Please configure all your API Keys & Repo details in Settings (Gear icon) first!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusLog = "Step 1: AI Agent generating Flutter code via OpenAI (GPT-4o)...";
    });

    try {
      // 1. OpenAI API Call for Code Generation
      final aiResponse = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an elite Flutter developer. Generate clean, fully working, self-contained Dart code for lib/main.dart based on the user prompt. Return ONLY valid Dart code without markdown formatting if possible, or standard code.'
            },
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      String generatedCode = "";
      if (aiResponse.statusCode == 200) {
        final data = jsonDecode(aiResponse.body);
        generatedCode = data['choices'][0]['message']['content'];
        generatedCode = generatedCode.replaceAll('```dart', '').replaceAll('```', '').trim();
      } else {
        throw Exception("OpenAI Error: ${aiResponse.body}");
      }

      setState(() {
        _statusLog = "Step 2: Saving logs to Supabase Database...";
      });

      // 2. Supabase Integration & Saving Data
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      final supabase = Supabase.instance.client;
      
      await supabase.from('ai_logs').insert({
        'prompt': prompt,
        'response': generatedCode,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _statusLog = "Step 3: Creating/Updating 'lib/main.dart' file directly inside GitHub Repository...";
      });

      // 3. GitHub Contents API to create/update file (lib/main.dart)
      const filePath = 'lib/main.dart';
      final fileUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$filePath');

      String? fileSha;
      final getFileRes = await http.get(
        fileUrl,
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (getFileRes.statusCode == 200) {
        final fileData = jsonDecode(getFileRes.body);
        fileSha = fileData['sha'];
      }

      String base64EncodedCode = base64Encode(utf8.encode(generatedCode));

      final Map<String, dynamic> bodyData = {
        'message': 'AI Agent update: built app for prompt -> $prompt',
        'content': base64EncodedCode,
        'branch': 'main',
      };
      if (fileSha != null) {
        bodyData['sha'] = fileSha;
      }

      final putFileRes = await http.put(
        fileUrl,
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      if (putFileRes.statusCode != 200 && putFileRes.statusCode != 201) {
        throw Exception("GitHub File Push Error: ${putFileRes.body}");
      }

      setState(() {
        _statusLog = "Step 4: Triggering GitHub Actions Workflow to build APK...";
      });

      // 4. GitHub Actions Workflow Dispatch API Call
      final dispatchUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/dispatches');
      final dispatchRes = await http.post(
        dispatchUrl,
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        body: jsonEncode({
          'event_type': 'build_apk_trigger',
          'client_payload': {'prompt': prompt}
        }),
      );

      if (dispatchRes.statusCode == 204) {
        setState(() {
          _statusLog = "Success! AI Agent wrote code, pushed 'lib/main.dart' to GitHub, saved to Supabase, and triggered APK Build!\nCheck your GitHub Actions tab.";
          _isLoading = false;
        });
      } else {
        throw Exception("GitHub Dispatch Error: ${dispatchRes.body}");
      }

    } catch (e) {
      setState(() {
        _statusLog = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia AI Agent Studio'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Configure API Keys',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What app do you want the AI Agent to build?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Create a modern crypto portfolio tracker screen...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isLoading ? null : _runReplitAgent,
              icon: const Icon(Icons.auto_awesome),
              label: _isLoading 
                ? const Text('Agent is Working...') 
                : const Text('Run AI Agent & Build APK', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Live Execution Console:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _statusLog,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
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

// ⚙️ Settings Screen: To Enter OpenAI, Supabase & GitHub Keys
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();
  final TextEditingController _openAiKeyController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _repoOwnerController = TextEditingController();
  final TextEditingController _repoNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _supabaseUrlController.text = prefs.getString('supabase_url') ?? '';
      _supabaseKeyController.text = prefs.getString('supabase_key') ?? '';
      _openAiKeyController.text = prefs.getString('openai_key') ?? '';
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _repoOwnerController.text = prefs.getString('repo_owner') ?? '';
      _repoNameController.text = prefs.getString('repo_name') ?? '';
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', _supabaseUrlController.text.trim());
    await prefs.setString('supabase_key', _supabaseKeyController.text.trim());
    await prefs.setString('openai_key', _openAiKeyController.text.trim());
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('repo_owner', _repoOwnerController.text.trim());
    await prefs.setString('repo_name', _repoNameController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All API Keys Saved Successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys & Repo Settings'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Enter your keys below. They are saved securely on your device.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(controller: _supabaseUrlController, decoration: const InputDecoration(labelText: 'Supabase URL', filled: true, fillColor: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            TextField(controller: _supabaseKeyController, decoration: const InputDecoration(labelText: 'Supabase Anon Key', filled: true, fillColor: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            TextField(controller: _openAiKeyController, decoration: const InputDecoration(labelText: 'OpenAI API Key (GPT-4o)', filled: true, fillColor: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            TextField(controller: _githubTokenController, decoration: const InputDecoration(labelText: 'GitHub Personal Access Token', filled: true, fillColor: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            TextField(controller: _repoOwnerController, decoration: const InputDecoration(labelText: 'GitHub Username', filled: true, fillColor: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            TextField(controller: _repoNameController, decoration: const InputDecoration(labelText: 'GitHub Repository Name', filled: true, fillColor: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveKeys,
              child: const Text('Save All Keys', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
