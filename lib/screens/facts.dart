import 'package:flutter/material.dart';

class FactsPage extends StatelessWidget {
  final bool isLoggedIn;
  const FactsPage({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facts')),
      body: const Center(
        child: Text(
          'Read verified renal health facts and information.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
