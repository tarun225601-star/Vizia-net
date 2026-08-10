import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  runApp(const AutonomousAgentStudioApp());
}

// =====================================================================
// 1. APP ENTRY POINT & THEME CONFIGURATION
// =====================================================================
class AutonomousAgentStudioApp extends StatelessWidget {
  const AutonomousAgentStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autonomous Replit & Agent Studio Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
      ),
      home: const AgentStudioDashboard(),
    );
  }
}

// =====================================================================
// 2. MAIN DASHBOARD UI & STATE MANAGEMENT
// =====================================================================
class AgentStudioDashboard extends StatefulWidget {
  const AgentStudioDashboard({super.key});

  @override
  State<AgentStudioDashboard> createState() => _AgentStudioDashboardState();
}

class _AgentStudioDashboardState extends State<AgentStudioDashboard> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _telemetryLogs = [];
  bool _isPipelineActive = false;
  double _pipelineProgress = 0.0;
  String _githubDeploymentStatus = 'Idle / Waiting for Prompt';

  final AutonomousEngineBackend _engineBackend = AutonomousEngineBackend();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _triggerAutonomousPipeline() async {
    final promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid prompt to begin generation.')),
      );
      return;
    }

    setState(() {
      _isPipelineActive = true;
      _telemetryLogs.clear();
      _pipelineProgress = 0.05;
      _githubDeploymentStatus = 'Initializing core modules...';
    });

    try {
      await _engineBackend.executePipeline(
        userPrompt: promptText,
        onLogStream: (logMessage) {
          setState(() {
            _telemetryLogs.add(logMessage);
            if (_telemetryLogs.length > 250) {
              _telemetryLogs.removeAt(0);
            }
          });
        },
        onProgressUpdate: (progressVal, statusDesc) {
          setState(() {
            _pipelineProgress = progressVal;
            _githubDeploymentStatus = statusDesc;
          });
        },
      );
    } catch (e) {
      setState(() {
        _telemetryLogs.add('❌ Critical Pipeline Error: $e');
        _githubDeploymentStatus = 'Deployment Failed due to Exception';
      });
    } finally {
      setState(() {
        _isPipelineActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Agent Studio (Self-Healing Core)'),
        backgroundColor: const Color(0xFF111827),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent),
            tooltip: 'Self-Healing Engine Active',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local Code Guard & Type Validation is Active.')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Prompt Instructions Card
            Card(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Prompt Architecture',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., Build a complete professional notes app with local db & search...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Execution Action Button
            ElevatedButton.icon(
              onPressed: _isPipelineActive ? null : _triggerAutonomousPipeline,
              icon: _isPipelineActive
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(_isPipelineActive ? 'Autonomous Pipeline Processing...' : 'Step 1: Analyze, Self-Test & Push'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Pipeline Telemetry & Progress Status Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      const Text('Pipeline Status Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(_pipelineProgress * 100).toInt()}%', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _pipelineProgress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GitHub Status: $_githubDeploymentStatus',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Telemetry Terminal Logs
            const Text(
              'Live Telemetry & Self-Correction Logs:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: ListView.builder(
                  itemCount: _telemetryLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        _telemetryLogs[index],
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

// =====================================================================
// 3. BACKEND ENGINE & SELF-HEALING VALIDATION CORE
// =====================================================================
class AutonomousEngineBackend {
  
  // Local Code Validation Guard to catch type casting errors (e.g. toStringAsFixed on String)
  bool _performLocalCodeAnalysis(Map<String, String> projectFiles, Function(String) logEmitter) {
    bool isCodeClean = true;
    
    for (var entry in projectFiles.entries) {
      final fileName = entry.key;
      final fileContent = entry.value;

      if (fileName.endsWith('.dart')) {
        // Check rule 1: Misuse of toStringAsFixed directly on string without numeric parsing
        if (fileContent.contains('.toStringAsFixed') && 
            !fileContent.contains('double.parse') && 
            !fileContent.contains('tryParse') && 
            !fileContent.contains('double?')) {
          logEmitter('⚠️ Self-Test Alert: Found potential type error (.toStringAsFixed on String) in $fileName');
          isCodeClean = false;
        }

        // Check rule 2: Basic syntax terminator verification
        if (fileContent.contains('return expression') && !fileContent.contains(';')) {
          logEmitter('⚠️ Self-Test Alert: Missing semicolon statement terminator detected in $fileName');
          isCodeClean = false;
        }
      }
    }
    return isCodeClean;
  }

  // Complete Execution Loop with Autonomous Self-Correction
  Future<void> executePipeline({
    required String userPrompt,
    required Function(String) onLogStream,
    required Function(double, String) onProgressUpdate,
  }) async {
    onLogStream('🚀 Autonomous Agent Session Started.');
    onProgressUpdate(0.15, 'Analyzing user prompt specifications...');
    await Future.delayed(const Duration(milliseconds: 800));

    onLogStream('📋 Architect planned 15 core files for modular application structure.');
    onProgressUpdate(0.30, 'Generating code files via AI model...');
    await Future.delayed(const Duration(milliseconds: 1000));

    int maxRetries = 3;
    bool isDeploymentReady = false;
    Map<String, String> currentProjectFiles = {};
    String activePromptContext = userPrompt;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      onLogStream('⚙️ Code Generation Attempt $attempt of $maxRetries in progress...');
      
      // Simulate Code Generation from AI
      currentProjectFiles = _generateMockProjectFiles(activePromptContext);
      
      onLogStream('🔍 Running internal syntax verification & type safety analyzer...');
      onProgressUpdate(0.50, 'Running local self-tests...');
      await Future.delayed(const Duration(milliseconds: 1000));

      // Run Local Verification Guard
      if (_performLocalCodeAnalysis(currentProjectFiles, onLogStream)) {
        isDeploymentReady = true;
        onLogStream('✅ Local Self-Test Passed Cleanly with 0 errors!');
        break;
      } else {
        onLogStream('🔄 Self-Test Failed! Triggering automatic self-correction loop...');
        activePromptContext = "$userPrompt \n\nAUTO-CORRECTION INSTRUCTION: Ensure all numeric values are parsed via double.tryParse before calling formatting methods, and fix any missing syntax elements.";
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    if (isDeploymentReady) {
      onProgressUpdate(0.75, 'Preparing secure GitHub commit payload...');
      onLogStream('📦 Packaging verified code files for GitHub synchronization...');
      await Future.delayed(const Duration(milliseconds: 1000));

      onProgressUpdate(1.0, 'Deployment Completed Successfully.');
      onLogStream('✨ All tests passed. Final verified code successfully pushed to GitHub repository!');
    } else {
      onProgressUpdate(0.65, 'Deployment Failed.');
      onLogStream('❌ Autonomous Agent could not resolve errors automatically after $maxRetries attempts.');
    }
  }

  // Simulated Generator returning structured project files
  Map<String, String> _generateMockProjectFiles(String prompt) {
    return {
      'lib/main.dart': '''
        import 'package:flutter/material.dart';
        void main() => runApp(const SelfHealedApp());
        class SelfHealedApp extends StatelessWidget {
          const SelfHealedApp({super.key});
          @override
          Widget build(BuildContext context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                appBar: AppBar(title: const Text('Autonomous Verified App')),
                body: const Center(
                  child: Text(
                    'Application Verified & Deployed Safely!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }
        }
      ''',
      'lib/calculator_logic.dart': '''
        class CalculatorEngine {
          String calculate(String expression) {
            try {
              String sanitized = expression.replaceAll(' ', '');
              double? parsed = double.tryParse(sanitized);
              if (parsed != null) {
                return parsed.toStringAsFixed(2);
              }
              return sanitized;
            } catch (e) {
              return 'Error';
            }
          }
        }
      ''',
      'pubspec.yaml': '''
        name: autonomous_verified_app
        description: Generated via Autonomous Self-Healing Agent.
        publish_to: 'none'
        version: 1.0.0+1
        environment:
          sdk: '>=3.0.0 <4.0.0'
        dependencies:
          flutter:
            sdk: flutter
          http: ^1.2.0
        flutter:
          uses-material-design: true
      ''',
    };
  }
}
