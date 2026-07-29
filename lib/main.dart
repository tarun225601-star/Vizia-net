import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ViziaNetApp());
}

class ViziaNetApp extends StatelessWidget {
  const ViziaNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia Global Studio',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
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
  final List<String> logs = [];
  bool isRunning = false;
  String buildStatus = 'तैयार है';
  bool isSuccess = true;

  void _addLog(String message) {
    setState(() {
      logs.add(message);
    });
  }

  // Groq Cloud API से ऐप कोड जनरेटर (ऑटो-फिक्स v2 एम्बेडिंग के साथ)
  Future<String> _generateCodeWithGroq(String prompt) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer gsk_your_groq_api_key_here', // यहाँ अपनी Groq API Key डाल लेना
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are an expert Flutter developer and autonomous app architect. You have access to all 7 core project files: 1. pubspec.yaml, 2. lib/main.dart, 3. android/app/src/main/AndroidManifest.xml, 4. android/app/build.gradle, 5. android/build.gradle, 6. android/settings.gradle, 7. android/gradle.properties. Analyze the user prompt to dynamically select ONLY the required files for the requested app. CRITICAL RULE: Every AndroidManifest.xml MUST include <meta-data android:name=\"flutterEmbedding\" android:value=\"2\" /> inside the application tag. Write 100% complete, fully functional code without placeholders or truncation."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.3
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];

        // ऑटो-फिक्स: अगर मैनिफेस्ट फाइल है और v2 एम्बेडिंग नहीं है, तो ऐप खुद जोड़ देगा
        if (aiResponse.contains('AndroidManifest.xml') && !aiResponse.contains('flutterEmbedding')) {
          aiResponse = aiResponse.replaceAll(
            '<application',
            '<application\n        <meta-data android:name="flutterEmbedding" android:value="2" />'
          );
        }

        return aiResponse;
      } else {
        _addLog('⚠️ Groq API Error: ${response.body}');
        return '';
      }
    } catch (e) {
      _addLog('⚠️ Groq Exception: $e');
      return '';
    }
  }

  Future<void> _startFullyAutomatedSystem() async {
    if (_promptController.text.trim().isEmpty) {
      _addLog('⚠️ कृपया पहले प्रॉम्प्ट लिखें!');
      return;
    }

    setState(() {
      isRunning = true;
      buildStatus = 'प्रोसेस जारी है...';
      isSuccess = true;
      logs.clear();
    });

    _addLog('🚀 ऑटो-सिस्टम शुरू हो गया है...');
    String prompt = _promptController.text;
    
    _addLog('🤖 Groq AI से कोड जनरेट हो रहा है...');
    String generatedCode = await _generateCodeWithGroq(prompt);

    if (generatedCode.isNotEmpty) {
      _addLog('✅ कोड सफलतापूर्वक जनरेट हो गया!');
    } else {
      _addLog('❌ कोड जनरेशन विफल रहा।');
      setState(() {
        isSuccess = false;
        buildStatus = 'विफल रहा';
      });
    }

    setState(() {
      isRunning = false;
      buildStatus = isSuccess ? 'सफल रहा' : 'विफल रहा';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Global Studio - AI Builder'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'अपना ऐप आइडिया यहाँ लिखें...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isRunning ? null : _startFullyAutomatedSystem,
              icon: isRunning
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Icon(Icons.rocket_launch),
              label: Text(isRunning ? 'ऑटो-बिल्ड प्रोसेस जारी है...' : '🚀 ऑटो-एजेंट चलाकर ऐप बनाएँ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'बिल्ड स्टेटस: $buildStatus',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.info,
                  color: isSuccess ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? 'सिस्टम नॉर्मल है' : 'चेतावनी / एरर'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'लाइव लॉग्स:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        logs[index],
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
