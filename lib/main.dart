import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vizia AI Studio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.blueAccent,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _statusLog = "Ready to build your app...";

  // यहाँ पर तेरा एजेंट वाला फंक्शन आएगा जो गिटहब पर पुश करेगा
  Future<void> _runAgent() async {
    setState(() {
      _statusLog = "Starting AI Agent...";
    });
    // अपना एजेंट कोड यहाँ रख सकते हैं
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia AI Agent Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your app prompt here (e.g., Build a calculator app)...',
                filled: true,
                fillColor: Color(0xFF1E293B),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runAgent,
              child: const Text('Build App with AI'),
            ),
            const SizedBox(height: 20),
            Text(
              _statusLog,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Settings Screen ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();
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
      _groqKeyController.text = prefs.getString('groq_key') ?? '';
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _repoOwnerController.text = prefs.getString('repo_owner') ?? '';
      _repoNameController.text = prefs.getString('repo_name') ?? '';
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', _supabaseUrlController.text.trim());
    await prefs.setString('supabase_key', _supabaseKeyController.text.trim());
    await prefs.setString('groq_key', _groqKeyController.text.trim());
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
      appBar: AppBar(title: const Text('API Keys & Repository Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _groqKeyController, decoration: const InputDecoration(labelText: 'Groq API Key', filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          TextField(controller: _githubTokenController, decoration: const InputDecoration(labelText: 'GitHub Personal Access Token', filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          TextField(controller: _repoOwnerController, decoration: const InputDecoration(labelText: 'Repository Owner (username)', filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          TextField(controller: _repoNameController, decoration: const InputDecoration(labelText: 'Repository Name', filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _saveKeys, child: const Text('Save Settings')),
        ],
      ),
    );
  }
}
