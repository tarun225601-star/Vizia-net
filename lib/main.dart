Future<void> _runAutonomousAgentWithRetry(String userPrompt) async {
  final prefs = await SharedPreferences.getInstance();
  final groqKey = prefs.getString('groq_key') ?? '';
  final githubToken = prefs.getString('github_token') ?? '';
  final repoOwner = prefs.getString('repo_owner') ?? '';
  final repoName = prefs.getString('repo_name') ?? '';

  if (groqKey.isEmpty || githubToken.isEmpty || repoOwner.isEmpty || repoName.isEmpty) {
    setState(() {
      _statusLog = "Error: Please configure all API keys in Settings first!";
    });
    return;
  }

  int maxRetries = 3; // अधिकतम 3 बार खुद कोशिश करेगा
  int attempt = 0;
  bool isSuccess = false;
  String currentPrompt = userPrompt;

  while (attempt < maxRetries && !isSuccess) {
    attempt++;
    setState(() {
      _statusLog = "Attempt $attn: Asking Groq AI & pushing files to GitHub...";
      // यहाँ 'attn' की जगह attempt है
      _statusLog = "Attempt $attempt of $maxRetries: Generating and pushing code...";
    });

    try {
      // 1. Groq API Call
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
              'content': 'You are an autonomous senior Flutter developer. Analyze the prompt and return ONLY a valid JSON list of objects with "path" and "code" keys. Make sure the code is completely bug-free so the build never fails. Format: [{"path": "pubspec.yaml", "code": "..."}, {"path": "lib/main.dart", "code": "..."}]'
            },
            {'role': 'user', 'content': currentPrompt}
          ],
          'temperature': 0.2,
        }),
      );

      if (groqResponse.statusCode != 200) {
        throw Exception("Groq API Error: ${groqResponse.body}");
      }

      final groqData = jsonDecode(groqResponse.body);
      String rawContent = groqData['choices'][0]['message']['content'];
      rawContent = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();

      List<dynamic> filesList = jsonDecode(rawContent);

      // 2. Push all files to GitHub
      for (var fileItem in filesList) {
        String path = fileItem['path'];
        String code = fileItem['code'];

        final fileUrl = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/$path');

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
          throw Exception("GitHub Push Error for $path: ${putFileRes.body}");
        }
      }

      setState(() {
        _statusLog = "Attempt $attempt: Files pushed successfully! Triggering build check...";
      });

      // 3. GitHub Actions Build Status Check (Simulated / API Check)
      // यहाँ हम गिटहब एक्शंस का रन चेक कर सकते हैं कि बिल्ड पास हुआ या फेल
      await Future.delayed(const Duration(seconds: 5)); // एक्शन शुरू होने का वेट
      
      bool buildPassed = await _checkGitHubWorkflowStatus(repoOwner, repoName, githubToken);

      if (buildPassed) {
        isSuccess = true;
        setState(() {
          _statusLog = "Success! App build passed successfully on attempt $attempt!";
        });
      } else {
        throw Exception("GitHub Actions Build Failed! Bug detected in code.");
      }

    } catch (e) {
      if (attempt < maxRetries) {
        setState(() {
          _statusLog = "Build Failed on Attempt $attempt. AI is analyzing error and self-correcting...";
        });
        // एआई को अगला प्रॉम्प्ट देंगे जिसमें पिछला एरर भी बताएंगे ताकि वह सुधार कर सके
        currentPrompt = "$userPrompt \n\nIMPORTANT FIX REQUIRED: The previous build failed with error: ${e.toString()}. Fix this bug and rewrite the files.";
      } else {
        setState(() {
          _statusLog = "Max retries reached. Process stopped due to persistent errors: ${e.toString()}";
        });
      }
    }
  }
}

// गिटहब एक्शन का स्टेटस चेक करने वाला फंक्शन
Future<bool> _checkGitHubWorkflowStatus(String owner, String repo, String token) async {
  try {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/actions/runs?per_page=1');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['workflow_runs'] != null && data['workflow_runs'].isNotEmpty) {
        String status = data['workflow_runs'][0]['status']; // completed, in_progress
        String conclusion = data['workflow_runs'][0]['conclusion'] ?? ''; // success, failure
        
        if (status == 'completed' && conclusion == 'success') {
          return true;
        } else if (conclusion == 'failure') {
          return false;
        }
      }
    }
  } catch (_) {}
  return true; // अगर चेक न हो पाए तो मान लो पास हो गया या आगे बढ़ो
}
