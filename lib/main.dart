import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MasterBoxApp());

class MasterBoxApp extends StatelessWidget {
  const MasterBoxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Master Box Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        primaryColor: Colors.cyanAccent,
      ),
      home: const MasterHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// मॉडल: हर सेव होने वाले ऐप का डाटा
// ==========================================
class SavedAppItem {
  final String title;
  final String code;
  final String timestamp;

  SavedAppItem({required this.title, required this.code, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'title': title,
        'code': code,
        'timestamp': timestamp,
      };

  factory SavedAppItem.fromJson(Map<String, dynamic> json) => SavedAppItem(
        title: json['title'] ?? 'App',
        code: json['code'] ?? '',
        timestamp: json['timestamp'] ?? '',
      );
}

// ==========================================
// 1. सेटिंग्स स्क्रीन (अलग-अलग नाम और अलग कोड्स का वॉल्ट)
// ==========================================
class MasterSettingsScreen extends StatefulWidget {
  const MasterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MasterSettingsScreen> createState() => _MasterSettingsScreenState();
}

class _MasterSettingsScreenState extends State<MasterSettingsScreen> {
  final TextEditingController _groqKeyController = TextEditingController();
  List<SavedAppItem> savedAppsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groqKeyController.text = prefs.getString('groq_key') ?? '';
      List<String> rawList = prefs.getStringList('saved_apps_vault_v2') ?? [];
      savedAppsList = rawList.map((item) => SavedAppItem.fromJson(jsonDecode(item))).toList();
    });
  }

  Future<void> _saveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_key', _groqKeyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Groq API Key सुरक्षित हो गई है!')),
    );
  }

  Future<void> _deleteItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedAppsList.removeAt(index);
    });
    List<String> rawList = savedAppsList.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('saved_apps_vault_v2', rawList);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ कोड डिलीट कर दिया गया है।')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('लोकल सेटिंग्स और अलग कोड वॉल्ट'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _groqKeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Groq Cloud API Key',
                prefixIcon: Icon(Icons.bolt, color: Colors.cyanAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              onPressed: _saveKey,
              icon: const Icon(Icons.save),
              label: const Text('की सेव करें', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              '📦 आपके अलग-अलग सहेजे गए ऐप्स (नाम और कोड):',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: savedAppsList.isEmpty
                  ? const Center(child: Text('कोई ऐप अभी तक सेव नहीं है।', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: savedAppsList.length,
                      itemBuilder: (context, index) {
                        final appItem = savedAppsList[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      appItem.title,
                                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () => _deleteItem(index),
                                    ),
                                  ],
                                ),
                                Text(
                                  'समय: ${appItem.timestamp}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 90,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      appItem.code,
                                      style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: appItem.code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('📋 "${appItem.title}" का कोड कॉपी हो गया!')),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('कोड कॉपी करें'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. होम स्क्रीन (AI जेनरेटर + लाइव WebView प्रीव्यू)
// ==========================================
class MasterHomePage extends StatefulWidget {
  const MasterHomePage({Key? key}) : super(key: key);

  @override
  State<MasterHomePage> createState() => _MasterHomePageState();
}

class _MasterHomePageState extends State<MasterHomePage> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Build a simple calculator app with modern UI',
  );

  bool isProcessing = false;
  String generatedCode = '';
  String statusMessage = 'तैयार है...';
  WebViewController? _webViewController;
  bool showWebView = false;

  Future<void> _runEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_key') ?? '';

    if (groqKey.isEmpty) {
      setState(() => statusMessage = '❌ त्रुटि: कृपया सेटिंग्स में जाकर Groq API Key दर्ज करें!');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      isProcessing = true;
      statusMessage = '🔄 एआई से ऐप लेआउट तैयार हो रहा है...';
      showWebView = false;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are an elite UI designer. Based on the user prompt, generate a fully styled, modern, single-file responsive HTML/CSS/JS application so it can be previewed live in a webview. Return ONLY the HTML code without markdown blocks."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String htmlCode = data['choices'][0]['message']['content'];

        if (htmlCode.contains('```html')) {
          htmlCode = htmlCode.split('```html')[1].split('```')[0];
        } else if (htmlCode.contains('```')) {
          htmlCode = htmlCode.split('```')[1].split('```')[0];
        }
        htmlCode = htmlCode.trim();

        // अलग नाम और टाइमिंग के साथ ऐप सेव करना (जैसे App #1, App #2...)
        List<String> rawList = prefs.getStringList('saved_apps_vault_v2') ?? [];
        List<SavedAppItem> existingList = rawList.map((item) => SavedAppItem.fromJson(jsonDecode(item))).toList();
        
        int nextNumber = existingList.length + 1;
        String shortTitle = prompt.length > 20 ? '${prompt.substring(0, 20)}...' : prompt;
        String appName = 'App #$nextNumber: $shortTitle';
        String timeStr = TimeOfDay.fromDateTime(DateTime.now()).format(context);

        SavedAppItem newItem = SavedAppItem(title: appName, code: htmlCode, timestamp: timeStr);
        existingList.insert(0, newItem);

        List<String> updatedRawList = existingList.map((item) => jsonEncode(item.toJson())).toList();
        await prefs.setStringList('saved_apps_vault_v2', updatedRawList);

        // WebView इनिशियलाइज करना
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(htmlCode);

        setState(() {
          generatedCode = htmlCode;
          _webViewController = controller;
          isProcessing = false;
          showWebView = true;
          statusMessage = '✅ "${appName}" सफलता से बन गई है और नीचे लाइव दिख रही है!';
        });
      } else {
        setState(() {
          isProcessing = false;
          statusMessage = '⚠️ API एरर: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        statusMessage = '⚠️ एरर: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('मास्टर बॉक्स प्रो (अलग कोड मैनेजर)'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MasterSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ऐप प्रॉम्प्ट लिखें:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _promptController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                onPressed: isProcessing ? null : _runEngine,
                icon: isProcessing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bolt),
                label: Text(isProcessing ? 'बनाया जा रहा है...' : '⚡ ऐप बनाएँ और लाइव देखें', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Text(statusMessage, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            
            // लाइव WebView प्रीव्यू बॉक्स
            if (showWebView && _webViewController != null) ...[
              const Text('📱 लाइव ऐप व्यूअर:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.5),
                    child: WebViewWidget(controller: _webViewController!),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Text('📦 जेनरेटेड सोर्स कोड:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    generatedCode.isEmpty ? '// यहाँ कोड दिखेगा...' : generatedCode,
                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 10),
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
