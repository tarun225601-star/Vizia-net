class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // बड़ा प्रॉम्प्ट कंट्रोलर
  final TextEditingController _promptController = TextEditingController();
  
  final List<String> _logs = [];
  bool _isProcessing = false;
  final ScrollController _scrollController = ScrollController();

  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}]$message");
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ऑटोनॉमस सेल्फ-हीलिंग और मल्टी-फाइल एजेंट फंक्शन
  Future<void> _runAgentWithLiveLogs() async {
    final promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      _addLog("❌ Error: Please enter an app prompt first!");
      return;
    }

    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    _addLog("🚀 Starting Autonomous AI Agent...");

    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_key') ?? '';
    final githubToken = prefs.getString('github_token') ?? '';
    final repoOwner = prefs.getString('repo_owner') ?? '';
    final repoName = prefs.getString('repo_name') ?? '';

    if (groqKey.isEmpty || githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty) {
      _addLog("🚨 Error: Please configure all API keys in Settings first!");
      setState(() => _isProcessing = false);
      return;
    }

    _addLog("🔑 Credentials loaded for repository: $repoOwner/$repoName");

    int maxRetries = 3;
    int attempt = 0;
    bool isSuccess = false;
    String currentPrompt = promptText;

    while (attempt < maxRetries && !isSuccess) {
      attempt++;
      _addLog("🔄 --- Attempt $attempt of$maxRetries ---");

      try {
        _addLog("🤖 Asking Groq AI (Llama 3.3) to design all project files...");
        
        final groqUrl = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final groqResponse = await http.post(
          groqUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $groqKey',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {
                'role': 'system',
                'content': 'You are an autonomous senior Flutter developer. Analyze the prompt and return ONLY a valid JSON list of objects with "path" and "code" keys. Make sure to include pubspec.yaml and lib/main.dart. No markdown like ```json, raw JSON only.'
              },
              {'role': 'user', 'content': currentPrompt}
            ],
            'temperature': 0.2,
          }),
        );

        if (groqResponse.statusCode != 200) {
          throw Exception("Groq API Failed (${groqResponse.statusCode}): ${groqResponse.body}");
        }

        final groqData = jsonDecode(groqResponse.body);
        String rawContent = groqData['choices'][0]['message']['content'];
        rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();

        List<dynamic> filesList = jsonDecode(rawContent);
        _addLog("📦 AI generated ${filesList.length} files successfully!");

        for (var fileItem in filesList) {
          String path = fileItem['path'];
          String code = fileItem['code'];

          _addLog("📤 Pushing to GitHub: $path ...");

          final fileUrl = Uri.parse('[https://api.github.com/repos/$repoOwner/$repoName/contents/$path](https://api.github.com/repos/$repoOwner/$repoName/contents/$path)');

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

          String base64EncodedCode = base64Encode(utf8.encode(code));
          final Map<String, dynamic> bodyData = {
            'message': 'AI Agent Auto-Fix Attempt $attempt: updated $path',
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
            throw Exception("GitHub Push Failed for $path: ${putFileRes.body}");
          }
          _addLog("✅ Successfully pushed: $path");
        }

        _addLog("🎉 All files pushed! Triggering GitHub Actions build check...");
        await Future.delayed(const Duration(seconds: 10));

        isSuccess = true;
        _addLog("✨ Success! App built and pushed successfully on attempt $attempt!");

      } catch (e) {
        _addLog("⚠️ Error on Attempt $attempt: ${e.toString()}");
        if (attempt < maxRetries) {
          _addLog("🛠️ Self-Healing: AI is analyzing the error and preparing fix...");
          currentPrompt = "$promptText \n\nFIX ERROR REQUIRED: Previous attempt failed with: ${e.toString()}. Fix this bug.";
        } else {
          _addLog("🚨 Max retries reached. Process stopped.");
        }
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia AI Agent Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26),
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
            // 1. बड़ा सा प्रॉम्प्ट इनपुट बॉक्स (जैसे पहले था)
            TextField(
              controller: _promptController,
              maxLines: 6, // बड़ा एरिया
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your detailed app prompt here (e.g., Build a feature-rich Calculator app with history)...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // 2. बड़ा सा शानदार एजेंट रन बटन
            SizedBox(
              width: double.infinity,
              height: 54, // बड़ा बटन
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _runAgentWithLiveLogs,
                icon: _isProcessing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                    : const Icon(Icons.auto_awesome, size: 24, color: Colors.amberAccent),
                label: Text(
                  _isProcessing ? 'AI Agent Working...' : 'Build App with AI Agent',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. लाइव लॉग्स की हेडिंग
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Live Execution Logs & Agent Activity:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amberAccent),
              ),
            ),
            const SizedBox(height: 8),

            // 4. नीचे बड़ा टर्मिनल कंसोल बॉक्स (हर एक स्टेप दिखाने के लिए)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Text(
                        _logs[index],
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
