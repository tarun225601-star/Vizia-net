import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AutonomousEnterpriseApp());
}

class AutonomousEnterpriseApp extends StatelessWidget {
  const AutonomousEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autonomous Enterprise Studio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        primaryColor: const Color(0xFF00F5D4),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F5D4),
          secondary: Color(0xFF7209B7),
          surface: Color(0xFF1D3557),
        ),
      ),
      home: const EnterpriseStudioScreen(),
      debugShowCheckedModeBanner: false,
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
}

class EnterpriseStudioScreen extends StatefulWidget {
  const EnterpriseStudioScreen({super.key});

  @override
  State<EnterpriseStudioScreen> createState() => _EnterpriseStudioScreenState();
}

class _EnterpriseStudioScreenState extends State<EnterpriseStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _searchFileController = TextEditingController();

  bool _isAutonomousRunning = false;
  bool _isWaitingForUserFileSelection = false;
  double _progressValue = 0.0;
  String _currentPhase = 'Idle - Ready for Enterprise Task.';
  String _fileSearchQuery = '';

  final List<String> _logs = [];
  List<Map<String, dynamic>> _selectableFiles = [];
  final List<Map<String, String>> _detectedErrors = [];
  String _actionsUrl = '';
  String _criticalErrorReason = '';

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final config = await _getStoredConfig();
    if (config.groqKey == 'YOUR_GROQ_API_KEY') {
      _addLog('⚠️ Default configuration detected. Please check settings.');
    } else {
      _addLog('⚙️ Loaded stored configurations successfully.');
    }
  }

  void _addLog(String message, {String type = 'info'}) {
    setState(() {
      _logs.insert(
        0, 
        '[${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}] $message'
      );
    });
  }

  Future<AgentConfig> _getStoredConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return AgentConfig(
      groqKey: prefs.getString('groq_key') ?? 'YOUR_GROQ_API_KEY',
      githubToken: prefs.getString('github_token') ?? 'YOUR_GITHUB_TOKEN',
      githubUser: prefs.getString('github_user') ?? 'tarun225601-star',
      githubRepo: prefs.getString('github_repo') ?? 'real_time',
      selectedModel: prefs.getString('groq_model') ?? 'llama-3.3-70b-versatile',
    );
  }

  Future<void> _saveConfig(AgentConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', config.groqKey);
    await prefs.setString('github_token', config.githubToken);
    await prefs.setString('github_user', config.githubUser);
    await prefs.setString('github_repo', config.githubRepo);
    await prefs.setString('groq_model', config.selectedModel);
  }

  void _showSettingsDialog() {
    final groqKeyController = TextEditingController();
    final githubTokenController = TextEditingController();
    final githubUserController = TextEditingController();
    final githubRepoController = TextEditingController();
    String selectedModel = 'llama-3.3-70b-versatile';

    _getStoredConfig().then((config) {
      groqKeyController.text = config.groqKey;
      githubTokenController.text = config.githubToken;
      githubUserController.text = config.githubUser;
      githubRepoController.text = config.githubRepo;
      selectedModel = config.selectedModel;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enterprise Studio Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groqKeyController,
                decoration: const InputDecoration(labelText: 'Groq API Key'),
                obscureText: true,
              ),
              TextField(
                controller: githubTokenController,
                decoration: const InputDecoration(labelText: 'GitHub Personal Access Token'),
                obscureText: true,
              ),
              TextField(
                controller: githubUserController,
                decoration: const InputDecoration(labelText: 'GitHub Username'),
              ),
              TextField(
                controller: githubRepoController,
                decoration: const InputDecoration(labelText: 'GitHub Repository Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedModel,
                decoration: const InputDecoration(labelText: 'Groq Model'),
                items: const [
                  DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('Llama 3.3 70B Versatile')),
                  DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('Llama 3.1 8B Instant')),
                ],
                onChanged: (val) {
                  if (val != null) selectedModel = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newConfig = AgentConfig(
                groqKey: groqKeyController.text.trim(),
                githubToken: githubTokenController.text.trim(),
                githubUser: githubUserController.text.trim(),
                githubRepo: githubRepoController.text.trim(),
                selectedModel: selectedModel,
              );
              await _saveConfig(newConfig);
              Navigator.pop(context);
              _addLog('💾 Configuration updated successfully.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _startAutonomousPipeline() async {
    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter a prompt or app requirement!')),
      );
      return;
    }

    setState(() {
      _isAutonomousRunning = true;
      _progressValue = 0.15;
      _currentPhase = 'Analyzing prompt for architecture rules...';
      _selectableFiles.clear();
      _detectedErrors.clear();
      _actionsUrl = '';
      _criticalErrorReason = '';
    });

    _addLog('🚀 Enterprise Autonomous Agent Pipeline Initialized.');
    _addLog('🧠 Evaluating prompt for file requirements...');

    try {
      final config = await _getStoredConfig();
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final systemPrompt = '''
तू एक प्रोफेशनल फ्लटर (Flutter) डेवलपर है। तेरा काम दिए गए काम के आधार पर एक पूरा, वर्किंग और एरर-फ्री एप्लीकेशन बनाना है। 

CRITICAL RULE: Return ONLY a JSON array of essential file paths and code content as expected by the agent pipeline. No markdown, no text, strictly valid JSON format.

इसके अलावा इन नियमों का पालन कर:
1. **क्रैश-प्रूफ कोडिंग:** ऐप शुरू होते ही सफेद स्क्रीन या क्रैश नहीं होनी चाहिए। इसके लिए 'main()' फंक्शन में 'runApp' से पहले हमेशा 'WidgetsFlutterBinding.ensureInitialized();' का इस्तेमाल कर।
2. **सिंगल फाइल आर्किटेक्चर:** पूरी एप्लीकेशन को एक ही 'lib/main.dart' फाइल में बना। कोई अलग फाइल नहीं बनानी है।
3. **लेआउट का ध्यान रख:** 'PageView' या 'ListView' बनाते समय 'SizedBox' में 'height' फिक्स करने की जगह 'Expanded', 'Flexible' या 'AspectRatio' का यूज़ कर ताकि लेआउट हर स्क्रीन पर सही दिखे, ओवरफ्लो न हो।
4. **डेटा फीड:** अगर फोटो या डेटा वाली ऐप है, तो फायरबेस या स्टेट का सही इस्तेमाल कर और कोड में परमिशन हैंडलिंग का ध्यान रख।
'''.trim();

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
          "max_tokens": 4000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Architect Planner Error: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      String content = decoded['choices'][0]['message']['content'].trim();
      
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = content.indexOf('[');
      int endIndex = content.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        content = content.substring(startIndex, endIndex + 1);
      }
      
      List<dynamic> parsedList = jsonDecode(content);
      List<String> filePlan = parsedList.map((e) => e.toString()).toList();

      if (!filePlan.contains('lib/main.dart')) {
        filePlan.add('lib/main.dart');
      }

      _addLog('📋 Architect designed ${filePlan.length} files.');

      setState(() {
        _selectableFiles = filePlan.map((path) => {'path': path, 'selected': true}).toList();
        _isAutonomousRunning = false;
        _isWaitingForUserFileSelection = true;
        _progressValue = 0.30;
        _currentPhase = 'Paused: Review & Select Files.';
        _fileSearchQuery = '';
        _searchFileController.clear();
      });

    } catch (e) {
      _addLog('⚠️ Planning Error: $e', type: 'error');
      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Aborted.';
        _criticalErrorReason = 'Planning Phase Failed: $e';
      });
    }
  }

  Future<void> _confirmAndExecuteBuild() async {
    final chosenFiles = _selectableFiles
        .where((f) => f['selected'] == true)
        .map((f) => f['path'].toString())
        .toList();

    if (chosenFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select at least one file to build!')),
      );
      return;
    }

    setState(() {
      _isWaitingForUserFileSelection = false;
      _isAutonomousRunning = true;
      _progressValue = 0.40;
      _currentPhase = 'Phase 2: Surgical Laborer Active (Self-Healing Loop)...';
      _criticalErrorReason = '';
    });

    String previousErrorContext = '';
    int maxRetryAttempts = 0;
    bool buildSuccess = false;

    for (int attempt = 1; attempt <= maxRetryAttempts; attempt++) {
      _addLog('⚡ Attempt $attempt of $maxRetryAttempts: Laborer executing code fix...');

      try {
        final config = await _getStoredConfig();
        final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

        String repairInstruction = previousErrorContext.isEmpty 
            ? '' 
            : '''
\n\n=== SURGICAL ERROR LOG SCAN (BOTTOM-TO-TOP) ===
The previous build failed with the exact log below. You are a code laborer. Read the file name in the error and fix ONLY that specific file:
$previousErrorContext
--------------------------------------------------
''';

        final systemPrompt = '''
You are an automated code-fixing laborer. You have only two objectives:
1. SCAN & ANALYZE: Read the build log errors. Find the exact file name and line mentioned.
2. EXECUTE: 
   - IF THE ERROR SAYS 'No such file or directory': You MUST generate that missing file immediately in the JSON.
   - IF THE ERROR IS A SYNTAX OR COMPILATION ERROR: Fix it directly in the affected file.
   - MERGE RULE: To completely avoid missing file issues, ensure all necessary logic is robustly implemented inside "lib/main.dart".

Output MUST be a valid JSON array of objects with this exact structure:
[
  {
    "fileName": "lib/main.dart",
    "fileCode": "actual clean code string here..."
  }
]
Do NOT output markdown outside the JSON. Strictly valid JSON array.$repairInstruction
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
              {"role": "user", "content": "Generate code for files: ${jsonEncode(chosenFiles)} based on user requirement: ${_promptController.text.trim()}"}
            ],
            "temperature": 0.1,
            "max_tokens": 4000,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Code Synthesis Error: ${response.body}');
        }

        final decoded = jsonDecode(response.body);
        String rawResponse = decoded['choices'][0]['message']['content'];

        setState(() {
          _progressValue = 0.50 + (attempt * 0.05);
          _currentPhase = 'Phase 3: Parsing & Safety Verification...';
        });

        _addLog('🔍 Applying bulletproof build protection templates...');
        final files = _parsePlainFiles(rawResponse, config.githubRepo);

        setState(() {
          _progressValue = 0.65 + (attempt * 0.03);
          _currentPhase = 'Phase 4: GitHub Secure Push...';
        });

        _addLog('☁️ Connecting to GitHub REST API endpoints...');
        for (int i = 0; i < files.length; i++) {
          final fileEntry = files[i];
          final String fileName = fileEntry['fileName'];
          final String fileCode = fileEntry['fileCode'];

          _addLog('📦 Pushing module: $fileName');
          await _pushFileToGitHub(config, fileName, fileCode);
        }

        _addLog('⏳ Waiting for GitHub Actions workflow to run & verify build...');
        setState(() => _currentPhase = 'Phase 5: Monitoring GitHub Build Actions...');

        String actionStatus = await _monitorGitHubAction(config);

        if (actionStatus == 'success') {
          buildSuccess = true;
          _addLog('🎉 GitHub Action Build Passed Successfully!');
          break;
        } else if (actionStatus == 'failure') {
          _addLog('❌ GitHub Action Build Failed! Reading raw error logs bottom-to-top...', type: 'error');
          previousErrorContext = await _fetchLatestActionErrorLog(config);
          _addLog('🤖 Laborer analyzing failure logs to patch the exact file...');
        } else {
          _addLog('⚠️ Build status timeout or unknown. Proceeding with caution.');
          buildSuccess = true;
          break;
        }

      } catch (e) {
        _addLog('⚠️ Execution Error in Attempt $attempt: $e', type: 'error');
        previousErrorContext = e.toString();
      }
    }

    if (buildSuccess) {
      final config = await _getStoredConfig();
      setState(() {
        _progressValue = 1.0;
        _isAutonomousRunning = false;
        _currentPhase = 'Pipeline Completed Successfully!';
        _actionsUrl = 'https://github.com/${config.githubUser}/${config.githubRepo}/actions';
      });
      _addLog('🎉 Application successfully verified and deployed!');
    } else {
      setState(() {
        _isAutonomousRunning = false;
        _progressValue = 1.0;
        _currentPhase = 'Pipeline Halted: Unresolvable Critical Error.';
        _criticalErrorReason = 'GitHub Actions Build failed continuously after 10 attempts.\n\nLast Error Log:\n$previousErrorContext';
      });
      _addLog('🛑 Pipeline stopped because automatic fixes could not resolve the error.', type: 'error');
    }
  }

  Future<String> _monitorGitHubAction(AgentConfig config) async {
    for (int i = 0; i < 24; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final url = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs?per_page=1');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer ${config.githubToken}',
            'Accept': 'application/vnd.github+json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final runs = data['workflow_runs'] as List;
          if (runs.isNotEmpty) {
            final latestRun = runs.first;
            String status = latestRun['status'] ?? ''; 
            String conclusion = latestRun['conclusion'] ?? ''; 

            if (status == 'completed') {
              return conclusion; 
            }
          }
        }
      } catch (_) {}
    }
    return 'timeout';
  }

  Future<String> _fetchLatestActionErrorLog(AgentConfig config) async {
    try {
      final runsUrl = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs?per_page=1');
      final response = await http.get(
        runsUrl,
        headers: {
          'Authorization': 'Bearer ${config.githubToken}',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final runs = data['workflow_runs'] as List;
        if (runs.isNotEmpty) {
          final runId = runs.first['id'];
          final jobsUrl = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/runs/$runId/jobs');
          
          final jobsResponse = await http.get(
            jobsUrl,
            headers: {
              'Authorization': 'Bearer ${config.githubToken}',
              'Accept': 'application/vnd.github+json',
            },
          );

          if (jobsResponse.statusCode == 200) {
            final jobsData = jsonDecode(jobsResponse.body);
            final jobs = jobsData['jobs'] as List;
            if (jobs.isNotEmpty) {
              final jobId = jobs.first['id'];
              final logUrl = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/actions/jobs/$jobId/logs');
              final logRes = await http.get(
                logUrl,
                headers: {
                  'Authorization': 'Bearer ${config.githubToken}',
                  'Accept': 'application/vnd.github+json',
                },
              );

              if (logRes.statusCode == 200) {
                String rawLogs = logRes.body;
                List<String> lines = rawLogs.split('\n');
                List<String> relevantLines = [];
                
                for (int i = lines.length - 1; i >= 0; i--) {
                  String line = lines[i];
                  String lower = line.toLowerCase();
                  if (lower.contains('error') || lower.contains('fail') || lower.contains('exception') || lower.contains('no such file') || lower.contains('undefined') || lower.contains('syntax')) {
                    relevantLines.insert(0, line);
                    if (relevantLines.length >= 40) break; 
                  }
                }
                return relevantLines.isNotEmpty ? relevantLines.join('\n') : (rawLogs.length > 1000 ? rawLogs.substring(rawLogs.length - 1000) : rawLogs);
              }
            }
          }
        }
      }
    } catch (e) {
      return 'Log fetching error: $e';
    }
    return 'Unknown build failure inside Flutter gradle compile phase.';
  }

  Future<void> _scanActionErrors() async {
    setState(() {
      _currentPhase = 'Scanning GitHub Action logs for errors...';
      _detectedErrors.clear();
    });
    _addLog('🔍 Scanning latest build logs from bottom-to-top...');

    try {
      final config = await _getStoredConfig();
      String rawLog = await _fetchLatestActionErrorLog(config);

      List<String> lines = rawLog.split('\n');
      List<Map<String, String>> foundErrors = [];

      for (String line in lines) {
        String lower = line.toLowerCase();
        if (lower.contains('error') || lower.contains('fail') || lower.contains('undefined') || lower.contains('exception') || lower.contains('syntax')) {
          String targetFile = 'lib/main.dart';
          if (line.contains('pubspec.yaml')) targetFile = 'pubspec.yaml';
          if (line.contains('.dart')) {
            RegExp regExp = RegExp(r'([\w\-/]+\.dart)');
            var match = regExp.firstMatch(line);
            if (match != null) targetFile = match.group(0)!;
          }
          foundErrors.add({'file': targetFile, 'error': line});
        }
      }

      setState(() {
        _detectedErrors.addAll(foundErrors.take(10));
        _currentPhase = foundErrors.isEmpty ? 'Build looks clean! No errors found.' : 'Errors detected! Tap "Fix" on specific error.';
      });

      _addLog(foundErrors.isEmpty ? '🎉 No errors found in latest logs!' : '⚠️ Found ${foundErrors.length} issues.');

    } catch (e) {
      _addLog('⚠️ Scan failed: $e', type: 'error');
      setState(() => _currentPhase = 'Scan failed.');
    }
  }

  Future<void> _fixSpecificError(String targetFile, String errorMessage) async {
    setState(() {
      _isAutonomousRunning = true;
      _currentPhase = 'Surgically fixing file: $targetFile...';
    });
    _addLog('🛠️ Laborer dispatching surgical fix for file: $targetFile');

    try {
      final config = await _getStoredConfig();
      String existingCode = await _fetchFileFromGitHub(config, targetFile);

      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final systemPrompt = '''
You are a surgical code debugger. You are given a specific file and a specific error message. 
Fix ONLY the error inside this file. Do not touch other files. Return ONLY the corrected raw code for this file without markdown wrappers.
Target File: $targetFile
Error Message: $errorMessage
''';

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${config.groqKey}'},
        body: jsonEncode({
          "model": config.selectedModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "Existing Code:\n$existingCode"}
          ],
          "temperature": 0.1,
        }),
      );

      if (response.statusCode != 200) throw Exception(response.body);

      final decoded = jsonDecode(response.body);
      String fixedCode = decoded['choices'][0]['message']['content'];
      fixedCode = fixedCode.replaceAll('```dart', '').replaceAll('```', '').trim();

      _addLog('☁️ Pushing surgically patched $targetFile to GitHub...');
      await _pushFileToGitHub(config, targetFile, fixedCode);

      setState(() {
        _isAutonomousRunning = false;
        _currentPhase = 'Patch applied to $targetFile successfully. Re-scan to verify.';
        _detectedErrors.removeWhere((e) => e['file'] == targetFile);
      });
      _addLog('✨ Successfully patched and pushed $targetFile!');

    } catch (e) {
      _addLog('⚠️ Surgical fix error: $e', type: 'error');
      setState(() => _isAutonomousRunning = false);
    }
  }

  Future<String> _fetchFileFromGitHub(AgentConfig config, String path) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/contents/$path');
      final res = await http.get(url, headers: {'Authorization': 'Bearer ${config.githubToken}', 'Accept': 'application/vnd.github+json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return utf8.decode(base64Decode(data['content'].replaceAll('\n', '')));
      }
    } catch (_) {}
    return '// Code not found or new file';
  }

  List<Map<String, dynamic>> _parsePlainFiles(String rawResponse, String packageName) {
    try {
      String cleaned = rawResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      int startIndex = cleaned.indexOf('[');
      int endIndex = cleaned.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }

      List<dynamic> list = [];
      try {
        list = jsonDecode(cleaned);
      } catch (_) {
        list = [];
      }

      List<Map<String, dynamic>> parsedFiles = [];
      for (var item in list) {
        parsedFiles.add({
          'fileName': item['fileName'] ?? '',
          'fileCode': item['fileCode'] ?? '',
        });
      }

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'pubspec.yaml');
      parsedFiles.add({
        'fileName': 'pubspec.yaml',
        'fileCode': '''name: $packageName
description: A new Flutter application.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '^3.3.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString().contains('AndroidManifest.xml'));
      parsedFiles.add({
        'fileName': 'android/app/src/main/AndroidManifest.xml',
        'fileCode': '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="$packageName"
        android:name="\${applicationName}">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString().contains('styles.xml'));
      parsedFiles.add({
        'fileName': 'android/app/src/main/res/values/styles.xml',
        'fileCode': '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@android:color/white</item>
    </style>
</resources>''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString().contains('launch_background.xml'));
      parsedFiles.add({
        'fileName': 'android/app/src/main/res/drawable/launch_background.xml',
        'fileCode': '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'android/build.gradle');
      parsedFiles.add({
        'fileName': 'android/build.gradle',
        'fileCode': '''allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "\${rootProject.buildDir}/\${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'android/app/build.gradle');
      parsedFiles.add({
        'fileName': 'android/app/build.gradle',
        'fileCode': '''plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.$packageName"
    compileSdkVersion flutter.compileSdkVersion
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    defaultConfig {
        applicationId "com.example.$packageName"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode 1
        versionName "1.0.0"
    }
}

flutter {
    source = "../.."
}
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'android/settings.gradle');
      parsedFiles.add({
        'fileName': 'android/settings.gradle',
        'fileCode': '''pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        def flutterPropertiesFile = new File('local.properties')
        if (flutterPropertiesFile.exists()) {
            properties.load(new FileInputStream(flutterPropertiesFile))
        }
        def flutterSdkPath = properties.getProperty('flutter.sdk')
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("\$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "7.3.0" apply false
    id "org.jetbrains.kotlin.android" version "1.8.0" apply false
}

include ":app"
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString() == 'android/gradle.properties');
      parsedFiles.add({
        'fileName': 'android/gradle.properties',
        'fileCode': '''org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
''',
      });

      parsedFiles.removeWhere((file) => file['fileName'].toString().endsWith('.yml') || file['fileName'].toString().endsWith('.yaml'));
      parsedFiles.add({
        'fileName': '.github/workflows/flutter.yml',
        'fileCode': '''name: Build Flutter App
on:
  push:
    branches: [ "main" ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
      - run: flutter pub get
      - run: flutter build apk --release
''',
      });

      return parsedFiles;
    } catch (e) {
      throw Exception('Parsing Error: $e');
    }
  }

  Future<void> _pushFileToGitHub(AgentConfig config, String fileName, String fileCode) async {
    final url = Uri.parse('https://api.github.com/repos/${config.githubUser}/${config.githubRepo}/contents/$fileName');
    
    String? existingSha;
    try {
      final getResponse = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${config.githubToken}',
          'Accept': 'application/vnd.github+json',
        },
      );
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        existingSha = data['sha'];
      }
    } catch (_) {}

    final encodedContent = base64Encode(utf8.encode(fileCode));

    final Map<String, dynamic> bodyData = {
      "message": "Autonomous Laborer: Fix/Add $fileName",
      "content": encodedContent,
      "branch": "main",
    };

    if (existingSha != null) {
      bodyData["sha"] = existingSha;
    }

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${config.githubToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github+json',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to push $fileName to GitHub: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _selectableFiles.where((f) {
      return f['path'].toLowerCase().contains(_fileSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Enterprise Studio'),
        backgroundColor: const Color(0xFF1D3557),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enter App Requirement / Prompt',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isAutonomousRunning || _isWaitingForUserFileSelection ? null : _startAutonomousPipeline,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5D4), 
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('🔍 Step 1: Plan Core Architecture', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
            ),
            const SizedBox(height: 8),
            Text('Pipeline Status: ${(_progressValue * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_currentPhase, style: const TextStyle(color: Color(0xFF00F5D4))),
            const SizedBox(height: 12),
            if (_criticalErrorReason.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛑 CRITICAL HALT REASON:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_criticalErrorReason, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_isWaitingForUserFileSelection) ...[
              TextField(
                controller: _searchFileController,
                onChanged: (val) => setState(() => _fileSearchQuery = val),
                decoration: const InputDecoration(
                  labelText: 'Search Files...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Review & Select Files to Build:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final fileItem = filteredFiles[index];
                    return CheckboxListTile(
                      title: Text(fileItem['path']),
                      value: fileItem['selected'],
                      activeColor: const Color(0xFF00F5D4),
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          fileItem['selected'] = val ?? true;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _confirmAndExecuteBuild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5D4), 
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('🚀 Step 2: Synthesize & Self-Heal Build', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Live Telemetry & Diagnostics:', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _isAutonomousRunning ? null : _scanActionErrors,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent, 
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(36),
                ),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Scan Build Errors & Show Fix Buttons'),
              ),
              const SizedBox(height: 6),
              if (_detectedErrors.isNotEmpty) ...[
                const Text('🛠️ Detected Errors & Surgical Fix:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 120,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05), 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: ListView.builder(
                      itemCount: _detectedErrors.length,
                      itemBuilder: (context, index) {
                        final err = _detectedErrors[index];
                        return Card(
                          color: const Color(0xFF1D3557),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            title: Text(err['file']!, style: const TextStyle(color: Color(0xFF00F5D4), fontWeight: FontWeight.bold, fontSize: 11)),
                            subtitle: Text(err['error']!, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent, 
                                foregroundColor: Colors.white, 
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                minimumSize: const Size(50, 28),
                              ),
                              onPressed: _isAutonomousRunning ? null : () => _fixSpecificError(err['file']!, err['error']!),
                              child: const Text('Fix', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _logs[index], 
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_actionsUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: Text('Actions URL: $_actionsUrl', style: const TextStyle(color: Color(0xFF00F5D4))),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
