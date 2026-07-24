import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Desi AI App')),
        body: const Center(
          child: Text('AI एजेंट द्वारा बनाई गई पहली स्क्रीन! 🚀'),
        ),
      ),
    );
  }
}
