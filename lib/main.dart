import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MultiAgentBuilderApp());
}

class MultiAgentBuilderApp extends StatelessWidget {
  const MultiAgentBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Multi-Agent 6-File Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurple,
      ),
      home: const BuilderHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// सेटिंग्स स्क्रीन (Groq API और GitHub क्रेडेंशियल्स)
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _repoOwnerController = TextEditingController();
  final TextEditingController _repoNameController = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _githubTokenController.text = prefs.getString('github_token') ?? '';
      _repoOwnerController.text = prefs.getString('repo_owner') ?? '';
      _repoNameController.text = prefs.getString('repo_name') ?? '';
      _groqKeyController.text = prefs.getString('groq_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_token', _githubTokenController.text.trim());
    await prefs.setString('repo_owner', _repoOwnerController.text.trim());
    await prefs.setString('repo_name', _repoNameController.text.trim());
    await prefs.setString('groq_key', _groqKeyController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('सेटिंग्स सफलतापूर्वक सेव हो गई हैं!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('एपीआई और गिटहब सेटिंग्स')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(labelText: 'GitHub Personal Access Token'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoOwnerController,
              decoration: const InputDecoration(labelText: 'GitHub Username / Owner'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoNameController,
              decoration: const InputDecoration(labelText: 'GitHub Repository Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groqKeyController,
              decoration: const InputDecoration(labelText: 'Groq Cloud API Key'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('सभी सेटिंग्स सेव करें'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// होम स्क्रीन (Auto-Clean & Full 6-File Agent Builder)
// ==========================================
class BuilderHomePage extends StatefulWidget {
  const BuilderHomePage({super.key});

  @override
  State<BuilderHomePage> createState() => _BuilderHomePageState();
}

class _BuilderHomePageState extends State<BuilderHomePage> {
  final TextEditingController _promptController = TextEditingController(
    text: 'make a professional weather app',
  );

  List<String> logs = [];
  bool isRunning = false;
  String buildStatus = 'प्रतीक्षा में (Idle)';
  bool isSuccess = false;

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      final timeOfDay = TimeOfDay.fromDateTime(DateTime.now()).format(context);
      logs.insert(0, '[$timeOfDay] $message');
    });
  }

  // गिटहब से पुरानी फाइल डिलीट करने का फंक्शन
  Future<void> _deleteFileFromGitHub(String token, String owner, String repo, String path) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
      final getRes = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (getRes.statusCode == 200) {
        final sha = jsonDecode(getRes.body)['sha'];
        await http.delete(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github+json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': 'Agent: clean old $path',
            'sha': sha,
          }),
        );
      }
    } catch (_) {}
  }

  // गिटहब पर फाइल पुश करने का सुरक्षित फंक्शन
  Future<bool> _pushFileToGitHub(String token, String owner, String repo, String path, String content, String commitMessage) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
      String? sha;
      
      final getRes = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      );

      if (getRes.statusCode == 200) {
        sha = jsonDecode(getRes.body)['sha'];
      }

      final body = {
        'message': commitMessage,
        'content': base64Encode(utf8.encode(content)),
        if (sha != null) 'sha': sha,
      };

      final putRes = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return putRes.statusCode == 200 || putRes.statusCode == 201;
    } catch (e) {
      _addLog('❌ GitHub Push Error ($path): $e');
      return false;
    }
  }

  // --- Groq Cloud API से केवल lib/main.dart का कोड जनरेटर ---
  Future<String> _generateCodeWithGroq(String grokApiKey, String userPrompt) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $grokApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are an expert Flutter developer. Write a complete, fully working, single-file Flutter app based on the user request. EVERYTHING must be inside a single file containing main(). Do NOT use external custom packages (only standard material and http if needed). Return ONLY pure Dart code inside ```dart markdown. Do not include any extra conversation."
            },
            {
              "role": "user",
              "content": userPrompt
            }
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['choices'][0]['message']['content'];

        if (text.contains('```dart')) {
          text = text.split('```dart')[1].split('```')[0];
        } else if (text.contains('```')) {
          text = text.split('```')[1];
        }
        return text.trim();
      } else {
        _addLog('❌ Groq API Error: ${response.body}');
        return '';
      }
    } catch (e) {
      _addLog('❌ Groq Exception: $e');
      return '';
    }
  }

  // 6-File Multi-Agent System (Auto-Clean & Fresh Deploy)
  Future<void> _startMultiAgentsSystem() async {
    final prefs = await SharedPreferences.getInstance();
    String githubToken = prefs.getString('github_token') ?? '';
    String repoOwner = prefs.getString('repo_owner') ?? '';
    String repoName = prefs.getString('repo_name') ?? '';
    String grokApiKey = prefs.getString('groq_key') ?? '';

    if (githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty || grokApiKey.isEmpty) {
      _addLog('❌ सेटिंग्स अधूरी हैं! कृपया ऊपर सेटिंग आइकॉन पर क्लिक करके सभी API Keys और GitHub डिटेल्स भरें।');
      return;
    }

    setState(() {
      isRunning = true;
      logs.clear();
      buildStatus = 'पुराना डेटा साफ करके 6 फाइलें तैयार हो रही हैं...';
      isSuccess = false;
    });

    _addLog('🧹 एजेंट 0: पुरानी सभी 6 संभावित फाइलें डिलीट कर रहा है...');
    
    List<String> filesToClean = [
      'lib/main.dart',
      'pubspec.yaml',
      'android/app/src/main/AndroidManifest.xml',
      'android/app/build.gradle',
      'android/build.gradle',
      '.github/workflows/build.yml'
    ];

    for (var filePath in filesToClean) {
      await _deleteFileFromGitHub(githubToken, repoOwner, repoName, filePath);
    }
    _addLog('✨ पुराना कबाड़ पूरी तरह साफ हो गया है!');

    _addLog('🚀 6-File एजेंट सिस्टम शुरू हो गया है!');
    
    // --- 1. फाइल: lib/main.dart ---
    _addLog('🤖 एजेंट 1: Groq 70B से नया lib/main.dart कोड लिखवा रहा है...');
    String generatedCode = await _generateCodeWithGroq(grokApiKey, _promptController.text.trim());

    if (generatedCode.isEmpty) {
      _addLog('❌ कोड जनरेशन असफल रहा।');
      setState(() => isRunning = false);
      return;
    }
    _addLog('✔️ फाइल 1/6: नया lib/main.dart तैयार!');

    // --- 2. फाइल: pubspec.yaml ---
    String pubspecYaml = '''
name: ai_generated_app
description: A new Flutter project generated by AI Multi-Agent Builder.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';
    _addLog('✔️ फाइल 2/6: pubspec.yaml तैयार!');

    // --- 3. फाइल: android/app/src/main/AndroidManifest.xml ---
    String androidManifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.ai_generated_app">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="AI App"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
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
</manifest>
''';
    _addLog('✔️ फाइल 3/6: AndroidManifest.xml तैयार!');

    // --- 4. फाइल: android/app/build.gradle ---
    String appBuildGradle = '''
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.ai_generated_app"
    compileSdkVersion flutter.compileSdkVersion
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    defaultConfig {
        applicationId "com.example.ai_generated_app"
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}
''';
    _addLog('✔️ फाइल 4/6: app/build.gradle तैयार!');

    // --- 5. फाइल: android/build.gradle ---
    String projectBuildGradle = '''
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = '\${rootProject.buildDir}/\${project.name}'
}
subprojects {
    project.evaluationDependsOn(':app')
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
''';
    _addLog('✔️ फाइल 5/6: android/build.gradle तैयार!');

    // --- 6. फाइल: .github/workflows/build.yml ---
    String workflowYml = '''
name: Flutter Build

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "20.x"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.9'

      - name: Install Dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release
''';
    _addLog('✔️ फाइल 6/6: workflow build.yml तैयार!');

    // --- गिटहब पर सभी 6 फाइलें फ्रेश अपलोड करना ---
    _addLog('🔍 एजेंट 2: गिटहब पर सभी 6 नई फाइलें फ्रेश अपलोड कर रहा है...');

    bool f1 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'lib/main.dart', generatedCode, 'Agent: fresh update main.dart');
    bool f2 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'pubspec.yaml', pubspecYaml, 'Agent: fresh add pubspec.yaml');
    bool f3 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'android/app/src/main/AndroidManifest.xml', androidManifest, 'Agent: fresh add AndroidManifest.xml');
    bool f4 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'android/app/build.gradle', appBuildGradle, 'Agent: fresh add app build.gradle');
    bool f5 = await _pushFileToGitHub(githubToken, repoOwner, repoName, 'android/build.gradle', projectBuildGradle, 'Agent: fresh add project build.gradle');
    bool f6 = await _pushFileToGitHub(githubToken, repoOwner, repoName, '.github/workflows/build.yml', workflowYml, 'Agent: fresh add workflow yml');

    if (f1 && f2 && f3 && f4 && f5 && f6) {
      _addLog('🎉 शानदार! पुराना सब साफ करके कुल 6 नई फाइलें गिटहब पर डिप्लॉय हो गई हैं।');
      setState(() {
        isRunning = false;
        buildStatus = 'बिल्ड ट्रिगर हो गई (Actions चेक करें)';
        isSuccess = true;
      });
    } else {
      _addLog('⚠️ कुछ फाइलें अपलोड होने में दिक्कत आई।');
      setState(() {
        isRunning = false;
        buildStatus = 'बिल्ड फेल / इनकंप्लीट';
        isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 6-File Agent Builder'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('कोई भी नया ऐप आइडिया यहाँ लिखें:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: isRunning ? null : _startMultiAgentsSystem,
                icon: isRunning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.flash_on),
                label: Text(
                  isRunning ? '6 फाइलें तैयार हो रही हैं...' : '✨ पुराना साफ कर 6 नई फाइलें बनाएँ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('लाइव प्रोसेस और लॉग्स:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        logs[index],
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('बिल्ड स्टेटस: $buildStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(isSuccess ? Icons.check_circle : Icons.info, color: isSuccess ? Colors.green : Colors.orange),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
